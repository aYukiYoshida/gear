#!/usr/bin/env python3

import sys
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
import os
import inspect
from absl import app
from absl import flags
from typing import Union, List, Dict, Tuple
from decimal import Decimal, ROUND_HALF_UP


###-----------------------------------------------------------------------
class Log(object):
###-----------------------------------------------------------------------
    STATUS = {
        0 : 'DEBUG',
        1 : 'INFO',
        2 : 'WARNING',
        3 : 'ERROR' }


    ###-------------------------------------------------------------------
    def __init__(self,loglv: Union[int, str] = 1) -> None:
    ###-------------------------------------------------------------------
        if type(loglv) is str:
            try:
                loglv = list(self.STATUS.values()).index(loglv.upper())
            except ValueError:
                raise ValueError(f'loglv should be set to an integer between 0 and 3 or a one of '+', '.join(self.STATUS.values())+'.')
        self.loglv: int = loglv


    ###-------------------------------------------------------------------
    def logger(self,string: str,level: int, frame=None) -> None:
    ###-------------------------------------------------------------------
        if not frame == None:
            function_name = inspect.getframeinfo(frame)[2]
            console_msg = f'[{self.STATUS[level]}] {function_name} : {str(string)}'
        else:
            console_msg = f'[{self.STATUS[level]}] {str(string)}'
        if (level >= self.loglv):
            print(console_msg)


    ###-------------------------------------------------------------------
    def debug(self,string: str, frame=None) -> None:
    ###-------------------------------------------------------------------
        self.logger(string,0,frame)


    ###-------------------------------------------------------------------
    def info(self,string: str, frame=None) -> None:
    ###-------------------------------------------------------------------
        self.logger(string,1,frame)


    ###-------------------------------------------------------------------
    def warning(self,string: str, frame=None) -> None:
    ###-------------------------------------------------------------------
        self.logger(string,2,frame)


    ###-------------------------------------------------------------------
    def error(self,string: str, frame=None) -> None:
    ###-------------------------------------------------------------------
        self.logger(string,3,frame)


    ###-------------------------------------------------------------------
    def abort(self,string: str,frame=None) -> None:
    ###-------------------------------------------------------------------
        self.error(string,frame)
        sys.exit(1)



###-----------------------------------------------------------------------
class BinningLightCurve(Log):
###-----------------------------------------------------------------------
    # CLASS VARIABLES
    DPI = 150
    LOWER_THRESHOLD = 1.E-05
    COLUMN_NAMES = ['time','time_delta',
                    'count0','error0',
                    'count1','error1',
                    'count2','error2',
                    'ratio0','ratio_error0',
                    'ratio1','ratio_error1',
                    'count3','error3',
                    'flag' ]

    ###-------------------------------------------------------------------
    def __init__(self, qdpfile:str, binsize_sec:float, img_out:bool=False, loglv:Union[int, str]=1):
    ###-------------------------------------------------------------------
        super().__init__(loglv)

        self.qdpfile = qdpfile
        self.outqdpfile = qdpfile.replace('.qdp',f'_rebin_{str(int(binsize_sec))}s.qdp')
        self.binsize_sec = binsize_sec
        self.img_out = img_out        


    @classmethod
    ###-------------------------------------------------------------------
    def round_half_up(cls,x:float):
    ###-------------------------------------------------------------------
        return np.vectorize(lambda x: Decimal(x).quantize(Decimal('0'), rounding=ROUND_HALF_UP))(x)


    ###-------------------------------------------------------------------
    def read_qdp(self) -> None:
    ###-------------------------------------------------------------------
        try:            
            self.qdp = pd.read_table(
                self.qdpfile, 
                sep='\s+',
                skiprows=3,
                names=self.COLUMN_NAMES)
        except FileNotFoundError:
            self.abort('Input file does not exist')


    ###-------------------------------------------------------------------
    def reduce_data(self) -> None:
    ###-------------------------------------------------------------------
        for column in self.COLUMN_NAMES[2:]:
            self.qdp[column].mask(self.qdp[column]=='NO', inplace=True)
            self.qdp[column] = self.qdp[column].astype(float)
        
        # self.qdp['count1'].mask(self.qdp['count1']<=self.LOWER_THRESHOLD, inplace=True)
        # self.qdp['error1'].mask(self.qdp['count1']<=self.LOWER_THRESHOLD, inplace=True)
        # self.qdp['count2'].mask(self.qdp['count2']<=self.LOWER_THRESHOLD, inplace=True)
        # self.qdp['error2'].mask(self.qdp['count2']<=self.LOWER_THRESHOLD, inplace=True)
        # self.qdp['count3'].mask(self.qdp['count3']<=self.LOWER_THRESHOLD, inplace=True)
        # self.qdp['error3'].mask(self.qdp['count3']<=self.LOWER_THRESHOLD, inplace=True)
        
        for i in range(3):
            self.qdp[f'weight{i}'] = self.qdp[f'error{i}']**(-2.0)
            self.qdp[f'weight{i}'].mask(self.qdp[f'weight{i}']==np.inf, inplace=True)
            self.qdp[f'weighted_count{i}'] = self.qdp[f'count{i}'] * self.qdp[f'weight{i}']

        self.qdp['time_lower_limit'] = self.qdp['time'] - self.qdp['time_delta']
        self.qdp['time_upper_limit'] = self.qdp['time'] + self.qdp['time_delta']
        self.qdp['group'] = ((self.qdp['time'] - self.qdp['time'].min())/self.binsize_sec).astype(int)


    ###-------------------------------------------------------------------
    def group(self) -> None:
    ###-------------------------------------------------------------------
        self.info(f'binsize = {self.binsize_sec}')
        sum = self.qdp.groupby('group')[[ f'weight{i}' for i in range(3) ] + [ f'weighted_count{i}' for i in range(3) ]].sum()

        grouped = pd.DataFrame()
        grouped['time'] = self.qdp.groupby('group')['time'].mean()
        grouped['time_delta'] = (self.qdp.groupby('group')['time_upper_limit'].max() - self.qdp.groupby('group')['time_lower_limit'].min())*0.5

        for i in range(3):
            grouped[f'count{i}'] = sum[f'weighted_count{i}'] / sum[f'weight{i}']
            grouped[f'error{i}'] = np.sqrt(1/sum[f'weight{i}'])
            grouped[f'error{i}'].mask(grouped[f'error{i}']==np.inf, inplace=True)

        grouped['count3'] = np.zeros(grouped.index.size)
        grouped['error3'] = np.zeros(grouped.index.size)

        grouped['ratio0'] = grouped['count1'] / grouped['count0']
        grouped['ratio_error0'] = grouped['ratio0']*np.sqrt((grouped['error0']/grouped['count0'])**2+ (grouped['error1']/grouped['count1'])**2)

        grouped['ratio1'] = np.zeros(grouped.index.size)
        grouped['ratio_error1'] = np.zeros(grouped.index.size)
        grouped['flag'] = np.ones(grouped.index.size).astype(int)
        
        grouped.fillna('NO', inplace=True)
        self.grouped = grouped

    
    ###-------------------------------------------------------------------
    def group_light_curve(self):
    ###-------------------------------------------------------------------
        self.read_qdp()
        self.reduce_data()
        self.group()

        with open(self.outqdpfile, 'w') as f:
            f.write('READ SERR 1 2 3 4 5 6 7\n')
            f.write('!\n')
            self.grouped[self.COLUMN_NAMES].to_csv(
                f, sep=' ',
                index=False,
                header=False)
        self.info(f'{self.outqdpfile} is generated')

        
    ##--------------------------------------------------------------------------
    def plot_binned_light_curve(self) -> None:
    ##--------------------------------------------------------------------------        
        labels = [ 'XIS', 'PIN', 'PIN/XIS' ]
        fontsize = 12.0

        fig,axes = plt.subplots(
            3,1,
            figsize=(8, 6),
            sharex='col')
        fig.subplots_adjust(
            left=0.12, right=0.95,
            bottom=0.095, top=0.95,
            wspace=0.15, hspace=0.1)
        
        for ax, i, label in zip(axes, range(3), labels):
            if i < 2:
                ax.errorbar(
                    self.grouped['time'],
                    self.grouped[f'count{i}'], 
                    xerr=self.grouped['time_delta'],
                    yerr=self.grouped[f'error{i}'],
                    fmt='ro', label=label, ecolor='r', color='r',
                    marker='.', ms=5, capsize=0, elinewidth=1.3)

                ax.set_ylabel('counts/s',fontsize=fontsize)
                ax.tick_params(labelbottom=False)
            else:
                ax.errorbar(
                    self.grouped['time'],
                    self.grouped[f'ratio0'], 
                    xerr=self.grouped['time_delta'],
                    yerr=self.grouped[f'ratio_error0'],
                    fmt='ro', label=label, ecolor='r', color='r',
                    marker='.', ms=5, capsize=0, elinewidth=1.3)

                ax.set_xlabel('time(s)', fontsize=fontsize)
                ax.set_ylabel('hardness', fontsize=fontsize)
                # ax.set_yscale('log')

            ax.grid(True)
            ax.legend(fontsize=8.0,loc=2,scatterpoints=1,numpoints=1,
                      fancybox=True, framealpha=1.0)
            ax.tick_params(axis='both', which='both', direction='in')
            ax.yaxis.set_label_coords(-0.08, 0.5)
            

        if self.img_out:
            image_file_format = 'png'
            image_file_name = self.qdpfile.replace('.qdp', f'.{image_file_format}')
            plt.savefig(image_file_name, format=image_file_format, dpi=self.DPI , transparent=True)
            plt.close(fig)
            self.info(f'{image_file_name} is generated')
        else:
            plt.pause(1.0)
            plt.show()


###-----------------------------------------------------------------------
def main(argv):
###-----------------------------------------------------------------------
    logger = Log(flag_values.loglv)

    if flag_values.qdp:
        grouper = BinningLightCurve(flag_values.qdp, flag_values.binsize, flag_values.image, flag_values.loglv)
        grouper.group_light_curve()
        if flag_values.plot:
            grouper.plot_binned_light_curve()
    else:
        logger.error('Please qdp file name !!')
        logger.abort('Try --help to get a list of flags !!')


###-----------------------------------------------------------------------
if __name__ == '__main__':
###-----------------------------------------------------------------------
    flag_values = flags.FLAGS
    flags.DEFINE_boolean('plot', False, 'plot binned light curve.')
    flags.DEFINE_boolean('image', False, 'flag to output image file.')
    flags.DEFINE_enum('loglv', 'INFO', ['DEBUG', 'debug', 'INFO', 'info', 'WARNING', 'warning', 'ERROR', 'error'], 'Logging level.')
    flags.DEFINE_string('qdp', None, 'qdp file of light curve')
    flags.DEFINE_float('binsize', 64., 'binning size in unit of second', 0.)
    sys.exit(app.run(main))

    # argvs = sys.argv  #
    # argc = len(argvs)  #
    # cmd,qdp,binsize,imgout=setparam(argvs)


    # func = binning(qdp,binsize,imgout)
    # func.read_qdp()
    # func.calc_sum()
    # func.calc_ave()
    # func.pltbinnedlc()
    
    # sys.exit()


