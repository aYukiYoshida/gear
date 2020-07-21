#! /usr/bin/env python
# -*- coding: utf-8 -*-

__author__ =  'Yuki Yoshida (yy(at)rikkyo.ac.jp)'
__version__=  '1.0'


import sys
import os
import inspect
from absl import app, flags
from typing import Union, Dict, List, Tuple
import numpy as np
from astropy.io import fits as iofits
from astropy.coordinates import Angle
from regions import read_ds9 as read_ds9_region
from regions import ds9_objects_to_string
from regions import CircleAnnulusPixelRegion, RectanglePixelRegion, PixCoord


RADII = {
    '3arcmin': 172.584,  # pixel
    '5arcmin': 287.64,   # pixel
    '7arcmin': 402.69663 # pixel
    }

SRC_REGION_META = {
    'include': True
    }

BKG_REGION_META = {
    'include': True,
    'comment': '# background'
    }


def logger(string: str, level: int, frame=None) -> None:
    status = {
        0: 'DEBUG',
        1: 'INFO',
        2: 'WARNING',
        3: 'ERROR'}
    if not frame == None:
        function_name = inspect.getframeinfo(frame)[2]
        console_msg = '[%s] %s : %s' % (
            status[level], function_name, str(string))
    else:
        console_msg = '[%s] %s' % (status[level], str(string))
    if (level >= flag_values.loglv):
        print(console_msg)


def make_output_directory():
    out_dir = flag_values.out_directory
    os.makedirs(out_dir, exist_ok=True)
    logger(f'{out_dir} is generated', 0)


def open_image_fits(file_name:str,index) -> Union[
        iofits.hdu.image.PrimaryHDU,iofits.hdu.table.BinTableHDU]:
    hdulist = iofits.open(file_name)
    return hdulist[index]


def get_necessary_parameters(hdu: iofits.hdu.image.PrimaryHDU) -> Dict[str,Union[int,float]]:
    parameters = dict(
        win_opt = hdu.header['WINOPT'],  # (0:Off, 1:1/4, 2:1/8, 3:1/16)
        win_size = hdu.header['WIN_SIZ'],
        win_start = hdu.header['WIN_ST'],
        pa_nom = hdu.header['PA_NOM'],
        xref_pix = hdu.header['CRPIX1'],
        yref_pix = hdu.header['CRPIX2'],
        xis_id = int(hdu.header['INSTRUME'].strip('XIS')))
    return parameters


def define_rotation_angle_deg(paramters: dict) -> float:
    rot_angle_deg = {
        0: paramters['pa_nom'],
        1: paramters['pa_nom'] - 90.,
        2: paramters['pa_nom'] + 90.,
        3: paramters['pa_nom']
    }
    return rot_angle_deg[paramters['xis_id']]


def define_rotaion_matrix(parameters: dict) -> Tuple[np.ndarray, np.ndarray]:
    rot_angle_rad = np.radians(define_rotation_angle_deg(parameters))
    normal_rotaion_matrix = np.matrix([
        [np.cos(rot_angle_rad), -np.sin(rot_angle_rad)],
        [np.sin(rot_angle_rad), np.cos(rot_angle_rad)]], dtype=float)
    inverse_rotaion_matrix = np.matrix([
        [np.cos(rot_angle_rad), np.sin(rot_angle_rad)],
        [-np.sin(rot_angle_rad), -np.cos(rot_angle_rad)]], dtype=float)
    return normal_rotaion_matrix, inverse_rotaion_matrix


def convert_reference_coodinate(ref: np.ndarray, parameters: dict) -> np.matrix:
    nrm_rot_mtx, _ = define_rotaion_matrix(parameters)
    org = np.array([parameters['xref_pix'], parameters['yref_pix']]).reshape(2,1)

    ref = ref.reshape(2,1)
    ref = nrm_rot_mtx * ref
    ref = ref + org
    return ref


def read_pileup_region() -> CircleAnnulusPixelRegion:
    regions = read_ds9_region(flag_values.pileup_region)
    return regions[0]


def define_regions(hdu: iofits.hdu.image.PrimaryHDU, parameters: dict) -> Dict[str, Union[
        CircleAnnulusPixelRegion, RectanglePixelRegion]]:
    regions = dict()
    pileup_region = read_pileup_region()
    rot_angle_deg = define_rotation_angle_deg(parameters)
    windel = parameters['win_start'] - 512

    # source region
    regions['src'] = CircleAnnulusPixelRegion(
        center=pileup_region.center,
        inner_radius=pileup_region.inner_radius,
        outer_radius=RADII['3arcmin'],
        meta=SRC_REGION_META)

    # background region
    regions['bkg'] = CircleAnnulusPixelRegion(
        center=pileup_region.center,
        inner_radius=RADII['5arcmin'],
        outer_radius=RADII['7arcmin'],
        meta=BKG_REGION_META)

    # exclude region 1
    ref = np.array([0, windel - 256.])
    ref = convert_reference_coodinate(ref, parameters)
    regions['rct1'] = RectanglePixelRegion(
        center=PixCoord(float(ref[0][0]), float(ref[1][0])),
        width=1024.,
        height=512.,
        angle=Angle(rot_angle_deg,'deg'))

    # exclude region 2
    ref = np.array([0, windel + parameters['win_size'] + 256.])
    ref = convert_reference_coodinate(ref, parameters)
    regions['rct2'] = RectanglePixelRegion(
        center=PixCoord(float(ref[0][0]), float(ref[1][0])),
        width=1024.,
        height=512.,
        angle=Angle(rot_angle_deg,'deg'))

    # exclude region 3
    ref = np.array([512. + 128., windel + parameters['win_size'] * 0.5])
    ref = convert_reference_coodinate(ref, parameters)
    regions['rct3'] = RectanglePixelRegion(
        center=PixCoord(float(ref[0][0]), float(ref[1][0])),
        width=256.,
        height=parameters['win_size']+1024.,
        angle=Angle(rot_angle_deg,'deg'))

    # exclude region 4
    ref = np.array([-512 - 128, windel + parameters['win_size'] * 0.5])
    ref = convert_reference_coodinate(ref, parameters)
    regions['rct4'] = RectanglePixelRegion(
        center=PixCoord(float(ref[0][0]), float(ref[1][0])),
        width=256.,
        height=parameters['win_size']+1024.,
        angle=Angle(rot_angle_deg,'deg'))

    return regions


def generate_region(context: str, regions: list, xis_id: int) -> None:
    region_filename = os.path.join(
        flag_values.out_directory, f'x{xis_id}_{context}.reg')
    write_ds9_region(regions,region_filename)
    logger(f'{region_filename} is generated',1)


def write_ds9_region(regions: list, region_filename: str) -> None:
    output = ds9_objects_to_string(regions,coordsys='physical')
    output = output.replace('box','-box')
    logger(f'DESCRIPTION OF OUTPUT REGION: {region_filename}\n{output}',0)
    with open(region_filename, 'w') as f:
        f.write(output)

def main(argv) -> None:
    if flag_values.debug:
        flag_values.loglv = 0

    hdu = open_image_fits(flag_values.image,0)
    par = get_necessary_parameters(hdu)
    regions = define_regions(hdu,par)
    make_output_directory()
    generate_region(
        'src',[regions['src'],regions['rct1'],regions['rct2']],
        par['xis_id'])
    generate_region(
        'bkg',[regions['bkg'],regions['rct1'],regions['rct2'],regions['rct3'],regions['rct4']],
        par['xis_id'])


if __name__ == '__main__':
    flag_values = flags.FLAGS
    flags.DEFINE_string('image', None, 'XIS image FITS file.', short_name='i')
    flags.DEFINE_string('pileup_region', 
        None, 
        'Region file generated by aepileupcheckup.py.',
        short_name='r')
    flags.DEFINE_string('out_directory', 
        'src', 
        'Output directory.',
        short_name='o')
    flags.DEFINE_boolean('debug', False, 'enable debug trace.', short_name='d')
    flags.DEFINE_integer('loglv', 1, 'logging level.', lower_bound=0, upper_bound=3)
    flags.mark_flags_as_required(['image', 'pileup_region'])
    sys.exit(app.run(main))