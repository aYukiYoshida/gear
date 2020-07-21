#! /usr/bin/python
# -*- coding: utf-8 -*-

__author__ =  'Yuki Yoshida (yy(at)rikkyo.ac.jp)'
__version__=  '2.0'


############################################################################
## import module
############################################################################
import sys
import getopt
import math
import os.path
import numpy as np
import pyfits
import scipy.optimize
from scipy.misc import imrotate
import matplotlib.pyplot as plt

#import aplpy
#from pyds9 import *
#from skypy import *


############################################################################
# Function
############################################################################

############################################
# usage
############################################
def usage():
    print 'USAGE:'
    print '   '+os.path.basename(sys.argv[0])+' <IMG>'
    print 'EXAMPLE:'
    print '   '+os.path.basename(sys.argv[0])+' --IMG=x0.img'
    print 'PARAMETERS:'
    print '   IMG  :  Image FITS FILE'


############################################
# read image FITS file
############################################
def __subpyf_openfits(filename=None, index=0, type=1, id=0):
    """
    Open FITS with pyfits

    type --- what to return
    """
    if filename == None:
        filename = str(input("FITS file name "+str(id)+" > "))
    f = pyfits.open(filename)
    data = np.array(f[index].data, float)
    imdata = [data]
    if type == 0:
        scalemin = None
        scalemax = None
        return imdata, scalemin, scalemax
    elif type == 1:
        return imdata
    elif type == 2:
        return imdata, f
    elif type == 3:
        header = f[index].header
        return imdata, f, header


def subopenfits(filename=None, index=0, type=1, id=0, mod="pyf"):
    """
    Open FITS
    """
    if mod == "pyf":
        imdata, f, header = __subpyf_openfits(
            filename=filename, index=index, type=3, id=id)
    if type == 0:
        scalemin = None
        scalemax = None
        # print imdata,scalemin,scalemax
        return imdata, scalemin, scalemax
    elif type == 1:
        # print imdata
        return imdata
    elif type == 2:
        # print imdata,f
        return imdata, f
    elif type == 3:
        # print imdata,f,header
        return imdata, f, header


############################################
# read region file of ds9 format
############################################
def opendatreg(filename=None):
    """
    Open dat type region file.

    filename --- Region file name (.dat or .reg)
    """
    if filename == None:
        filename = input("region file (.dat) > ")
    f = open(filename)
    regfile = f.readlines()
    f.close()
    outreg = []
    unit = None
    for ii in range(1, len(regfile), 1):  # range(start,stop,step)
        if regfile[ii][:3] == "box":  # 'box[a,b,c,...]'
            n = 4
        elif regfile[ii][:6] == "rotbox":
            n = 7
        elif regfile[ii][:6] == "circle":
            n = 7
            unit = 1.
            regfile[ii].replace('"', '')
            if regfile[ii][-3] == "'" or regfile[ii][-2] == "'":
                unit = 60.
                regfile[ii] = regfile[ii].replace("'", '')
        else:
            n = None

        if '#' in regfile[ii]:
            index = regfile[ii].rindex('#')
            regfile[ii] = regfile[ii][:index]

        if n != None:
            subreg = regfile[ii][n:-2].split(',')
            reg = [float(k) for k in subreg]
            if unit != None:
                reg[-1] *= unit
            outreg.append(reg)
    # print "Set %d region." %len(outreg)
    # print outreg
    return outreg


############################################
# rotation image
############################################
def rotimg(idnum, data, angle=0.0, outfit=False, imp_interp='bilinear'):
    # The imp_interp string determines
    # how the interpolation will be done, with self-explanatory options
    # 'nearest', 'bilinear', 'cubic','bicubic'
    # print idnum ##DEBUG
    # print angle ##DEBUG
    rot_data = imrotate(data, angle, interp=imp_interp)
    hdu = pyfits.PrimaryHDU(rot_data)
    rot_img = pyfits.HDUList([hdu])
    out_rot_img = str('mkpeakreg/img/xi%s_rot.img') % idnum
    if os.path.exists(out_rot_img) == False:
        if outfit == True:
            rot_img.writeto(out_rot_img)
            print '%s generated %s' % (os.path.basename(sys.argv[0]), str(out_rot_img))
        else:
            print '%s did not generate %s' % (os.path.basename(sys.argv[0]), str(out_rot_img))
    else:
        print '%s could not generate %s, already exists.' % (os.path.basename(sys.argv[0]), str(out_rot_img))
        # sys.exit(2)
    return rot_data


############################################
# extract image in region
############################################
def outrotinregimg(idnum, data):
    hdu = pyfits.PrimaryHDU(data)
    img = pyfits.HDUList([hdu])
    out_img = str('mkpeakreg/img/xi%s_rot_inreg.img') % idnum
    if os.path.exists(out_img) == False:
        img.writeto(out_img, clobber=True)
        print '%s generated %s' % (os.path.basename(sys.argv[0]), str(out_img))
    else:
        print '%s could not generate %s, already exists.' % (os.path.basename(sys.argv[0]), str(out_img))
        # sys.exit(2)


############################################
# gaussian function
############################################
def gaussian(x, A, mean, sigma):
    gauss = A/math.sqrt(2.0*math.pi)/sigma * np.exp(-((x-mean)/sigma)**2/2)
    return(gauss)


############################################
# chi_square
############################################
def chi_square(param_fit, y, x, yerr):
    A, mean, sigma, base = param_fit
    err = (y - (gaussian(x, A, mean, sigma)+base)) / yerr
    return(err)


############################################
# fitting
############################################
def fiton(data, amp, mean, sigma, base=0.0):
    x = data[:, 0]
    y_d = data[:, 1]
    y_d_err = data[:, 2]

    param_tmp = [amp, mean, sigma, base]  # initial guess
    param_output = scipy.optimize.leastsq(chi_square, param_tmp,
                                          args=(y_d, x, y_d_err),
                                          full_output=True)
    param_result = param_output[0]  # fitted parameters
    covar_result = param_output[1]  # covariant matrix

    print("Amplitude: %10.5f +/- %10.5f"
          % (param_result[0], np.sqrt(covar_result[0][0])))
    print("Center   : %10.5f +/- %10.5f"
          % (param_result[1], np.sqrt(covar_result[1][1])))
    print("Sigma    : %10.5f +/- %10.5f"
          % (param_result[2], np.sqrt(covar_result[2][2])))
    print("Baseline : %10.5f +/- %10.5f"
          % (param_result[3], np.sqrt(covar_result[3][3])))

    ############################################
    # fitting result plot
    ############################################
    def fit_result_plot(x, param):
        result = gaussian(x, param[0], param[1], param[2]) + param[3]
        return result
    ##
    # plot result and data
    ##
    plt.plot(x, fit_result_plot(x, param_result), x, y_d)
    plt.title('Least-squares fit to noisy data')
    plt.legend(['Fit', 'Data'])
    plt.xlabel('pixel')
    plt.ylabel('counts')
    plt.savefig('fit_gaussian.png', dpi=150)
    plt.show()


############################################################################
# OPTION
############################################################################
def setparam():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "huv", [
                                   "help", "IMG=", "img="])
    except getopt.GetoptError, err:
        # ヘルプメッセージを出力して終了
        print str(err)  # will print something like "option -a not recognized"
        usage()
        sys.exit(2)

    #global img
    #global imgfilextest
    img = None
    imgfilextest = False
    # print img ##DEBUG
    verbose = False
    # print opts ##DEBUG
    # print args ##DEBUG

    for o, a in opts:
        if o == "-v":
            verbose = True
        elif o in ("-u", "-h", "--help"):
            usage()
            sys.exit()
        elif o in ("--img", "--IMG"):
            img = a
            imgfilextest = os.path.isfile(img)
            # print imgfile ##DEBUG
        else:
            assert False, "unhandled option"
    # ...
    return img, imgfilextest


def main(argv) -> None:
    pass

############################################################################
# MAIN
############################################################################
if __name__ == "__main__":

    ############################################
    # Set parameter
    ############################################
    img, imgfilextest = setparam()
    # if img is None or os.path.isfile(img) is False:
    if img is None or imgfilextest is False:
        usage()
        sys.exit(1)
    else:
        print "Input IMAGE FITS FILE    : "+os.path.basename(img)

    ############################################
    # Make directory
    ############################################
    dirlst = ['mkpeakreg', 'mkpeakreg/reg',
              'mkpeakreg/qdpfile', 'mkpeakreg/img']
    for dir in dirlst:
        if os.path.isdir(dir) == False:
            os.mkdir(dir)
            print 'Make following directory : '+dir

    ############################################
    # set fits file
    ############################################
    data_img, fop, hdr_img = subopenfits(img, 0, 3)
    # hdulist_img=pyfits.open(img)
    # hdr_img=hdulist_img[0].header
    # data_img=hdulist_img[0].data
    # hdulist_img.close()  ## image FITS file closed

    ############################################
    # set fits paramter
    ############################################
    winopt = hdr_img['WINOPT']  # (0:Off, 1:1/4, 2:1/8, 3:1/16)
    winsize = hdr_img['WIN_SIZ']
    winstart = hdr_img['WIN_ST']
    pa_nom = hdr_img['PA_NOM']
    org_refx = hdr_img['CRPIX1']
    org_refy = hdr_img['CRPIX2']
    inst = hdr_img['INSTRUME']

    ############################################
    # setup projection region file
    ############################################
    idflg = {'XIS0': '0', 'XIS1': '1', 'XIS2': '2', 'XIS3': '3'}
    id = int(idflg[str(inst)])

    reg = str('mkpeakreg/reg/xi%s_pject.reg') % id
    reg_out = open(reg, "w")
    # print 'Make following projection region : '+os.path.basename(reg)

    ############################################
    # set reference coodinate
    ############################################
    windel = winstart - 512
    ref_x = 0
    ref_y = windel + winsize/2
    ref = [[ref_x], [ref_y]]
    org = [[org_refx], [org_refy]]
    #angle = pa_nom
    # out_deg=deg

    ############################################
    # calculate rotation angle
    ############################################
    if inst == 'XIS0' or inst == 'XIS3':
        deg_angle = pa_nom
    elif inst == 'XIS1':
        deg_angle = pa_nom - 90
    elif inst == 'XIS2':
        deg_angle = pa_nom + 90
    else:
        print "otherwise"
        sys.exit(1)

    rad_angle = math.radians(deg_angle)

    ############################################
    # rotation transformed coodinate set
    ############################################
    #rot_ref_x = ref_x * math.cos(rad_angle) - ref_y * math.sin(rad_angle)
    #rot_ref_y = ref_x * math.sin(rad_angle) + ref_y * math.cos(rad_angle)
    rot = np.matrix([[math.cos(rad_angle), -math.sin(rad_angle)],
                     [math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    invrot = np.matrix([[math.cos(rad_angle), math.sin(
        rad_angle)], [-math.sin(rad_angle), -math.cos(rad_angle)]], dtype=float)
    rot_ref = rot*ref
    # print rot_ref # DEBUG

    ############################################
    # translated coodinate
    ############################################
    tra_rot_ref = rot_ref + org
    # print tra_rot_ref # DEBUG

    ############################################
    # make projection regions
    ############################################
    reg_x = tra_rot_ref[0]
    reg_y = tra_rot_ref[1]
    x_width = 1024
    y_width = winsize

    print >> reg_out, "physical"
    print >> reg_out, "box(%f,%f,%d,%d,%f)" % (
        reg_x, reg_y, x_width, y_width, deg_angle)
    print '%s generated %s' % (os.path.basename(sys.argv[0]), str(reg))
    reg_out.close()

    ############################################
    # calculate four corner
    ############################################

    lower_cn = [-512+org[0][0], windel+org[1][0]]  # lower_x,lower_y
    upper_cn = [512+org[0][0], windel+winsize+org[1][0]]  # upper_x,upper_y
    # print lower_cn ##DEBUG
    # print upper_cn ##DEBUG

    ############################################
    # extract data in region from rotating image
    ############################################
    # return data_rot_img
    data_rot_img = rotimg(id, data_img[0], deg_angle, True)
    lower_x = int(math.floor(lower_cn[0]))  # 切り捨て
    lower_y = int(math.floor(lower_cn[1]))  # 切り捨て
    upper_x = int(math.ceil(upper_cn[0]))  # 切り上げ
    upper_y = int(math.ceil(upper_cn[1]))  # 切り上げ
    # print lower_x,upper_x,lower_y,upper_y

    reg_data_rot_img = np.array(data_rot_img[lower_y:upper_y, lower_x:upper_x])
    # reg_data_rot_img=data_rot_img[435:692,256:1281]
    outrotinregimg(id, reg_data_rot_img)

    ############################################
    # calculate projection & make qdp
    ############################################
    # 横軸方向projection,y軸でplot
    row_sum_reg_data_rot_img = np.sum(reg_data_rot_img, axis=1)
    # print col_sum_reg_data_rot_img
    # print len(col_sum_reg_data_rot_img)
    out_row_sum = str('mkpeakreg/qdpfile/xi%s_row_sum.qdp') % id
    row_sum = open(out_row_sum, "w")  # output to qdpfile

    print >> row_sum, "READ SERR 2"  # output to qdpfile
    row_sum_lst = []
    for ii in range(len(row_sum_reg_data_rot_img)):
        print >> row_sum, '%d %f %f' % (ii+lower_y, row_sum_reg_data_rot_img[ii], np.sqrt(
            row_sum_reg_data_rot_img[ii]))  # output to qdpfile
        row_sum_lst.append(
            [ii+lower_y, row_sum_reg_data_rot_img[ii], np.sqrt(row_sum_reg_data_rot_img[ii])])
    row_sum_array = np.asarray(row_sum_lst)
    print str(out_row_sum)+" was generated"  # show message

    # 縦軸方向projection,x軸でplot
    col_sum_reg_data_rot_img = np.sum(reg_data_rot_img, axis=0)
    # print row_sum_reg_data_rot_img
    # print len(row_sum_reg_data_rot_img)
    out_col_sum = str('mkpeakreg/qdpfile/xi%s_col_sum.qdp') % id
    col_sum = open(out_col_sum, "w")  # output to qdpfile

    print >> col_sum, "READ SERR 2"  # output to qdpfile
    col_sum_lst = []
    for ii in range(len(col_sum_reg_data_rot_img)):
        print >> col_sum, '%d %f %f' % (ii+lower_x, col_sum_reg_data_rot_img[ii], np.sqrt(
            col_sum_reg_data_rot_img[ii]))  # output to qdpfile
        col_sum_lst.append(
            [ii+lower_x, col_sum_reg_data_rot_img[ii], np.sqrt(col_sum_reg_data_rot_img[ii])])
    col_sum_array = np.asarray(col_sum_lst)
    print str(out_col_sum)+" was generated"  # show message

    ############################################
    # fitting projection (non execute!!!!!)
    ############################################
    s_for_row = (lower_y+upper_y)/2
    # fiton(row_sum_array,100.0,s_for_row,30.0)
    s_for_col = (lower_x+upper_x)/2
    # fiton(col_sum_array,100.0,s_for_row,30.0)

    ############################################
    # scan max & rotate max coordinate
    ############################################
    col_sum_max = col_sum_array.argmax(0)[1]+lower_x  # X-axis
    row_sum_max = row_sum_array.argmax(0)[1]+lower_y  # Y-axis
    maxcoord = [[col_sum_max], [row_sum_max]]
    # print maxcoord #DEBUG
    tra_maxcoord = [[maxcoord[0][0] - org[0][0]], [maxcoord[1][0] - org[1][0]]]
    rot_tra_maxcoord = rot*tra_maxcoord
    inv_rot_tra_maxcoord = [rot_tra_maxcoord.T[0, 0] +
                            org[0][0], rot_tra_maxcoord.T[0, 1]+org[1][0]]
    # print inv_rot_tra_maxcoord

    ############################################
    # setup src & bkg region file
    ############################################
    srcreg = str('mkpeakreg/reg/xi%s_src.reg') % id
    srcreg_out = open(srcreg, "w")
    # print 'Make following projection region : '+os.path.basename(srcreg)

    bkgreg = str('mkpeakreg/reg/xi%s_bkg.reg') % id
    bkgreg_out = open(bkgreg, "w")
    # print 'Make following projection region : '+os.path.basename(bkgreg)

    ############################################
    # make src & bkg regions
    ############################################
    cet_x = inv_rot_tra_maxcoord[0]
    cet_y = inv_rot_tra_maxcoord[1]
    r3 = 172.584
    r5 = 287.64
    r7 = 402.69663

    # source region
    print >> srcreg_out, "physical"
    print >> srcreg_out, "circle(%f,%f,%f)" % (cet_x, cet_y, r3)

    # background region
    print >> bkgreg_out, "physical"
    print >> bkgreg_out, "annulus(%f,%f,%f,%f)" % (cet_x, cet_y, r5, r7)

    # exclude region 1
    windel = winstart - 512
    ref_x = 0
    ref_y = windel - 256
    ref = [[ref_x], [ref_y]]
    rot = np.matrix([[math.cos(rad_angle), -math.sin(rad_angle)],
                     [math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    invrot = np.matrix([[math.cos(rad_angle), math.sin(
        rad_angle)], [-math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    rot_ref = rot*ref
    tra_rot_ref = rot_ref + org
    reg_x = tra_rot_ref[0]
    reg_y = tra_rot_ref[1]
    x_width = 1024
    y_width = 512

    print >> srcreg_out, "-box(%f,%f,%d,%d,%f)" % (reg_x,
                                                   reg_y, x_width, y_width, deg_angle)
    print >> bkgreg_out, "-box(%f,%f,%d,%d,%f)" % (reg_x,
                                                   reg_y, x_width, y_width, deg_angle)

    # exclude region 2
    windel = winstart - 512
    ref_x = 0
    ref_y = windel + winsize + 256
    ref = [[ref_x], [ref_y]]
    rot = np.matrix([[math.cos(rad_angle), -math.sin(rad_angle)],
                     [math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    invrot = np.matrix([[math.cos(rad_angle), math.sin(
        rad_angle)], [-math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    rot_ref = rot*ref
    tra_rot_ref = rot_ref + org
    reg_x = tra_rot_ref[0]
    reg_y = tra_rot_ref[1]
    x_width = 1024
    y_width = 512

    print >> srcreg_out, "-box(%f,%f,%d,%d,%f)" % (reg_x,
                                                   reg_y, x_width, y_width, deg_angle)
    print >> bkgreg_out, "-box(%f,%f,%d,%d,%f)" % (reg_x,
                                                   reg_y, x_width, y_width, deg_angle)

    # exclude region 3
    windel = winstart - 512
    ref_x = 512+128
    ref_y = windel + winsize/2
    ref = [[ref_x], [ref_y]]
    rot = np.matrix([[math.cos(rad_angle), -math.sin(rad_angle)],
                     [math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    invrot = np.matrix([[math.cos(rad_angle), math.sin(
        rad_angle)], [-math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    rot_ref = rot*ref
    tra_rot_ref = rot_ref + org
    reg_x = tra_rot_ref[0]
    reg_y = tra_rot_ref[1]
    x_width = 256
    y_width = winsize+1024

    print >> bkgreg_out, "-box(%f,%f,%d,%d,%f)" % (reg_x,
                                                   reg_y, x_width, y_width, deg_angle)

    # exclude region 4
    windel = winstart - 512
    ref_x = -512-128
    ref_y = windel + winsize/2
    ref = [[ref_x], [ref_y]]
    rot = np.matrix([[math.cos(rad_angle), -math.sin(rad_angle)],
                     [math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    invrot = np.matrix([[math.cos(rad_angle), math.sin(
        rad_angle)], [-math.sin(rad_angle), math.cos(rad_angle)]], dtype=float)
    rot_ref = rot*ref
    tra_rot_ref = rot_ref + org
    reg_x = tra_rot_ref[0]
    reg_y = tra_rot_ref[1]
    x_width = 256
    y_width = winsize+1024

    print >> bkgreg_out, "-box(%f,%f,%d,%d,%f)" % (reg_x,
                                                   reg_y, x_width, y_width, deg_angle)

    print '%s generated %s' % (os.path.basename(sys.argv[0]), str(srcreg))
    srcreg_out.close()

    print '%s generated %s' % (os.path.basename(sys.argv[0]), str(bkgreg))
    srcreg_out.close()
