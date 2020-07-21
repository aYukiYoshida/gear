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

def usage(_cmd_):
    print 'USAGE:'
    print '  '+os.path.basename(_cmd_)+' [-uh] <TAB> <GTI> <ORB> <ECC> <OMG>'
    print 'PARAMETERS:'
    print '  TAB  PHI-TIME TABEL.'
    print '  GTI  GTI ASCII FILE.'
    print '  ORB  Orbital period(day).'
    print '  ECC  Eccentricity of orbital.'
    print '  OMG  Longitude at the ORBZERO in unit of degree.'
    sys.exit()
    
        
def setparam(_input_):
    try:
        opts, args = getopt.getopt(_input_[1:], "hu",
                                   ["help","TAB=","tab=","gti=",
                                    "ASINI=","asini=","ECC=","ecc=",
                                    "OMG=","omg=","PORB=","porb="])
    except getopt.GetoptError, err:
        print str(err) # will print something like "option -a not recognized"
        sys.exit()
        
    #print 'opts',opts ##DEBUG
    #print 'args',args ##DEBUG

    cmd = _input_[0]
    for o, a in opts:
        if o in ("-u","-h","--help"):
            usage(cmd)
        elif o in ("--tab","--TAB"):
            tab = a
        elif o in ("--gti","--GTI"):
            gti = a
        elif o in ("--porb","--PORB"):
            orb = a
        elif o in ("--asini","--ASINI"):
            asi = a
        elif o in ("--ecc","--ECC"):
            ecc = a
        elif o in ("--omg","--OMG"):
            omg = a
        else:
            assert False, "unhandled option"
    # ...
    return cmd,tab,gti,orb,asi,ecc,omg


class mkphiphitab:
    def __init__(self,_tab_,_gti_,_orb_,_asi_,_ecc_,_omg_):
        self.tabfile = glob.glob('./'+str(_tab_))
        self.gtifile = glob.glob('./'+str(_gti_))
        self.orb = float(_orb_)
        self.asi = float(_asi_)
        self.ecc = float(_ecc_)
        self.omg = np.radians(float(_omg_))


        
    def caldp(self,p):
        dt = self.asi*(1-self.ecc**2)*np.sin(p+self.omg)/(1+self.ecc*np.cos(p+self.omg))
        dp = dt/86400/self.orb*2*np.pi #radian
        return dp


    def read_calc_tab(self):
        file=self.tabfile
        table = pd.read_table(file[0], header = None,
                              delimiter=' ',
                              names=['phi','day'])
        self.table = table
        self.table['mphi'] = self.table['phi'] - self.caldp(self.table['phi'])
        #print self.table


    def modphi(self,in_phi):
        p=interp1d(self.table['mphi'], self.table['phi'])
        p_supplement=p(in_phi)
        return p_supplement
    
    
    def read_make_gti(self):
        file=self.gtifile
        data = pd.read_table(file[0], header = None,
                             delimiter=' ',
                             names=['MPHISTART','MPHISTOP'])
        self.data = data
        self.data['PHISTART']=self.modphi(self.data['MPHISTART'])
        self.data['PHISTOP']=self.modphi(self.data['MPHISTOP'])
        self.data[['PHISTART','PHISTOP']].to_csv('./modphioutgti.dat',
                                                 sep=' ',
                                                 index=None,
                                                 index_label=False,
                                                 header=None)

    def plot_modphi(self):
        msize = 1
        pmin = int(round(self.table['mphi'].min(),0)+1)
        pmax = int(round(self.table['mphi'].max(),0)-1)
        tmp = np.arange(pmin,pmax)
        
        fig = plt.figure(figsize=(8, 6))
        ax = fig.add_axes((0.1,0.1,0.85,0.85))

        ax.plot(self.table['mphi'],self.table['phi'], 
                label="table",color="r",
                marker='.',ms=msize,zorder=1)
        ax.scatter(tmp,self.modphi(tmp), 
                   label="function",color="b",
                   marker='o',s=msize,zorder=2)

        ax.set_xlabel(r'modified $\phi$')
        ax.set_ylabel(r'$\phi$')
        ax.tick_params(axis='both',which='both',direction='in')
        ax.legend(fontsize=8.0, loc=2, scatterpoints=1, numpoints=1,
                  fancybox=True, framealpha=1.0)
        plt.pause(1.0)
        plt.show()


if __name__ == '__main__':
    argvs = sys.argv  #
    argc = len(argvs)  #
    cmd,tab,gti,orb,asi,ecc,omg=setparam(argvs)
    #print 'orb   '+orb ## DEBUG
    #print 'asini '+asi ##
    #print 'ecc   '+ecc ## DEBUG
    #print 'omg   '+omg ## DEBUG

    if tab is None or gti is None or orb is None or ecc is None or asi is None or omg is None:
        usage(cmd)
    else:
        func = mkphiphitab(tab,gti,orb,asi,ecc,omg)
        func.read_calc_tab()
        func.read_make_gti()
        #func.plot_modphi() ## DEBUG
        exit()
         
