#!/usr/bin/env python

import sys, getopt
import glob
import math
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
import mpl_toolkits.axisartist as AA
from mpl_toolkits.axes_grid1 import host_subplot
from scipy.interpolate import interp1d
from scipy.interpolate import splev, splrep
from scipy.interpolate import InterpolatedUnivariateSpline
from scipy import integrate
import os
import scipy.optimize
import os.path
import re
import logging
from datetime import datetime
import warnings;warnings.filterwarnings('ignore')


def usage(_cmd_):
    print 'USAGE:'
    print '  '+os.path.basename(_cmd_)+' [-uh] <TAB> <DAY|DAT>'
    print 'PARAMETERS:'
    print '  TAB  PHI-TIME TABEL.'
    print '  DAY  Day to translate.'
    print '  DAT  DATAFILE (aelceborbcor.e1lc_temp2.dat)'
    sys.exit()
    
        
def setparam(_input_):
    try:
        opts, args = getopt.getopt(_input_[1:], "hu",
                                   ["help","pltab","TAB=","tab=","DAY=","day=",
                                    "LCDAT=","lcdat=","GTIDAT=","gtidat="
                                    ])
    except getopt.GetoptError, err:
        print str(err) # will print something like "option -a not recognized"
        sys.exit()
        
    #print 'opts',opts ##DEBUG
    #print 'args',args ##DEBUG

    cmd = _input_[0]
    pltflg = False
    tab = None
    day = -1
    lcdat = None
    gtidat = None
    for o, a in opts:
        if o in ("-u","-h","--help"):
            usage(cmd)
        elif o in ("--pltab"):
            pltflg = True
        elif o in ("--tab","--TAB"):
            tab = a
        elif o in ("--day","--DAY"):
            day = a
        elif o in ("--lcdat","--LCDAT"):
            lcdat = a
        elif o in ("--gtidat","--GTIDAT"):
            gtidat = a
        else:
            assert False, "unhandled option"
    # ...
    return cmd,pltflg,tab,day,lcdat,gtidat


class transtimphi:
    def __init__(self,_pltflg_,_tab_,_day_,_lcdat_,_gtidat_):
        self.tabfile=glob.glob('./'+str(_tab_))
        self.lcdatfile=glob.glob('./'+str(_lcdat_))
        self.gtidatfile=glob.glob('./'+str(_gtidat_))
        self.day=float(_day_)


    def read_tab(self):
        if os.path.exists(self.tabfile) is True:
            self.table = pd.read_csv(self.tabfile, 
                                header = 0,
                                names=['phi','day']
            )
            #print self.table
        else:
            print '%s does not exist!' %(self.tabfile)
            sys.exit()


    def day2phi(self,tim):
        p=interp1d(self.table['day'], self.table['phi'])
        p_supplement=p(tim)
        return p_supplement



    def plot_tab(self):
        msize = 1
        tmin = int(round(self.table['day'].min(),0))
        tmax = int(round(self.table['day'].max(),0))
        tmp = np.arange(tmin,tmax)
        
        fig = plt.figure(figsize=(8, 6))
        ax = fig.add_axes((0.1,0.1,0.85,0.85))

        ax.plot(self.table['day'],self.table['phi']/2/np.pi, 
                label="table",color="r",
                marker='.',ms=msize,zorder=1)
        ax.scatter(tmp,self.day2phi(tmp)/2/np.pi, 
                   label="function",color="b",
                   marker='o',s=msize,zorder=2)

        ax.set_xlabel(r'day')
        ax.set_ylabel(r'$\phi$(phase)')
        ax.tick_params(axis='both',which='both',direction='in')
        ax.legend(fontsize=8.0, loc=2, scatterpoints=1, numpoints=1,
                  fancybox=True, framealpha=1.0)
        plt.pause(1.0)
        plt.show()

            

    def translate(self):
        phi=self.day2phi(self.day)
        print '%17.15e' % phi


    def read_make_lcdata(self):
        file=self.lcdatfile
        data = pd.read_table(file[0], header = None,
                              delimiter=' ',
                              names=['TIME','DAY','RATE','ERROR','FRACEXP'])
        self.data = data
        self.data['PHI']=self.day2phi(self.data['DAY'])
        self.data['PHI'].to_csv('./transdayphioutlc.dat',
                                sep=' ',
                                index=None,index_label=False)
        #print self.data


    def read_make_gtidata(self):
        file=self.gtidatfile
        data = pd.read_table(file[0], header = None,
                              delimiter=' ',
                              names=['TSTART','DAYSTART','TSTOP','DAYSTOP'])
        self.data = data
        self.data['PHISTART']=self.day2phi(self.data['DAYSTART'])
        self.data['PHISTOP']=self.day2phi(self.data['DAYSTOP'])
        self.data[['PHISTART','PHISTOP']].to_csv(
            './transdayphioutgti.dat', sep=' ',
            index=None,index_label=False,header=None)
        #print self.data
           

if __name__ == '__main__':
    argvs = sys.argv  #
    argc = len(argvs)  #
    cmd,pltflg,tab,day,lcdat,gtidat=setparam(argvs)

    if tab is None:
        usage(cmd)
    else:
        func = transtimphi(pltflg,tab,day,lcdat,gtidat)
        func.read_tab()

        if pltflg is True:
            func.plot_tab()
            
        if lcdat is None and gtidat is None:
            func.translate()
        elif day == -1 and gtidat is None:
            func.read_make_lcdata()
        elif day == -1 and lcdat is None:
            func.read_make_gtidata()

    sys.exit()
         
