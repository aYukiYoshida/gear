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
    print '  '+os.path.basename(_cmd_)+' [-uh] <ORB> <ECC> <MJDZ> <OBSTA> <OBSTP> <ORBZ>'
    print 'PARAMETERS:'
    print '  ORB       Orbital period(day).'
    print '  ECC       Eccentricity of orbital.'
    print '  MJDZ      Reference zero point of MJD(day).'
    print '  OBSTA     Observation start time(sec).'
    print '  OBSTP     Observation end time(sec).'
    print '  ORBZ      Origin of orbital of MJD(day).'
    sys.exit()
    
        
def setparam(_input_):
    try:
        opts, args = getopt.getopt(_input_[1:], "hu",
                                   ["help","ORB=","orb=","ECC=","ecc=",
                                    "MJDZ=","mjdz=","OBSTA=","obsta=",
                                    "OBSTP=","obstp=","ORBZ=","orbz="])
    except getopt.GetoptError, err:
        print str(err) # will print something like "option -a not recognized"
        sys.exit()
        
    #print 'opts',opts ##DEBUG
    #print 'args',args ##DEBUG

    cmd = _input_[0]
    orb = None
    ecc = None
    mjdz = None
    obsta = None
    obstp = None
    orbz = None
    for o, a in opts:
        if o in ("-u","-h","--help"):
            usage(cmd)
        elif o in ("--orb","--ORB"):
            orb = a
        elif o in ("--ecc","--ECC"):
            ecc = a
        elif o in ("--mjdz","--MJDZ"):
            mjdz = a
        elif o in ("--obsta","--OBSTA"):
            obsta = a
        elif o in ("--obstp","--OBSTP"):
            obstp = a
        elif o in ("--orbz","--ORBZ"):
            orbz = a
        else:
            assert False, "unhandled option"
    # ...
    return cmd,orb,ecc,mjdz,obsta,obstp,orbz


class mkphittab:
    def __init__(self,__orb__,__ecc__,__mjdz__,__obsta__,__obstp__,__orbz__):
        self.num=3000
        self.orb=float(__orb__)
        self.ecc=float(__ecc__)
        self.mjdz=float(__mjdz__)
        self.obsta=float(__obsta__)
        self.obstp=float(__obstp__)
        self.orbz=float(__orbz__)
        self.n=2*np.pi/self.orb
        self.const=(1-self.ecc**2)**1.5/self.n
        self.datab = pd.DataFrame({ 'phi(rad)':[],
                                    'tim(day)':[]
                                    })
        


    def infunc(self,phi):
        t = 1.0/(1.0+self.ecc*math.cos(phi))**2
        return t


    def calctim(self):
        fct=0.5
        #fct=0.0
        sphista=self.n*(self.obsta/86400+self.mjdz-self.orbz-self.orb*fct) #unit of radian
        sphistp=self.n*(self.obstp/86400+self.mjdz-self.orbz+self.orb*fct) #unit of radian
        #print((self.obsta/86400+self.mjdz-self.orbz)/self.orb) #DEBUG
        #print((self.obstp/86400+self.mjdz-self.orbz)/self.orb) #DEBUG
        #print 'phi start '+str(sphista) #DEBUG
        #print 'phi stop  '+str(sphistp) #DEBUG
        df=(sphistp-sphista)/self.num;

        f=sphista
        while f <= sphistp:
            t=self.const*integrate.quad(self.infunc, 0.0, f, limit=1000000)[0]
            print '%17.15f %17.15f' %(f,t) # radian day
            tmp = pd.DataFrame({'phi(rad)':[f], 
                                'tim(day)':[t]
                                })
            
            f+=df


if __name__ == '__main__':
    argvs = sys.argv  #
    argc = len(argvs)  #
    cmd,orb,ecc,mjdz,obsta,obstp,orbz=setparam(argvs)
    #print 'orb   '+orb ## DEBUG
    #print 'ecc   '+ecc ## DEBUG
    #print 'mjdz  '+mjdz ## DEBUG
    #print 'obsta '+obsta ## DEBUG
    #print 'obstp '+obstp ## DEBUG
    #print 'orbz  '+orbz ## DEBUG

    if orb is None or ecc is None or mjdz is None or obsta is None or obstp is None or orbz is None :
        usage(cmd)
    else:
        func = mkphittab(orb,ecc,mjdz,obsta,obstp,orbz)
        func.calctim()
        exit()
         
