#!/usr/bin/env python

import sys, getopt
import glob
import math
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib import gridspec
from matplotlib.patches import Ellipse
import mpl_toolkits.axisartist as AA
from mpl_toolkits.axes_grid1 import host_subplot
from scipy.interpolate import interp1d
from scipy.interpolate import splev, splrep
from scipy.interpolate import InterpolatedUnivariateSpline
from scipy import integrate
import os, os.path
import scipy.optimize
import re
import logging
from astropy.io import fits
from datetime import datetime
import warnings;warnings.filterwarnings('ignore')


def usage(__cmd__):
    print 'USAGE:'
    print '  '+os.path.basename(__cmd__)+' [-uh] [--imgout] <MODE> <TAB>'
    print 'PARAMETERS:'
    print '  MODE      Analysis mode(calc/corr).'
    print '  EVTFITS   Events FITS file'
    print '  TAB       Data table of day-phi.'
    print '  PORB      Orbital period(day).'
    print '  ECC       Eccentricity of orbital.'
    print '  ASINI     Projected semimajor axis(lt-s).'
    print '  OMG       Longitude at the PERAST(degree).'
    print '  SPCONJ    Superior conjunction of MJD(day).'
    print '  PERAST    Periastron passage of MJD(day)'
    print 'Following descripts show parameters that you must input for each analysis mode.'
    print ' To calculate day-phi tabel: <MODE>=CALC'
    print '   <TAB> <PORB> <ECC>'    
    print ' To plot day-phi tabel: <MODE>=TPLT'
    print '   <TAB> <PORB>'    
    print ' To conduct binary orbital correction <MODE>=CORR'
    print '   <TAB> <PORB> <ASIN> <ECC> <OMG> <ORBORG|PERAST> <EVTFITS>'
    sys.exit()
    
        
def setparam(__input__):
    try:
        opts, args = getopt.getopt(__input__[1:], "hu",
                                   [ "help", "imgout",
                                     "PORB=","porb=","ECC=","ecc=",
                                     "SPCONJ=","SPCONJ=","PERAST=","perast=",
                                     "ASINI=","asini=","OMG=","omg=",
                                     "TAB=","tab=","EVTFITS=","evtfits=",
                                     "mode=","MODE=" ])
    except getopt.GetoptError, err:
        print str(err) # will print something like "option -a not recognized"
        sys.exit()
        
    #print 'opts',opts ##DEBUG
    #print 'args',args ##DEBUG

    cmd = __input__[0]
    mode = None
    porb = None
    ecc = None
    spconj = None
    perast = None
    asin = None
    omg = None
    tab = None
    evt = None
    imgout = False
    
    for o, a in opts:
        if o in ("-u","-h","--help"):
            usage(cmd)
        elif o in ("--imgout"):
            imgout = True
        elif o in ("--mode","--MODE"):
            mode = a
        elif o in ("--porb","--PORB"):
            porb = a
        elif o in ("--ecc","--ECC"):
            ecc = a
        elif o in ("--spconj","--SPCONJ"):
            spconj = a
        elif o in ("--perast","--PERAST"):
            perast = a
        elif o in ("--asini","--ASINI"):
            asin = a
        elif o in ("--omg","--OMG"):
            omg = a
        elif o in ("--evtfits","--EVTFITS"):
            evt = a
        elif o in ("--tab","--TAB"):
            tab = a
        else:
            assert False, "unhandled option"
    # ...
    return cmd,mode,porb,ecc,spconj,perast,asin,omg,tab,evt,imgout


class correct:
    def __init__(self,__porb__,__ecc__,__spconj__,__perast__,__asin__,__omg__,__tab__,__evt__,__imgout__):
        self.num = 5000
        self.dpi = 200
        self.imgout = __imgout__

        if __porb__ is not None:
            self.porb = float(__porb__)
            self.N = 2*np.pi/self.porb

        if __ecc__ is not None:
            self.ecc = float(__ecc__)

        if __porb__ is not None and __ecc__ is not None:
            self.const = ((1-self.ecc**2)**1.5)/self.N

        if __spconj__ is not None:
            self.spconj = float(__spconj__)
            
        if __perast__ is not None:
            self.perast = float(__perast__)
            self.spconj = None

        if __asin__ is not None:
            self.asin = float(__asin__)

        if __asin__ is not None and __ecc__ is not None:
            self.b = self.asin*np.sqrt(1-self.ecc**2)
            self.c = self.asin*self.ecc

        if __omg__ is not None:
            self.omg = float(__omg__)

        if __tab__ is not None:
            self.tabfile = str(__tab__)

        if __evt__ is not None:
            self.evt = str(__evt__)
            
        self.tmpdf = pd.DataFrame({'ang(radian)':[],
                                   'tim(day)':[],
                                   'phi(phase)':[] })
        

    ##--------------------------------------------------------------------------
    ## make tim(day)-phi(rad) table
    ##--------------------------------------------------------------------------
    def infunc(self,phi):
        y = (1.0+self.ecc*np.cos(phi))**(-2)
        return y

    
    def integrate(self,phi):
        t = self.const*integrate.quad(self.infunc, 0.0, phi, limit=1000000)[0]
        return t


    def calc_tab(self):
        phista=0.0*np.pi
        phistp=4.0*np.pi
        #print 'phi start %s'%(str(phista)) #DEBUG
        #print 'phi stop  %s'%(str(phistp)) #DEBUG
        dp=(phistp-phista)/self.num
        self.tmpdf['ang(radian)'] = phista+np.arange(0,self.num,1)*dp
        for i in np.arange(0,self.num,1):
            self.tmpdf['tim(day)'][i] = self.integrate(self.tmpdf['ang(radian)'][i])
        self.tmpdf['phi(phase)'] = self.tmpdf['tim(day)']/self.porb
        self.tmpdf.to_csv(self.tabfile)
        print '%s was generated' %(str(self.tabfile))
        #print self.tmpdf


    ##--------------------------------------------------------------------------
    ## plot tim(day)-phi(rad) table
    ##--------------------------------------------------------------------------
    def read_tab(self):
        if os.path.exists(self.tabfile) is True:
            self.table = pd.read_csv(self.tabfile, 
                                     header = 0,
                                     names=['ang','phi','day']
            )
            #print self.table
        else:
            print '%s does not exist!' %(str(self.tabfile))
            sys.exit()


    def phi2ang(self,p):
        ang = interp1d(self.table['phi'], self.table['ang'])
        ang_supplement = ang(p)
        return ang_supplement


    def deg2phi(self,deg):
        ang = np.radians(float(deg))
        phi = interp1d(self.table['ang'], self.table['phi'])
        phi_supplement = phi(ang)
        return float(phi_supplement)


    def plt_tab(self):
        tmp_day = np.arange(0.0, self.porb*1, 1)
        tmp_phi = tmp_day/self.porb
        fig = plt.figure(figsize=(8, 6))
        ax1 = fig.add_axes((0.1, 0.1, 0.85, 0.8))
        ax2 = ax1.twiny()
        
        ax1.plot(self.table['day'],self.table['ang'], 
                 label="ellipsoidal",color="r",
                 ls='-',lw=1,zorder=2)

        ax1.plot(self.table['day'],self.table['day']*self.N,
                 label="circular",color="green",
                 ls='--',lw=1,zorder=1)

        ax1.scatter(tmp_day,self.phi2ang(tmp_phi), 
                    label="interpolation",color="b",
                    marker='o',s=5,zorder=3)

        x1ticks = np.arange(0.0, round(self.porb)*2, round(round(self.porb)*0.1,1))
        x2ticks = np.arange(0.0, 1.1, 0.1)
        y1ticks = np.arange(0.0, 2*np.pi+0.1, 0.25*np.pi)
        xlim = [ -0.05, 1.05 ] #orbital phase
        ylim = [ -0.1, 2*np.pi+0.1 ] #angle in radian

        ax1.grid(True)
        ax1.xaxis.set_ticks(x1ticks)
        ax1.yaxis.set_ticks(y1ticks)
        ax1.set_yticklabels(['0.0','','0.5','','1.0','','1.5','','2.0'])
        ax1.set_xlim(xlim[0]*self.porb, xlim[1]*self.porb)
        ax1.set_ylim(ylim[0], ylim[1])
        
        ax2.xaxis.set_ticks(x2ticks)
        ax2.set_xticklabels(['0.0','','0.2','','0.4','','0.6','','0.8','','1.0',''])
        ax2.set_xlim(xlim[0], xlim[1])
        ax2.set_ylim(ylim[0], ylim[1])
        
        ax2.set_xlabel(r'orbital phase')
        ax1.set_xlabel(r'day from periastron passing time')
        ax1.set_ylabel(r'$\phi$($\pi$ radian)')
        ax1.tick_params(axis='both',which='both',direction='in')
        ax1.legend(fontsize=8.0, loc=4, scatterpoints=3, numpoints=1,
                   fancybox=True, framealpha=1.0)

        if self.imgout is True:
            outimg = self.tabfile.replace('tab','').replace('.csv','_tab.png')
            plt.savefig(outimg, format='png', dpi=self.dpi , transparent=True)
            print(outimg+' is generated')
        else:
            plt.pause(1.0)
            plt.show()



    ##--------------------------------------------------------------------------
    ## plot orbital
    ##--------------------------------------------------------------------------
    def orbital(self,phi):
        r = self.asin*(1-self.ecc**2)/(1+self.ecc*np.cos(phi))
        return r

    
    def spconj2perast(self):
        self.angspconj = 90.0-self.omg #in unit of degree
        if self.angspconj < 0.0:
            self.angspconj = self.angspconj + 360
        self.phispconj = self.deg2phi(self.angspconj) #in unit of phase
        self.perast = self.spconj-self.porb*self.phispconj


    def plt_orb(self):
        ms = 1; ma = '.'
        sms = 3; sma = 'o'
        lw = 1; ls = '-'; pls = '--'
        hl = self.asin/15.; hw = self.asin/15.

        fig = plt.figure(figsize=(8, 8))
        fig.subplots_adjust(left=0.1, right=0.9, 
                            top=0.9, bottom=0.1, 
                            wspace=0.1, hspace=0.1)
        ax = fig.add_subplot(111)


        # the center of the ellipse
        x = -1*self.c*np.cos(np.radians(self.omg))
        y = -1*self.c*np.sin(np.radians(self.omg))
                
        ax.add_artist(Ellipse(xy=[x,y],width=2.0*self.asin,height=2.0*self.b,
                              angle=self.omg,facecolor='none'))
        

        # the focus 
        xf = [x+self.c*np.cos(np.radians(self.omg)),
              x-self.c*np.cos(np.radians(self.omg))]
        
        yf = [y+self.c*np.sin(np.radians(self.omg)),
              y-self.c*np.sin(np.radians(self.omg))]
        ax.plot(xf,yf,'xb', zorder=2)


        # orbital phase
        orb_lll = self.asin*(1-self.ecc**2)
        orb_phi = np.arange(0.0,1.0,0.1)
        orb_cnf = map(str,list(orb_phi))
        if spconj is not None:
            orb_phi = orb_phi+self.phispconj
            mjr_phi = np.arange(0.0,1.0,0.5)
            mjr_ang = self.phi2ang(mjr_phi)
            mjr_rad = orb_lll/(1+self.ecc*np.cos(mjr_ang))
            mxr = mjr_rad*np.cos(mjr_ang)
            myr = mjr_rad*np.sin(mjr_ang)
            mxrp = mxr*np.cos(np.radians(self.omg))-myr*np.sin(np.radians(self.omg))
            myrp = mxr*np.sin(np.radians(self.omg))+myr*np.cos(np.radians(self.omg)) 
            for q in range(0,len(mjr_phi)):
                ax.plot([xf[0], xf[0]+mxrp[q]],[yf[0], yf[0]+myrp[q]],
                        color='blue',ls='--',lw=1.5,zorder=1)

        orb_ang = self.phi2ang(orb_phi)        
        orb_rad = orb_lll/(1+self.ecc*np.cos(orb_ang))


        # converting the radius based on the focus 
        # into x,y coordinates on the ellipse:
        xr = orb_rad*np.cos(orb_ang)
        yr = orb_rad*np.sin(orb_ang)
        

        # accounting for the rotation by anlge:
        xrp = xr*np.cos(np.radians(self.omg))-yr*np.sin(np.radians(self.omg))
        yrp = xr*np.sin(np.radians(self.omg))+yr*np.cos(np.radians(self.omg)) 
        
        # put labels outside the "rays"
        offset = self.asin*0.1
        rLabel = orb_rad+offset
        xrl = rLabel*np.cos(orb_ang)
        yrl = rLabel*np.sin(orb_ang)
        
        xrpl = xrl*np.cos(np.radians(self.omg)) - yrl*np.sin(np.radians(self.omg))
        yrpl = xrl*np.sin(np.radians(self.omg)) + yrl*np.cos(np.radians(self.omg))
        tlabel = np.degrees(orb_ang-np.pi)
        
        for q in range(0,len(tlabel)):
            if tlabel[q] >= 180.0:
                tlabel[q] -= 180.0

        for q in range(0,len(orb_phi)):
            ax.plot([xf[0], xf[0]+xrp[q]],[yf[0], yf[0]+yrp[q]],
                    color='black',ls='--',lw=1,zorder=1)
            ax.text(xf[0]+xrpl[q],yf[0]+yrpl[q],orb_cnf[q],
                    va='center', ha='center',
                    rotation=self.omg+tlabel[q])


        # put an arrow to "Earth"
        arrowfactor = -1.3
        ax.arrow(0, 0, 0, arrowfactor*self.asin, 
                 head_length=hl, head_width=hw,
                 edgecolor='black', facecolor='black', lw=1, zorder=1)
        ax.text(x=1E-01*self.asin,y=arrowfactor*self.asin, 
                s='To Earth', fontsize=12.0, va='top', ha='left')


        # plot observation
        angle = self.timdata[(self.timdata['DFT0']>0.0)]['ANG']
        self.timdata['r'] = orb_lll/(1+self.ecc*np.cos(angle))
        self.timdata['xr'] = self.timdata['r']*np.cos(angle)
        self.timdata['yr'] = self.timdata['r']*np.sin(angle)
        self.timdata['rxr'] = self.timdata['xr']*np.cos(np.radians(self.omg)) - self.timdata['yr']*np.sin(np.radians(self.omg))
        self.timdata['ryr'] = self.timdata['xr']*np.sin(np.radians(self.omg)) + self.timdata['yr']*np.cos(np.radians(self.omg))
        
        
        ax.scatter(self.timdata['rxr'], self.timdata['ryr'],
                   label='Suzaku',color='red',
                   marker=sma, s=sms, zorder=3)

        
        # observation phase-----------------------------------------------------
        """
        obs_phi = np.array( [ 0.19, 0.38 ] )
        obs_cnf = [ 'suzaku', 'suzaku' ]
        obs_ang = self.phi2ang(obs_phi)
        obs_rad = orb_lll/(1+self.ecc*np.cos(obs_ang))
        color = [ 'red', 'red' ]

        obs_xr = obs_rad*np.cos(obs_ang)
        obs_yr = obs_rad*np.sin(obs_ang)

        obs_xrp = obs_xr*np.cos(np.radians(self.omg))-obs_yr*np.sin(np.radians(self.omg))
        obs_yrp = obs_xr*np.sin(np.radians(self.omg))+obs_yr*np.cos(np.radians(self.omg)) 

        obs_rLabel = obs_rad+offset
        obs_xrl = obs_rLabel*np.cos(obs_ang)
        obs_yrl = obs_rLabel*np.sin(obs_ang)

        obs_xrpl = obs_xrl*np.cos(np.radians(self.omg)) - obs_yrl*np.sin(np.radians(self.omg))
        obs_yrpl = obs_xrl*np.sin(np.radians(self.omg)) + obs_yrl*np.cos(np.radians(self.omg))
        obs_tlabel = np.degrees(obs_ang-np.pi)

        for q in range(0,len(obs_tlabel)):
            if obs_tlabel[q] >= 180.0:
                obs_tlabel[q] -= 180.0


        for x,y,xp,yp,tl,t,c in zip(obs_xrp,obs_yrp,obs_xrpl,obs_yrpl,obs_tlabel,obs_cnf,color):
            ax.plot([xf[0], xf[0]+x], [yf[0], yf[0]+y],
                    color=c, ls=pls, lw=lw, ms=ms, marker=ma, zorder=1)
            ax.text(x=xf[0]+xp,y=yf[0]+yp,
                    rotation= self.omg+tl,
                    s=t, fontsize=12.0, va='center', ha='center', color='black')
        """
        # observation phase END-------------------------------------------------
        


        # celestial plane
        ax.plot([np.radians(self.omg-270),np.radians(self.omg-90)],
                [self.asin*2,self.asin*2],
                color='black', ls=ls, lw=lw, ms=ms, marker=ma, zorder=1)


        ax.grid(True)
        limin=-2000;limax=2000
        axis_tick = np.arange(limin,limax,50)
        axis_conf = map(str,list(axis_tick))
        ax.xaxis.set_ticks(axis_tick)
        ax.set_xticklabels(axis_conf)
        ax.yaxis.set_ticks(axis_tick)
        ax.set_yticklabels(axis_conf)
        scale = 1.8
        ax.set_xlim(-1*scale*self.asin,scale*self.asin)
        ax.set_ylim(-1*scale*self.asin,scale*self.asin)
        ax.set_xlabel('[lt-s]')
        ax.set_ylabel('[lt-s]')
        ax.yaxis.set_label_coords(-0.085, 0.5)
        #ax.legend(fontsize=8.0,loc=2,scatterpoints=1, fancybox=True, framealpha=1.0)
        ax.axhline(y=0, xmin=limin, xmax=limax, color='green', ls='--', lw=1.5)
        fig.suptitle(self.tabfile.replace('.csv',''))

        if self.imgout is True:
            outimg = self.evt.replace('.evt','_orb.png')
            plt.savefig(outimg, format='png', dpi=self.dpi , transparent=True)
            print(outimg+' is generated')
        else:
            plt.pause(1.0)
            plt.show()


    ##--------------------------------------------------------------------------
    def coraetime(self,aetime):
    ##--------------------------------------------------------------------------
        day = aetime/86400+self.mjdref #;print self.aetime
        dft0 = day-self.perast         #;print self.dft0
        phi = dft0/self.porb           #;print self.phi
        phii = int(phi)                #;print self.phii
        phif = phi-phii                #;print self.phif
        ang = self.phi2ang(phif)       #;print self.ang
        dtim = self.orbital(ang)*np.sin(ang+np.radians(self.omg)) #;print self.dtim
        ctim = aetime-dtim 
        return ctim,dtim

    
    ##--------------------------------------------------------------------------
    def mkcorevt(self):
    ##--------------------------------------------------------------------------
        self.hdulist = fits.open(self.evt)
        self.ext0dat = self.hdulist[0].data
        self.ext0hed = self.hdulist[0].header
        self.ext1dat = self.hdulist[1].data
        self.ext1hed = self.hdulist[1].header
        self.ext2dat = self.hdulist[2].data
        self.ext2hed = self.hdulist[2].header
        self.hdulist.close()
        
        self.mjdrefi = self.ext0hed['MJDREFI']
        self.mjdreff = self.ext0hed['MJDREFF']
        self.mjdref = self.mjdrefi+self.mjdreff  #ORIGIN OF SUZAKU TIME 


        ## correct TSTART and TSTOP keywords included in header of EVENTS FITS file 
        self.tsta = self.ext0hed['TSTART']
        self.tstp = self.ext0hed['TSTOP']
        self.ctsta,self.dtsta = self.coraetime(self.tsta)
        self.ctstp,self.dtstp = self.coraetime(self.tstp)
        self.target = str(self.ext0hed['OBJECT'])
        self.obsid = str(self.ext0hed['OBS_ID'])
        
        ##----------------------------------------------------------------------
        ## correct extension#1 of EVENTS FITS file
        ##----------------------------------------------------------------------

        ## correction of TIME column
        self.timdata = pd.DataFrame({'TIME':self.ext1dat['TIME']})
        self.timdata['DAY'] = self.mjdref+self.timdata['TIME']/86400
        self.timdata['DFT0'] = self.timdata['DAY']-self.perast
        self.timdata['PHI'] = self.timdata['DFT0']/self.porb
        self.timdata['PHII'] = self.timdata[['PHI']].astype(int)
        self.timdata['PHIF'] = self.timdata['PHI']-self.timdata['PHII']
        self.timdata['PHIF'].where(self.timdata['DFT0']>0.0,0.0,inplace=True)
        self.timdata['ANG'] = self.phi2ang(self.timdata['PHIF'])
        self.timdata['ANG'].where(self.timdata['DFT0']>0.0,0.0,inplace=True)
        self.timdata['DTIM'] = self.orbital(self.timdata['ANG'])\
                               *np.sin(self.timdata['ANG']+np.radians(self.omg))
        self.timdata['CTIM'] = self.timdata['TIME']-self.timdata['DTIM']
        self.timdataminday = int(self.timdata[(self.timdata['DFT0']>0.0)]['DAY'].min())
        self.ext1dat['TIME'] = self.timdata['CTIM']

        ## correction of header keywords of extension#1
        self.ext1hed['TSTART'] = self.ctsta
        self.ext1hed['TSTOP'] = self.ctstp
        self.ext1hed['TSTABOCA'] = self.dtsta
        self.ext1hed.comments['TSTABOCA'] = 'binary-orbit correction amount for TSTART'
        self.ext1hed['TSTPBOCA'] = self.dtstp
        self.ext1hed.comments['TSTPBOCA'] = 'binary-orbit correction amount for TSTOP'

        fits.writeto('borbcorpy_ext1.evt',self.ext1dat,self.ext1hed,clobber=True)

        
        ##----------------------------------------------------------------------
        ## correct extension#2 of EVENTS FITS file
        ##----------------------------------------------------------------------

        ## correction of START & STOP columns 
        self.gtidata = pd.DataFrame({'TSTA':self.ext2dat['START'],
                                     'TSTP':self.ext2dat['STOP']})
        self.gtidata['DSTA'] = self.mjdref+self.gtidata['TSTA']/86400.0
        self.gtidata['DSTP'] = self.mjdref+self.gtidata['TSTP']/86400.0
        self.gtidata['DFT0STA'] = self.gtidata['DSTA']-self.perast
        self.gtidata['DFT0STP'] = self.gtidata['DSTP']-self.perast
        self.gtidata['PSTA'] = self.gtidata['DFT0STA']/self.porb
        self.gtidata['PSTP'] = self.gtidata['DFT0STP']/self.porb
        self.gtidata['PISTA'] = self.gtidata[['PSTA']].astype(int)
        self.gtidata['PISTP'] = self.gtidata[['PSTP']].astype(int)
        self.gtidata['PFSTA'] = self.gtidata['PSTA']-self.gtidata['PISTA']
        self.gtidata['PFSTP'] = self.gtidata['PSTP']-self.gtidata['PISTP'] 
        self.gtidata['PFSTA'].where(self.gtidata['DFT0STA']>0.0,0.0,inplace=True)
        self.gtidata['PFSTP'].where(self.gtidata['DFT0STP']>0.0,0.0,inplace=True)
        self.gtidata['ANGSTA'] = self.phi2ang(self.gtidata['PFSTA'])
        self.gtidata['ANGSTP'] = self.phi2ang(self.gtidata['PFSTP'])
        self.gtidata['ANGSTA'].where(self.gtidata['DFT0STA']>0.0,0.0,inplace=True)
        self.gtidata['ANGSTP'].where(self.gtidata['DFT0STP']>0.0,0.0,inplace=True)
        self.gtidata['DTSTA'] = self.orbital(self.gtidata['ANGSTA'])\
                                *np.sin(self.gtidata['ANGSTA']+np.radians(self.omg))
        self.gtidata['DTSTP'] = self.orbital(self.gtidata['ANGSTP'])\
                                *np.sin(self.gtidata['ANGSTP']+np.radians(self.omg))
        self.gtidata['CTSTA'] = self.gtidata['TSTA']-self.gtidata['DTSTA']
        self.gtidata['CTSTP'] = self.gtidata['TSTP']-self.gtidata['DTSTP']
        self.gtidataminday = int(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA'].min())
        self.ext2dat['START'] = self.gtidata['CTSTA']
        self.ext2dat['STOP'] = self.gtidata['CTSTP']
        
        ## correction of header keywords of extension#2
        self.ext2hed['TSTART'] = self.ctsta
        self.ext2hed['TSTOP'] = self.ctstp
        self.ext2hed['TSTABOCA'] = self.ctsta
        self.ext2hed.comments['TSTABOCA'] = 'binary-orbit correction amount for TSTART'
        self.ext2hed['TSTPBOCA'] = self.ctstp
        self.ext2hed.comments['TSTPBOCA'] = 'binary-orbit correction amount for TSTOP'

        fits.writeto('borbcorpy_ext2.evt',self.ext2dat,self.ext2hed,clobber=True)
        

    ##--------------------------------------------------------------------------
    def plt_timdata(self):
    ##--------------------------------------------------------------------------
        fig = plt.figure(figsize=(8, 6))
        ax1 = fig.add_subplot(2,1,1)
        ax2 = fig.add_subplot(2,1,2, sharex=ax1)
        fig.subplots_adjust(left=0.12, bottom=0.095, right=0.95, 
                            top=0.95, wspace=0.15, hspace=0.1)


        ax1.scatter(self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                    self.timdata[(self.timdata['DFT0']>0.0)]['DTIM'], 
                    label='correction amount',
                    color='red', marker='o', s=2, zorder=1)
        ax2.scatter(self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                    self.timdata[(self.timdata['DFT0']>0.0)]['CTIM']/86400+self.mjdref-self.timdataminday,
                    label='after correction',
                    color="red", marker='o', s=2, zorder=2)
        ax2.plot(self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                 self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                 label='before correction',
                 color='green', ls='-', lw=1, zorder=1)

        for ax in (ax1,ax2):
            ax.grid(True)
            ax.tick_params(axis='both',which='both',direction='in')
            ax.legend(fontsize=8.0, loc=4, scatterpoints=1, numpoints=1,
                      fancybox=True, framealpha=1.0)
            ax.yaxis.set_label_coords(-0.1,0.5)

        ax1.tick_params(labelbottom="off")
        ax1.set_ylabel(r'$\Delta$t(sec)')
        ax2.set_xlabel('MJD-%s(day)'%(str(int(self.timdataminday))))
        ax2.set_ylabel('MJD-%s(day)'%(str(int(self.timdataminday))))
        fig.suptitle(self.tabfile.replace('.csv',''))

        if self.imgout is True:
            outimg = self.evt.replace('.evt','_tim.png')
            plt.savefig(outimg, format='png', dpi=self.dpi , transparent=True)
            print(outimg+' is generated')


    ##--------------------------------------------------------------------------
    def plt_gtidata(self):
    ##--------------------------------------------------------------------------
        fig = plt.figure(figsize=(8, 6))
        ax1 = fig.add_subplot(2,1,1)
        ax2 = fig.add_subplot(2,1,2, sharex=ax1)
        fig.subplots_adjust(left=0.12, bottom=0.095, right=0.95, 
                            top=0.95, wspace=0.15, hspace=0.1)


        ax1.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DTSTA'], 
                    label='correction amount(TSTART)',
                    color='red', marker='o', s=2, zorder=1)
        ax1.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DTSTP'], 
                    label='correction amount(TSTOP)',
                    color='blue', marker='o', s=2, zorder=1)

        ax2.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['CTSTA']/86400+self.mjdref-self.gtidataminday,
                    label='after correction(TSTART)',
                    color="red", marker='o', s=2, zorder=2)
        ax2.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['CTSTP']/86400+self.mjdref-self.gtidataminday,
                    label='after correction(TSTOP)',
                    color="blue", marker='o', s=2, zorder=2)

        ax2.plot(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                 self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                 label='before correction(TSTART)',
                 color='green', ls='-', lw=1, zorder=1)
        ax2.plot(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                 self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                 label='before correction(TSTOP)',
                 color='orange', ls='-', lw=1, zorder=1)

        for ax in (ax1,ax2):
            ax.grid(True)
            ax.tick_params(axis='both',which='both',direction='in')
            ax.legend(fontsize=8.0, loc=4, scatterpoints=1, numpoints=1,
                      fancybox=True, framealpha=1.0)
            ax.yaxis.set_label_coords(-0.1,0.5)

        ax1.tick_params(labelbottom="off")
        ax1.set_ylabel(r'$\Delta$t(sec)')
        ax2.set_xlabel('MJD-%s(day)'%(str(int(self.gtidataminday))))
        ax2.set_ylabel('MJD-%s(day)'%(str(int(self.gtidataminday))))
        fig.suptitle(self.tabfile.replace('.csv',''))

        if self.imgout is True:
            outimg = self.evt.replace('.evt','_gti.png')
            plt.savefig(outimg, format='png', dpi=self.dpi , transparent=True)
            print(outimg+' is generated')



    ##--------------------------------------------------------------------------
    def plt_data(self):
    ##--------------------------------------------------------------------------
        fig = plt.figure(figsize=(12, 9))
        gs1 = gridspec.GridSpec(2,1)
        gs1.update(left=0.1, right=0.48,bottom=0.1, top=0.9,
                   wspace=0.1, hspace=0.2)
        gs2 = gridspec.GridSpec(4,1)
        gs2.update(left=0.57, right=0.95, bottom=0.1, top=0.9,
                   wspace=0.1, hspace=0.1)
        ax1 = fig.add_subplot(gs1[0,0])
        ax2 = ax1.twiny()
        ax3 = fig.add_subplot(gs1[1,0],aspect='equal')
        ax4 = fig.add_subplot(gs2[0,0])
        ax5 = fig.add_subplot(gs2[1,0],sharex=ax4)
        ax6 = fig.add_subplot(gs2[2,0],sharex=ax4)
        ax7 = fig.add_subplot(gs2[3,0],sharex=ax4)

        
        ##----------------------------------------------------------------------
        ## visual setting
        ##----------------------------------------------------------------------
        ms = 1      # mark size
        ma = '.'    # marker
        sms = 3     # mark size for scattering plot
        sma = 'o'   # marker for scattering plot
        lw = 1.0    # line width
        ls = '-'    # line style
        sls = '--'  # line style for suplement
        slw = 2.0   # line style for suplement        
        fs = 12.0   # font size 
        lfs = 8.0   # font size for legend

        
        ##----------------------------------------------------------------------
        ## plot table
        ##----------------------------------------------------------------------
        tmp_day = np.arange(0.0, self.porb*1, 1)
        tmp_phi = tmp_day/self.porb


        ax1.plot(self.table['day'],self.table['ang'], 
                 label="ellipsoidal",color="r",
                 ls='-',lw=lw,zorder=2)

        ax1.plot(self.table['day'],self.table['day']*self.N,
                 label="circular",color="green",
                 ls='--',lw=lw,zorder=1)

        ax1.scatter(tmp_day,self.phi2ang(tmp_phi), 
                    label="interpolation",color="b",
                    marker=sma,s=sms,zorder=3,rasterized=True)
        
        x1ticks = np.arange(0.0, round(self.porb)*2, round(round(self.porb)*0.1,1))
        x2ticks = np.arange(0.0, 1.1, 0.1)
        y1ticks = np.arange(0.0, 2*np.pi+0.1, 0.25*np.pi)
        xlim = [ -0.05, 1.05 ] #orbital phase
        ylim = [ -0.1, 2*np.pi+0.1 ] #angle in radian

        ax1.grid(True)
        ax1.xaxis.set_ticks(x1ticks)
        ax1.yaxis.set_ticks(y1ticks)
        ax1.set_yticklabels(['0.0','','0.5','','1.0','','1.5','','2.0'])
        ax1.set_xlim(xlim[0]*self.porb, xlim[1]*self.porb)
        ax1.set_ylim(ylim[0], ylim[1])
        
        ax2.xaxis.set_ticks(x2ticks)
        ax2.set_xticklabels(['0.0','','0.2','','0.4','','0.6','','0.8','','1.0',''])
        ax2.set_xlim(xlim[0], xlim[1])
        ax2.set_ylim(ylim[0], ylim[1])
        
        ax2.set_xlabel(r'orbital phase')
        ax1.set_xlabel(r'day from periastron passing time')
        ax1.set_ylabel(r'$\phi$($\pi$ radian)')
        ax1.tick_params(axis='both',which='both',direction='in')
        ax1.legend(fontsize=lfs, loc=4, scatterpoints=3, numpoints=1,
                   fancybox=True, framealpha=1.0)


        ##----------------------------------------------------------------------
        ## plot orbital
        ##----------------------------------------------------------------------
        hl = self.asin/15.; hw = self.asin/15.
                
        # the center of the ellipse
        x = -1*self.c*np.cos(np.radians(self.omg))
        y = -1*self.c*np.sin(np.radians(self.omg))
                
        ax3.add_artist(Ellipse(xy=[x,y],width=2.0*self.asin,height=2.0*self.b,
                               angle=self.omg,facecolor='none'))
        

        # the focus 
        xf = [x+self.c*np.cos(np.radians(self.omg)),
              x-self.c*np.cos(np.radians(self.omg))]
        
        yf = [y+self.c*np.sin(np.radians(self.omg)),
              y-self.c*np.sin(np.radians(self.omg))]
        ax3.plot(xf,yf,'xb', zorder=2)


        # orbital phase
        orb_lll = self.asin*(1-self.ecc**2)
        orb_phi = np.arange(0.0,1.0,0.1)
        orb_cnf = map(str,list(orb_phi))
        if spconj is not None:
            orb_phi = orb_phi+self.phispconj
            mjr_phi = np.arange(0.0,1.0,0.5)
            mjr_ang = self.phi2ang(mjr_phi)
            mjr_rad = orb_lll/(1+self.ecc*np.cos(mjr_ang))
            mxr = mjr_rad*np.cos(mjr_ang)
            myr = mjr_rad*np.sin(mjr_ang)
            mxrp = mxr*np.cos(np.radians(self.omg))-myr*np.sin(np.radians(self.omg))
            myrp = mxr*np.sin(np.radians(self.omg))+myr*np.cos(np.radians(self.omg)) 
            for q in range(0,len(mjr_phi)):
                ax3.plot([xf[0], xf[0]+mxrp[q]],[yf[0], yf[0]+myrp[q]],
                         color='blue',ls=sls,lw=lw,zorder=1)

        orb_ang = self.phi2ang(orb_phi)        
        orb_rad = orb_lll/(1+self.ecc*np.cos(orb_ang))

        # converting the radius based on the focus 
        # into x,y coordinates on the ellipse:
        xr = orb_rad*np.cos(orb_ang)
        yr = orb_rad*np.sin(orb_ang)
        

        # accounting for the rotation by anlge:
        xrp = xr*np.cos(np.radians(self.omg))-yr*np.sin(np.radians(self.omg))
        yrp = xr*np.sin(np.radians(self.omg))+yr*np.cos(np.radians(self.omg)) 
        
        # put labels outside the "rays"
        offset = self.asin*0.2
        rLabel = orb_rad+offset
        xrl = rLabel*np.cos(orb_ang)
        yrl = rLabel*np.sin(orb_ang)
        
        xrpl = xrl*np.cos(np.radians(self.omg)) - yrl*np.sin(np.radians(self.omg))
        yrpl = xrl*np.sin(np.radians(self.omg)) + yrl*np.cos(np.radians(self.omg))
        tlabel = np.degrees(orb_ang-np.pi)
        
        for q in range(0,len(tlabel)):
            if tlabel[q] >= 180.0:
                tlabel[q] -= 180.0

        for q in range(0,len(orb_phi)):
            ax3.plot([xf[0], xf[0]+xrp[q]],[yf[0], yf[0]+yrp[q]],
                     color='black',ls=sls,lw=lw,zorder=1)
            ax3.text(xf[0]+xrpl[q],yf[0]+yrpl[q],orb_cnf[q],
                     va='center', ha='center',
                     rotation=self.omg+tlabel[q])
            
        # put an arrow to "Earth"
        arrowfactor = -1.4
        ax3.arrow(0, 0, 0, arrowfactor*self.asin, 
                  head_length=hl, head_width=hw,
                  edgecolor='black', facecolor='black', lw=lw, zorder=1)
        ax3.text(x=1E-01*self.asin,y=arrowfactor*self.asin, 
                 s='To Earth', fontsize=fs, va='top', ha='left')


        # plot observation
        angle = self.timdata[(self.timdata['DFT0']>0.0)]['ANG']
        self.timdata['r'] = orb_lll/(1+self.ecc*np.cos(angle))
        self.timdata['xr'] = self.timdata['r']*np.cos(angle)
        self.timdata['yr'] = self.timdata['r']*np.sin(angle)
        self.timdata['rxr'] = self.timdata['xr']*np.cos(np.radians(self.omg)) - self.timdata['yr']*np.sin(np.radians(self.omg))
        self.timdata['ryr'] = self.timdata['xr']*np.sin(np.radians(self.omg)) + self.timdata['yr']*np.cos(np.radians(self.omg))
        
        
        ax3.scatter(self.timdata['rxr'], self.timdata['ryr'],
                    label='Suzaku',color='red',
                    marker=sma, s=sms, zorder=3, rasterized=True)
        

        # celestial plane
        ax3.plot([np.radians(self.omg-270),np.radians(self.omg-90)],
                 [self.asin*2,self.asin*2],
                 color='black', ls=ls, lw=lw, ms=ms, marker=ma, zorder=1)


        ax3.grid(True)
        limin=-2000;limax=2000
        axis_tick = np.arange(limin,limax,50)
        axis_conf = map(str,list(axis_tick))
        ax3.xaxis.set_ticks(axis_tick)
        ax3.set_xticklabels(axis_conf)
        ax3.yaxis.set_ticks(axis_tick)
        ax3.set_yticklabels(axis_conf)
        scale = 1.8
        ax3.set_xlim(-1*scale*self.asin,scale*self.asin)
        ax3.set_ylim(-1*scale*self.asin,scale*self.asin)
        ax3.set_xlabel('[lt-s]')
        ax3.set_ylabel('[lt-s]')
        ax3.yaxis.set_label_coords(-0.085, 0.5)
        ax3.axhline(y=0, xmin=limin, xmax=limax, color='green', ls=sls, lw=lw)


        ##----------------------------------------------------------------------
        ## plot time & gti data
        ##----------------------------------------------------------------------
        ax4.scatter(self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                    self.timdata[(self.timdata['DFT0']>0.0)]['DTIM'], 
                    label='correction amount',
                    color='red', marker=sma, s=sms, zorder=1, rasterized=True)

        ax5.scatter(self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                    self.timdata[(self.timdata['DFT0']>0.0)]['CTIM']/86400+self.mjdref-self.timdataminday,
                    label='after correction',
                    color="red", marker=sma, s=sms, zorder=2, rasterized=True)
        ax5.plot(self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                 self.timdata[(self.timdata['DFT0']>0.0)]['DAY']-self.timdataminday,
                 label='before correction',
                 color='green', ls=ls, lw=lw, zorder=1)

        ax6.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DTSTA'], 
                    label='correction amount(TSTART)',
                    color='red', marker=sma, s=sms, zorder=1)

        ax6.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DTSTP'], 
                    label='correction amount(TSTOP)',
                    color='blue', marker=sma, s=sms, zorder=1)

        ax7.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['CTSTA']/86400+self.mjdref-self.gtidataminday,
                    label='after correction(TSTART)',
                    color="red", marker=sma, s=sms, zorder=2, rasterized=True)

        ax7.scatter(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                    self.gtidata[(self.gtidata['DFT0STA']>0.0)]['CTSTP']/86400+self.mjdref-self.gtidataminday,
                    label='after correction(TSTOP)',
                    color="blue", marker=sma, s=sms, zorder=2, rasterized=True)

        ax7.plot(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                 self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTA']-self.gtidataminday,
                 label='before correction(TSTART)',
                 color='green', ls=ls, lw=lw, zorder=1)

        ax7.plot(self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                 self.gtidata[(self.gtidata['DFT0STA']>0.0)]['DSTP']-self.gtidataminday,
                 label='before correction(TSTOP)',
                 color='orange', ls=ls, lw=lw, zorder=1)

        
        for ax in (ax4,ax5,ax6,ax7):
            ax.grid(True)
            ax.tick_params(axis='both',which='both',direction='in')
            ax.legend(fontsize=lfs, loc=4, scatterpoints=3, numpoints=1,
                      fancybox=True, framealpha=1.0)
            ax.yaxis.set_label_coords(-0.11,0.5)

        for ax in (ax4,ax5,ax6):
            ax.tick_params(labelbottom="off")

        ax4.set_title('event FITS:'+self.evt,fontsize=fs)
        ax4.set_ylabel(r'$\Delta$t(sec)')
        ax5.set_ylabel('MJD-%s(day)'%(str(int(self.timdataminday))))
        ax6.set_ylabel(r'$\Delta$t(sec)')
        ax7.set_ylabel('MJD-%s(day)'%(str(int(self.gtidataminday))))
        ax7.set_xlabel('MJD-%s(day)'%(str(int(self.timdataminday))))

        fig.suptitle('suzaku binary orbital correction TARGET:'+self.target+'/SEQ:'+self.obsid,
                     fontsize=fs)
        
        if self.imgout is True:
            fltype = 'pdf'
            outimg = self.evt.replace('.evt','_borbcor.'+fltype)
            plt.savefig(outimg, format=fltype, papertype='a4',
                        dpi=self.dpi)
            print(outimg+' is generated')
        else:
            plt.pause(1.0)
            plt.show()
        
        
##------------------------------------------------------------------------------
## MAIN
##------------------------------------------------------------------------------
if __name__ == '__main__':
    argvs = sys.argv  #
    argc = len(argvs)  #
    cmd,mode,porb,ecc,spconj,perast,asin,omg,tab,evt,imgout=setparam(argvs)


    if mode is None:
        print 'Please input <MODE>'
    
    else:
        func = correct(porb,ecc,spconj,perast,asin,omg,tab,evt,imgout)

        if str(mode) == 'calc':
            if porb is None or ecc is None or tab is None :
                usage(cmd)
            else:
                func.calc_tab()
                func.read_tab()
                #func.plt_tab()

        elif str(mode) == 'corr':
            if tab is None \
                    or porb is None or ecc is None or asin is None or omg is None \
                    or (spconj is None and perast is None ) or evt is None:
                usage(cmd)
            else:
                func.read_tab()

                if perast is None and spconj is not None:
                    func.spconj2perast()

                func.mkcorevt()
                #func.plt_timdata()
                #func.plt_gtidata()
                #func.plt_orb()
                func.plt_data()
                    
        else:
            usage(cmd)

    sys.exit()
         
