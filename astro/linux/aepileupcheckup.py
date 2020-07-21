#!/usr/bin/env python


""" aepileupcheckup.py is to check pileup effect of Suzaku XIS 

This is a python script to estimate the CCD region affected by pileup events. 
History: 
2010-11 ; ver 0.0; wrriten by S. Yamada
2011-01 ; ver 0.1; minnor revises done by T. Yuasa
2011-02 ; ver 1.0; compiled and released by S. Yamada
2011-12 ; ver 1.1; minor bugs are fixed by S. Yamada
"""

__author__ =  'Shinya Yamada (yamada(at)juno.phys.s.u-tokyo.ac.jp)'
__version__=  '1.1'


# modules used in the scripts,
# if some are not needed for your purpose, please comment them out. 
import os 
import sys
import math
import commands 
import numpy as np
import matplotlib.cm as cm
import matplotlib.mlab as mlab
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator, FormatStrFormatter, FixedLocator
import pyfits
import optparse
from matplotlib.font_manager import fontManager, FontProperties
import matplotlib.pylab as plab
import yaml


# basic mathematical functions
def circlearea (r):
    return math.pi * ( r *  r)

def fanarea (radius,width):
    tri = 0.5 * width * math.sqrt(radius*radius - width*width) 
    fan = 0.5 * radius * radius * math.asin(width/radius)
    return 4. * ( tri + fan) 

def diverr(x,dx,y,dy):
    return x/y * math.sqrt ( (dx / x) * (dx /x) + (dy/y) * (dy/y) )

def pileupfraction (r):
    if r < 0 :
        return 0.
    else:
        return ( 1. - ( 1. + r ) * math.exp( -1. * r )  ) / (1. - math.exp( -1. * r))


# Image class. This is the unique class in the script. 

class Image():

    # member variables 
    debug = False

    cx = 777.
    cy = 777.
    maxradius = 360.0
    linlogthre = 100.0
    xyviewsize = 30.0
    pileupfreer = 180.0
    plotwindow = False
    
    def __init__ (self, eventfile, shortname, binsize, quickflag):

        if not quickflag:
            self.eventfilename = eventfile
            self.shortname = shortname
            self.binsize = binsize

            #extract header information 
            if os.path.isfile(eventfile):            
                self.eventfits = pyfits.open(eventfile)
                self.instrume = self.eventfits[0].header['INSTRUME']                                          
                self.clk_mode = self.eventfits[0].header['CLK_MODE']
                dicwinopt = {0:'Off',1:'1/4',2:'1/8'}
                self.winopt = dicwinopt[self.eventfits[0].header['WINOPT']]            
                self.snapti1 = self.eventfits[0].header['SNAPTI1']

                if self.snapti1 <=0: # Psum
                    self.snapti1 = 0.0078
                    self.psumflag = True
                    self.psum_l = 128 # row number summed in P-sum mode
                else:
                    self.psumflag = False
                    
                # These are based on NEP observation, 100018010. 2007/10/16
                if self.instrume == 'XIS1':
                    self.nxb = {'std':4.78e-7 * self.snapti1,'e3':2.34e-7 * self.snapti1 ,'e7':1.44e-7 * self.snapti1 ,'split':3.39e-7 * self.snapti1 ,'g1':7.60e-10 * self.snapti1, 'e3split':1.87e-7 * self.snapti1, 'e7split':1.2e-7 * self.snapti1,'e3g1':3.64e-10 * self.snapti1, 'e7g1':1.65e-10 * self.snapti1} # estimated from psum obs. in LOCKMAN_HOLE 2010-06-11
 #                   print("XIS BI", self.nxb)
                else:
                    if self.psumflag:
                        self.nxb = {'std':6e-7, 'e3':4e-7,'e7': 8e-8, 'split':0.,'g1':0., 'e3split':2.5e-7, 'e7split':5.0e-8,'e3g1':1e-7, 'e7g1':0.}
                    else:
                        self.nxb = {'std':1.90e-7 * self.snapti1 ,'e3':9.68e-8 * self.snapti1 ,'e7':3.27e-8 * self.snapti1,'split':5.31e-8 * self.snapti1,'g1':4.97e-10 * self.snapti1, 'e3split':3.99e-8 * self.snapti1, 'e7split':1.50e-8 * self.snapti1,'e3g1':4.19e-10 * self.snapti1, 'e7g1':5e-10 * self.snapti1}
#                    print("XIS FI", self.nxb)

                self.delay1 = self.eventfits[0].header['DELAY1']
                self.obsid = self.eventfits[0].header['OBS_ID']
                self.object = self.eventfits[0].header['OBJECT']
                self.winsiz = self.eventfits[0].header['WIN_SIZ']

                if self.winsiz <= 0:
                    self.winsiz = 1024

                self.winst = self.eventfits[0].header['WIN_ST']
                self.nom_pnt = self.eventfits[0].header['NOM_PNT']
                self.date = self.eventfits[0].header['DATE-OBS']
                self.ontime = self.eventfits[0].header['ONTIME']
                self.tstart = self.eventfits[0].header['TSTART']
                self.tstop = self.eventfits[0].header['TSTOP']
                self.ra_pnt = self.eventfits[0].header['RA_PNT']
                self.dec_pnt = self.eventfits[0].header['DEC_PNT']
                self.exposure = self.eventfits[0].header['EXPOSURE']
                
                if self.exposure <= 0 :
                    print("exposure is 0, thus ontime is set as exposure")
                    self.exposure = self.ontime # for psum
                tmpdt = self.tstop - self.tstart
                print("-- tstart, tstop, dt", self.tstart, self.tstop, tmpdt)

                # create lin and log image
                self.image2d = self.eventfits[0].data
                self.logimage2d = np.arange(0.0,len(self.image2d)*len(self.image2d),1.0);
                self.logimage2d.shape = len(self.image2d),len(self.image2d)
                for x in range(len(self.image2d)):
                    for y in range(len(self.image2d)):        
                        if self.image2d[x][y] > 0:                        
                            self.logimage2d[x][y] = math.log10(float(self.image2d[x][y]))   
                        else:
                            self.logimage2d[x][y] = 0.

                # create radius 
                if self.maxradius > self.linlogthre:
                
                    linbin = math.floor( (self.linlogthre / self.binsize) - 2)
                    logbin = math.floor( ((self.maxradius - self.linlogthre)/self.binsize)*0.35  )
                    logymin = math.log10(self.linlogthre); logymax = math.log10(self.maxradius)
                    linxr = np.linspace(0.,self.linlogthre,9.);
                    #linxr = np.linspace(0,self.linlogthre,linbin);
                    logxr = np.logspace(logymin,logymax,logbin)
                    # 1D array of radius for loop
                    self.radius = np.append(linxr,logxr[1:])
                    if self.debug: 
                        print("checking.... radius")
#                        print(self.radius)
                else:
                    self.radius = np.linspace(0,self.maxradius,self.binsize)

                postradius = self.radius[1:]; preradius = self.radius[0:-1]
                # 1D array of radius for plots 
                self.xradius = (postradius + preradius) * 0.5 
                self.err_xradius = (postradius - preradius) * 0.5

                # define other members.
                self.rrate = np.zeros(len(self.xradius))
                self.err_rrate = np.zeros(len(self.xradius))
                self.ratiorrate = np.zeros(len(self.xradius))
                self.err_ratiorrate = np.zeros(len(self.xradius))
                self.normedratiorrate = np.zeros(len(self.xradius))
                self.err_normedratiorrate = np.zeros(len(self.xradius))
                self.plrrate = np.zeros(len(self.xradius))
                self.err_plrrate = np.zeros(len(self.xradius))
                                                                                                                        
                if self.debug: 
                    print("xradius")
                    print(self.xradius)
                    print("err xradius")
                    print(self.err_xradius)


            else:
                print("ERROR: cat't find the fits file : ", self.eventfilename)
                quit()

        else:
            print("creating from yaml files")
            eve = eventfile
            self.eventfilename = eve['eventfilename']
            self.shortname =     eve['shortname']
            self.binsize =       eve['binsize']
            self.instrume =      eve['instrume']
            self.clk_mode =      eve['clk_mode']
            self.winopt =        eve['winopt']
            self.snapti1 =       eve['snapti1']
            self.nxb =           eve['nxb']
            self.delay1 =   eve['delay1']
            self.obsid =    eve['obsid']
            self.object =   eve['object']
            self.winsiz =  eve['winsiz']
            self.winst =   eve['winst']
            self.date =    eve['date']
            self.ontime =  eve['ontime']
            self.tstart =  eve['tstart']
            self.tstop =   eve['tstop']
            self.exposure= eve['exposure']
            self.xradius = eve['xradius']
            self.err_xradius =    np.array(eve['err_xradius'])
            self.shortname =      eve['shortname']
            self.rrate =          np.array(eve['rrate'])
            self.err_rrate =      np.array(eve['err_rrate'])
            self.ratiorrate =     np.array(eve['ratiorrate'])
            self.err_ratiorrate = np.array(eve['err_ratiorrate'])
            self.normedratiorrate = np.array(eve['normedratiorrate'])
            self.err_normedratiorrate = np.array(eve['err_normedratiorrate'])
            self.plrrate = np.array(eve['plrrate'])
            self.err_plrrate = np.array(eve['err_plrrate'])
            self.maxradius =   np.array(eve['maxradius'])
            self.cx =          eve['cx']
            self.cy =          eve['cy']
            self.xyviewsize =  eve['xyviewsize']
            self.nom_pnt =     eve['nom_pnt']
            
            if eve.has_key('logimage2d'):
                self.logimage2d =  np.array(eve['logimage2d'])

                                
    def cxcycalc(self):

        tmpmaxcount = 0. # the maximum counts of the image

        for x in range(len(self.image2d)):
            for y in range(len(self.image2d)):        
                if float(self.image2d[x][y]) > tmpmaxcount: 
                    tmpmaxcount = float(self.image2d[x][y])
                    self.cx = x
                    self.cy = y
    
    def mkrprofile(self,spectype,base):

        print("------------------------------------------------------------")
        print("==== start... mkrprofile from " + self.eventfilename)
        print("------------------------------------------------------------")
        self.rrate = np.zeros(len(self.xradius))
        self.err_rrate = np.zeros(len(self.xradius))
        # pileup rate
        self.plrrate = np.zeros(len(self.xradius))
        self.err_plrrate = np.zeros(len(self.xradius))

        self.area = np.zeros(len(self.xradius))
        self.sumpixelarea = np.zeros(len(self.xradius))

        area = 0.
        sumpixelarea = 0. # for HXD nominal
        tmpimg = 0.
        # create r profiles of grade 1 ratios. 
        for rnum in range(len(self.radius)):
            if (rnum == 0):
                armin = self.radius[rnum] 
            else:
                armax = self.radius[rnum]

                if armax <= 0.5 * self.winsiz:
                    outarea = circlearea(armax)
                else:
                    outarea = fanarea(armax,0.5 * self.winsiz)
                    
                if armin <= 0.5 * self.winsiz:
                    inarea = circlearea(armin)
                else:
                    inarea = fanarea(armin,0.5 * self.winsiz) 
                    
                area = outarea - inarea
                if self.psumflag:
                    area = ( armax - armin ) * self.psum_l
                self.area[rnum-1] = area
                
                for y in range(len(self.image2d)):
                    for x in range(len(self.image2d)):
                        if self.image2d[x][y] > 0:
                            r = self.binsize * math.sqrt( (x - self.cx) * (x - self.cx) + (y - self.cy) * (y - self.cy) )
                            #print("armin, armax, rnum, r", armin, armax, rnum,r)
                            if r > armin and r <= armax:
                                tmpimg = tmpimg + float(self.image2d[x][y])
                                sumpixelarea = sumpixelarea + self.binsize * self.binsize

                if self.shortname == 'std':
                #    print("entering std....")
                    if self.nom_pnt == 'HXD' and self.snapti1 < 2.1 and self.snapti1 > 0.9:
                        print("------  area, sumpixelarea, armax", area, sumpixelarea, armax)
                        if sumpixelarea > 0.1 * area:
                            print("====== set area ==== ")
                            self.sumpixelarea[rnum -1 ] = sumpixelarea
                            area = sumpixelarea
                else:
                    if self.nom_pnt == 'HXD' and self.snapti1 < 2.1 and self.snapti1 > 0.9:
                        print("entering HXD and snapti < 2.1 and except std")
                        if base.sumpixelarea[rnum -1 ] > 0.:
                            area =  base.sumpixelarea[rnum -1 ]

                self.rrate[rnum-1] = (tmpimg / area / self.exposure ) * self.snapti1  - self.nxb[spectype]
                if self.rrate[rnum-1] < 0:
                    self.rrate[rnum-1] = 0.
                self.err_rrate[rnum-1] = (math.sqrt(tmpimg) / area / self.exposure ) * self.snapti1

                gradepixel = 3 * 3
                if self.psumflag:
                    gradepixel = 3 * self.psum_l
                self.plrrate[rnum-1] = pileupfraction( self.rrate[rnum - 1] * gradepixel) 
                self.err_plrrate[rnum-1] = (math.sqrt(tmpimg) / area / self.exposure ) * self.snapti1


                # print("CountRate, CRerr, area, armin, armax", self.rrate[rnum-1], self.err_rrate[rnum-1], area, armin, armax
                tmpimg = 0. ; area = 0. ; armin = armax ; sumpixelarea = 0.

        if self.debug:        
            print("rrate")
            print(self.rrate)
            print(self.err_rrate)

        
    def mkratiotobase(self,baseimage):
            self.ratioimage2d = np.arange(0.0,len(self.image2d)*len(self.image2d),1.0);
            self.ratioimage2d.shape = len(self.image2d),len(self.image2d)

            for x in range(len(baseimage.image2d)):
                for y in range(len(baseimage.image2d)):        
                    if baseimage.image2d[x][y] > 0:                        
                        tmp = float(self.image2d[x][y])/float(baseimage.image2d[x][y])
                        self.ratioimage2d[x][y] = tmp * 100.
                    else:
                        self.ratioimage2d[x][y] = 0.

            self.ratiorrate =  np.zeros(len(self.xradius))
            self.err_ratiorrate =  np.zeros(len(self.xradius))

            self.normedratiorrate =  np.zeros(len(self.xradius))
            self.err_normedratiorrate =  np.zeros(len(self.xradius))

            for k in range(len(self.ratiorrate)):
                if ( baseimage.rrate[k] > 0) and (self.rrate[k] > 0 ) : 
                    self.ratiorrate[k] =  self.rrate[k] / baseimage.rrate[k] * 100.0
                    
                    self.err_ratiorrate[k] =  diverr(self.rrate[k],self.err_rrate[k],baseimage.rrate[k],baseimage.err_rrate[k]) * 100.0
                else:
                    self.ratiorrate[k] = 0.0
                    self.err_ratiorrate[k] = 0.0
                    
                    
            if self.debug: 
                print('ratiorate, err', self.ratiorrate, self.err_ratiorrate)


            meanid = np.where(  ( self.xradius > self.pileupfreer ) & ( self.xradius < self.pileupfreer + 100.0 )  )


#            print(" ")
#            print("MEAN ID: ")
#            print(self.xradius[meanid])
#            print(self.ratiorrate[meanid])
            
            meanval = plab.polyfit(self.xradius[meanid],self.ratiorrate[meanid],0)
            
            if meanval > 0: 
                self.normedratiorrate = self.ratiorrate / meanval 
                self.err_normedratiorrate = self.err_ratiorrate / meanval 
            else:
                self.normedratiorrate = self.ratiorrate
                self.err_normedratiorrate = self.err_ratiorrate


    def plotrprofile(self,figurefilename,plotwindow):

        plt.figure(figsize=(8,10))
 
        ax = plt.subplot(1,1,1)            
        plt.errorbar(self.xradius,self.rrate,xerr=self.err_xradius, yerr=self.err_rrate,fmt='k.',capsize=0, label=self.shortname)
        plt.legend(numpoints=1, frameon=False)

        plt.title('Countrate x snapti vs. r', size='medium')
        plt.xlim(0,self.maxradius)
#        plt.ylim(0.001,10)
        ax.set_yscale('log')
        plt.xlabel('Radius (Pixels)')
        plt.ylabel('Countrate x snapti (cts/pixel/pixels)')
        
        plt.savefig(figurefilename)

        if plotwindow:
            plt.show()


    def plotratiorprofile(self,figurefilename,plotwindow):

        plt.figure(figsize=(8,10))
        ax = plt.subplot(1,1,1)
        
        ax.set_yscale('log')
        
        # y axis
        yFormatter = FormatStrFormatter('%2.1f')            
        ymajorLocator = FixedLocator([x*y for x in [0.01,0.1,1,10,100] for y in np.arange(1,10,1)])
        yminorLocator   = FixedLocator([x*y for x in [0.01,0.1,1,10,100] for y in np.arange(1,10,0.1)])
        
        ax.yaxis.set_major_formatter(yFormatter)
        ax.yaxis.set_major_locator(ymajorLocator)
        ax.yaxis.set_minor_locator(yminorLocator)

        # x axis
        xFormatter = FormatStrFormatter('%2.0f')
        xmajorLocator = FixedLocator(np.arange(0,400,50))
        xminorLocator = FixedLocator(np.arange(0,400,10))  
        ax.xaxis.set_major_formatter(xFormatter)
        ax.xaxis.set_major_locator(xmajorLocator)
        ax.xaxis.set_minor_locator(xminorLocator)
                                               
        plt.errorbar(self.xradius,self.ratiorrate,xerr=self.err_xradius, yerr=self.err_ratiorrate,fmt='k.',capsize=0, label=self.shortname)
        plt.legend(numpoints=1, frameon=False)

        plt.title('ratio vs. r', size='medium')
        plt.xlim(0,self.maxradius)

        plt.xlabel('Radius (Pixels)')
        plt.ylabel('Ratio (%)')
        
        plt.savefig(figurefilename)

        if plotwindow:
            plt.show()

    def plotimage2d(self,figurefilename,plotwindow,xyviewsize):

        plt.imshow(self.logimage2d, interpolation='bilinear', cmap=cm.jet)
        cb = plt.colorbar()
        cb.set_label('LOG10(Counts)')
        plt.title(self.shortname + ' Image (rebin='+str(self.binsize)+')', size='medium')
        plt.xlim( self.cy - xyviewsize, self.cy + xyviewsize)
        plt.ylim( self.cx - xyviewsize, self.cx + xyviewsize)
        plt.ylabel('Radius (Pixels rebined ' + str(self.binsize) + ')')        
        plt.savefig(figurefilename)

        if plotwindow:
            plt.show()

    def plotratioimage2d(self,figurefilename,plotwindow,xyviewsize):

        plt.imshow(self.ratioimage2d, interpolation='bilinear', cmap=cm.jet)
        cb = plt.colorbar()
        cb.set_label('LOG10(Counts)')
        plt.title(self.shortname + ' Image (rebin='+str(self.binsize)+')', size='medium')
        plt.xlim( self.cy - xyviewsize, self.cy + xyviewsize)
        plt.ylim( self.cx - xyviewsize, self.cx + xyviewsize)
        plt.ylabel('Radius (Pixels rebined ' + str(self.binsize) + ')')        
        plt.savefig(figurefilename)

        if plotwindow:
            plt.show()
            
                        
    def __nonzero__(self):
        """ The flag of isexit is returned In case of unexpected errors """
        return self.isexist


    @staticmethod
    def plotresult(base,e3,e7,split,g1,e3split,e7split,e3g1,e7g1,figurefilename):

        font= FontProperties(size='x-small'); # used for legend 
                
        # plot figures 
        plt.figure(figsize=(8,10))
        plt.figtext(0.55, 0.96, "AE PILEUP CHECKUP", color='black', size='large')
        plt.figtext(0.05, 0.96, "Target : " + base.object + " " + base.obsid, color='black', size='small')
        plt.figtext(0.05, 0.94, "Base File :  " + base.eventfilename, color='black', size='small')
        plt.figtext(0.05, 0.92, "Status : " + base.instrume + " " + str(base.clk_mode) + " win:" + base.winopt + " st:" + str('%2.2f' % (base.snapti1)) + " d:" + str('%2.2f' % (base.delay1)) + " " + base.date + " ont:" + str('%2.1f' % (base.ontime * 0.001)) + "ks exp:" + str('%2.1f' % (base.exposure*0.001)) + "ks", color='black', size='small')


#---------------------- plot image --------------------------------------
        # std image
        ax = plt.subplot(3,2,1)

        plt.title(' (1) Image ', size='medium')
        plt.subplots_adjust(wspace = 0.4, hspace = 0.4, top=0.88)
        
        plt.imshow(base.logimage2d, interpolation='bilinear', cmap=cm.jet) 
        cb = plt.colorbar()
        cb.set_label('LOG10(Counts)')
        plt.xlim( base.cy - base.xyviewsize, base.cy + base.xyviewsize)
        plt.ylim( base.cx - base.xyviewsize, base.cx + base.xyviewsize)
        plt.ylabel('Radius (pixel rebined ' + str(base.binsize) + ')')
        plt.xlabel('Radius (pixel rebined ' + str(base.binsize) + ')')
        
        ax.yaxis.set_label_coords(-0.2,0.5)


#---------------------- plot radial brightness --------------------------------------



        ax = plt.subplot(3,2,2)
#        plt.subplots_adjust(wspace=0.4, hspace = 0.4,top=0.88)
        plt.title(' (2) Surface brightness', size='medium')
        # base 
        plt.errorbar(base.xradius,base.rrate,xerr=base.err_xradius, yerr=base.err_rrate,fmt='ko',capsize=0, markersize=2.5, label=base.shortname, markeredgecolor="k", markerfacecolor="k")

        # e3
        plt.errorbar(base.xradius,e3.rrate,xerr=base.err_xradius, yerr=e3.err_rrate,fmt='bo',capsize=0, markersize=2.5, label='e3', markeredgecolor="b", markerfacecolor="b")
        # e7
        plt.errorbar(base.xradius,e7.rrate,xerr=base.err_xradius, yerr=e7.err_rrate,fmt='go',capsize=0, markersize=2.5, label='e7', markeredgecolor="g", markerfacecolor="g")


        # e3split
        plt.errorbar(base.xradius,e3split.rrate,xerr=base.err_xradius, yerr=e3split.err_rrate,fmt='mo',capsize=0, markersize=2.5, label=e3split.shortname, markeredgecolor="m", markerfacecolor="m")
        # e7split
        plt.errorbar(base.xradius,e7split.rrate,xerr=base.err_xradius, yerr=e7split.err_rrate,fmt='ro',capsize=0, markersize=2.5, label=e7split.shortname, markeredgecolor="r", markerfacecolor="r")

        # e3g1
        plt.errorbar(base.xradius,e3g1.rrate,xerr=base.err_xradius, yerr=e3g1.err_rrate,fmt='cs',capsize=0, markersize=2.5, label=e3g1.shortname, markeredgecolor="c", markerfacecolor="c")

#        # e7g1
#        plt.errorbar(base.xradius,e7g1.rrate,xerr=base.err_xradius, yerr=e7g1.err_rrate,fmt='c-',capsize=0, markersize=2.5, label=e7g1.shortname, markeredgecolor="c", markerfacecolor="c")
#

        # plot nxb    
        plt.errorbar(base.xradius,plab.polyval([base.nxb['std']],base.xradius),fmt='k--')
        plt.errorbar(e3.xradius,plab.polyval([e3.nxb['e3']],e3.xradius),fmt='b--')
        plt.errorbar(e7.xradius,plab.polyval([e7.nxb['e7']],e7.xradius),fmt='g--')

        plt.errorbar(e3split.xradius,plab.polyval([split.nxb['e3split']],split.xradius),fmt='m-')
        plt.errorbar(e7split.xradius,plab.polyval([split.nxb['e7split']],split.xradius),fmt='r-')
        plt.errorbar(e3g1.xradius,plab.polyval([g1.nxb['e3g1']],g1.xradius),fmt='c-')
#        plt.errorbar(e7g1.xradius,plab.polyval([g1.nxb['e7g1']],g1.xradius),fmt='c-')

#        plt.legend(loc=0, numpoints=1, prop=font);
#        plt.legend(numpoints=1, frameon=False)        

        plt.ylim(0.1e-10,0.1)
        plt.xlim(0,base.maxradius)
        ax.set_yscale('log')
        
        plt.xlabel('Radius (pixel)')
        plt.ylabel('Counts/frame/pixel')
        ax.yaxis.set_label_coords(-0.2,0.5)

#---------------------- plot split events 3--10 keV --------------------------------------
        ax = plt.subplot(6,2,5)

        plt.title(' (3) Branching ratio', size='medium')

        #e3
        plt.errorbar(base.xradius,e3split.ratiorrate,xerr=base.err_xradius, yerr=e3split.err_ratiorrate,fmt='ms',capsize=0, markersize=2.5, label=e3split.shortname, markeredgecolor="m", markerfacecolor="m")
        plt.legend(numpoints=1, prop=font);
        #====== AXIS
        ax.set_yscale('log')
        
#        tmpmin = e3split.ratiorrate.min()
        tmp_positive_array = e3split.ratiorrate[np.where( e3split.ratiorrate > 0.1 )]
        tmpmin = tmp_positive_array.min()
        ymin = np.max([0.1, 0.9 * tmpmin])

        tmpmax = e3split.ratiorrate.max()
#        tmpmax = np.max([e3split.ratiorrate.max(), e7split.ratiorrate.max() ])
        ymax = np.min([100.0, 1.1 * tmpmax])
        plt.ylim(ymin,ymax)

        plt.xlim(0,base.maxradius)
        # y axis
        yFormatter = FormatStrFormatter('%2.1f')            
        ymajorLocator = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.5)])
        yminorLocator   = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.1)])
        ax.yaxis.set_major_formatter(yFormatter)
        ax.yaxis.set_major_locator(ymajorLocator);ax.yaxis.set_minor_locator(yminorLocator)
    
#        plt.xlabel('Radius (pixel)')
        plt.ylabel('Split Ratio (%)')
        ax.yaxis.set_label_coords(-0.2,0.5)


#---------------------- plot split events 3--10 keV --------------------------------------
        ax = plt.subplot(6,2,7)

        #e7
        plt.errorbar(base.xradius,e7split.ratiorrate,xerr=base.err_xradius, yerr=e7split.err_ratiorrate,fmt='rs',capsize=0, markersize=2.5, label=e7split.shortname, markeredgecolor="r", markerfacecolor="r")
        plt.legend(numpoints=1, prop=font);


        #====== AXIS
        ax.set_yscale('log')

        tmp_positive_array = e7split.ratiorrate[np.where( e7split.ratiorrate > 0.1 )]
        tmpmin = tmp_positive_array.min()        
#        tmpmin = e7split.ratiorrate.min()
        
        ymin = np.max([0.1, 0.9 * tmpmin])
        tmpmax = e7split.ratiorrate.max()
#        tmpmax = np.max([e3split.ratiorrate.max(), e7split.ratiorrate.max() ])
        ymax = np.min([100.0, 1.1 * tmpmax])
        plt.ylim(ymin,ymax)

        plt.xlim(0,base.maxradius)
        # y axis
        yFormatter = FormatStrFormatter('%2.1f')            
        ymajorLocator = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.5)])
        yminorLocator   = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.1)])
        ax.yaxis.set_major_formatter(yFormatter)
        ax.yaxis.set_major_locator(ymajorLocator);ax.yaxis.set_minor_locator(yminorLocator)
    
        plt.xlabel('Radius (pixel)')
        plt.ylabel('Split Ratio (%)')
        ax.yaxis.set_label_coords(-0.2,0.5)



        
#---------------------- plot hardness 3--10 keV --------------------------------------

        ax = plt.subplot( 6, 2, 6)
        plt.title(' (4) Hardness', size='medium')
        
        plt.errorbar(base.xradius,e3.ratiorrate,xerr=base.err_xradius, yerr=e3.err_ratiorrate,fmt='bs',capsize=0, markersize=2.5, label='E > 3 keV', markeredgecolor="b", markerfacecolor="b")

        plt.legend(loc='upper right', numpoints=1, prop=font);
        
        #====== AXIS
        ax.set_yscale('log')

        tmp_positive_array = e3.ratiorrate[np.where( e3.ratiorrate > 0.01 )]
        tmpmin = tmp_positive_array.min()      
        ymin = np.max([0.01,0.8 * tmpmin ])
        ymax = np.min([100.0,1.2 * e3.ratiorrate.max() ])
        plt.ylim(ymin,ymax)
        plt.xlim(0,base.maxradius)

        # y axis
        yFormatter = FormatStrFormatter('%2.1f')            
        ymajorLocator = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.5)])
        yminorLocator   = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.1)])
        ax.yaxis.set_major_formatter(yFormatter)
        ax.yaxis.set_major_locator(ymajorLocator);ax.yaxis.set_minor_locator(yminorLocator)
        
        plt.ylabel('Ratio to ' + base.shortname + '(%)' )
        ax.yaxis.set_label_coords(-0.2,0.5)

#---------------------- plot hardness 7--10 keV --------------------------------------

        ax = plt.subplot(6,2,8)
        
        plt.errorbar(base.xradius,e7.ratiorrate,xerr=base.err_xradius, yerr=e7.err_ratiorrate,fmt='gs',capsize=0, markersize=2.5, label='E > 7 keV', markeredgecolor="g", markerfacecolor="g")
        plt.legend(loc='upper right', numpoints=1, prop=font);


        #====== AXIS
        ax.set_yscale('log')
        
        tmp_positive_array = e7.ratiorrate[np.where( e7.ratiorrate > 0.01 )]
        tmpmin = tmp_positive_array.min()
        
        ymin = np.max([0.01,0.8 * tmpmin ])
        ymax = np.min([100.0,1.2 * e7.ratiorrate.max() ])
        plt.ylim(ymin,ymax)

        plt.xlim(0,base.maxradius)

        # y axis
        yFormatter = FormatStrFormatter('%2.1f')            
        ymajorLocator = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,1.)])
        yminorLocator   = FixedLocator([x*y for x in [0.1,1,10,100] for y in np.arange(1,10,0.5)])
        ax.yaxis.set_major_formatter(yFormatter)
        ax.yaxis.set_major_locator(ymajorLocator);ax.yaxis.set_minor_locator(yminorLocator)

        plt.xlabel('Radius (pixel)')
        plt.ylabel('Ratio to ' + base.shortname + '(%)' )
        ax.yaxis.set_label_coords(-0.2,0.5)

#---------------------- plot pileup fraction --------------------------------------

        ax = plt.subplot(3,2,5)
        r1p = [0.,0.]
        # --------- pileup fraction ---------- #
        if 100.0 * base.plrrate.max() > 1.0:   # pileup fraction is larger than 1 % is used. 
            # reverse array to calcrate spline func.

            rplrrate = base.plrrate[-1::-1]
            rxradius = base.xradius[-1::-1]
            
            yp = None
            g1p = np.array([0.03,0.01])
            r1p = mlab.stineman_interp(g1p,rplrrate,rxradius,yp)
            if (r1p[0] > r1p[1]) or r1p[0] < 0. or  100.0 * base.plrrate.max() < 3.0 : # when pileup fraction < 3%
                r1p[0] = 0.
            ispileup = True
            print("koooooooooo  Pileup is likely to occur. ")
            print('koooooooooo  3 % at ' + str('%3.1f' % r1p[0]) + ' pixel,   1 % at ' + str('%3.1f' % r1p[1]) + ' pixel ( 1 pixel ~ 1 arcsec)')

        else:
            
            ispileup = False
            print("okkkkkkkkkk  Pileup is not likely to occur. okkkkkkkkkk")
        
            
        plt.title('(5) Pileup fraction', size='medium')        
        plt.errorbar(base.xradius,100.0 * base.plrrate,xerr=base.err_xradius, yerr= 100.0 * base.err_plrrate,fmt='ko',capsize=0, markersize=2.5, label=base.shortname, markeredgecolor="k", markerfacecolor="k")

        if ispileup:
            plt.errorbar(base.xradius,plab.polyval([100.*g1p[0]],base.xradius),fmt='r--',linewidth = 1.0, label='3% at ' + str('%3.1f' % r1p[0]))
            plt.errorbar(base.xradius,plab.polyval([100.*g1p[1]],base.xradius),fmt='m--',linewidth = 1.0, label='1% at ' + str('%3.1f' % r1p[1]))
                    

        if ispileup:    
            plt.figtext(0.1, 0.035, 'Pileup fraction is 3 % at ' + str('%3.1f' % r1p[0]) + ' pixel,   1 % at ' + str('%3.1f' % r1p[1]) + ' pixel.' , color='black', backgroundcolor='red')
        else: 
            plt.figtext(0.1, 0.035, 'Pileup fraction is less than 1 % at any radius.', color='black', backgroundcolor='green')


        plt.legend(loc=0, numpoints=1, prop=font);
        plt.xlim(0,base.maxradius)
#        plt.ylim(0.00001,1)
#        ax.set_yscale('log')

        #====== AXIS
        ax.set_yscale('log')

        ymin = np.max([0.000001,0.8 * 100.0 * base.plrrate.min() ])
        plt.ylim(1e-4,100.0)
#        plt.ylim(ymin,100.0)

        plt.xlim(0,base.maxradius)

        plt.xlabel('Radius (pixel)')
        plt.ylabel('Pileup Fraction of ' + base.shortname +  ' (%)')
        ax.yaxis.set_label_coords(-0.2,0.5)


#---------------------- plot g1 event --------------------------------------

        ax = plt.subplot(3,2,6)

        plt.title('(6) Grade1 fraction', size='medium')
        
#        plt.errorbar(base.xradius,g1.ratiorrate,xerr=base.err_xradius, yerr=g1.err_ratiorrate,fmt='cs',capsize=0, markersize=2.5, label=g1.shortname, markeredgecolor="c", markerfacecolor="c")

        plt.errorbar(base.xradius,g1.ratiorrate,xerr=base.err_xradius, yerr=g1.err_ratiorrate,fmt='cs',capsize=0, markersize=2.5, label=g1.shortname, markeredgecolor="c", markerfacecolor="c")

#       plt.errorbar(base.xradius,e7g1.ratiorrate,xerr=base.err_xradius, yerr=e7g1.err_ratiorrate,fmt='gs',capsize=0, markersize=2.5, label=e7g1.shortname, markeredgecolor="g", markerfacecolor="g") 
#        plt.errorbar(base.rrate,g1.rrate,xerr=base.err_rrate, yerr=g1.err_rrate,fmt='cs',capsize=0, markersize=2.5, label=g1.shortname, markeredgecolor="c", markerfacecolor="c")
        plt.legend(loc=0, numpoints=1, prop=font);


        #====== AXIS
#        ax.set_xscale('log')
        ax.set_yscale('log')

#        ymin = np.max([1e-5, 0.5 * g1.ratiorrate.min() ])
#        ymax = np.min([10.,  2.0 * g1.ratiorrate.max() ])
        plt.ylim(1e-2,100)
        plt.xlim(0,base.maxradius)

        plt.ylabel('Ratio of ' + g1.shortname + ' to ' + base.shortname + ' (%)')
        ax.yaxis.set_label_coords(-0.2,0.5)
        plt.xlabel('Radius (pixel)')

        plt.savefig(figurefilename)

        if base.plotwindow:
            plt.show()


        return r1p

######################## for quickplot check ###################################


def dumpdic(obj):

    data = { 'obsid' : obj.obsid,
             'eventfilename' : obj.eventfilename,
             'instrume' : obj.instrume,
             'nxb' : obj.nxb,
             'binsize' : obj.binsize,
             'clk_mode' : obj.clk_mode,
             'winopt' : obj.winopt,
             'snapti1' : obj.snapti1,
             'delay1' : obj.delay1,
             'object' : obj.object,
             'winsiz' : obj.winsiz,
             'winst' : obj.winst,
             'date' : obj.date,
             'ontime' : obj.ontime,
             'tstart' : obj.tstart,
             'tstop' : obj.tstop,
             'exposure' : obj.exposure,
             'xradius' : obj.xradius.tolist(),
             'err_xradius' : obj.err_xradius.tolist(),
             'shortname' : obj.shortname,
             'rrate' : obj.rrate.tolist(),
             'err_rrate' : obj.err_rrate.tolist(),
             'ratiorrate' : obj.ratiorrate.tolist(),
             'err_ratiorrate' : obj.err_ratiorrate.tolist(),
             'normedratiorrate' : obj.normedratiorrate.tolist(),
             'err_normedratiorrate' : obj.err_normedratiorrate.tolist(),
             'plrrate' : obj.plrrate.tolist(),
             'err_plrrate' : obj.err_plrrate.tolist(),
             'maxradius' : obj.maxradius,
             'cx' : obj.cx,
             'cy' : obj.cy,
             'xyviewsize' : obj.xyviewsize,
             'nom_pnt' : obj.nom_pnt
             }
    #             'logimage2d' : obj.logimage2d.tolist(),
    
    return data

def dumpdicall(obj):

    data = dumpdic(obj)
#    print(tmpdata)
    data['logimage2d'] = obj.logimage2d.tolist()
#    print(data)
    return data


def main():
            
    """
    Run process according the following parameters. 
    """
    
    usage = '%prog (folder containing output of xis_extract_gradesortedimage.sh) (xis number; 0-3) [-b 8] [-x 30] [-o Gstd_G1] [-f xis0_result.pdf] [-w TRUE] [-d TRUE] [-u 0.01] [-e FALSE]' 

    version = '%prog ' + __version__


    parser = optparse.OptionParser(usage=usage, version=version)
                                                                                            
    parser.add_option( '-b', '--binsize', action='store', type='float',                     
        help='The xy binsize when input image fits are created.',                           
        metavar='BINSIZE',default=8.)                                                       
    parser.add_option( '-x', '--xyviewsize', action='store', type='float',                  
        help='The size (pixels) when images are plotted.',                                  
        metavar='XYVIEWSIZE', default=30.0)                                                 
    parser.add_option( '-o', '--outputtag',  action='store',  type='string',                
        help='The tag names to distinguish input images ',                           
        metavar='OUTPUTTAG', default='std_e3_e7_split_g1_e3split_e7split_e3g1_e7g1')                                             
    parser.add_option( '-r', '--maxradius',     action='store',  type='float',                   
        help='The maximum radius to be used',                                                     
        metavar='maxradius', default=360)                                                       
    parser.add_option('-f', '--figurefilename', action='store',type='string',               
        help='The name of output figure file name',                                         
        metavar='FIGUREFILENAME', default='result_aepileupestimate.pdf')                    
    parser.add_option('-w', '--plotwindow', action='store_true',               
        help='The flag to switch matplotlib plot GUI on or off', 
        metavar='PLOTWINDOW', default=False)                    
    parser.add_option('-d', '--debug', action='store_true',               
        help='The flag to switch status', 
        metavar='DEBUG', default=False)                    
    parser.add_option('-u', '--upperratio', action='store', type='float',
        help='The creiteria of pileup',
        metavar='UPPERRATIO', default=1)                    
    parser.add_option('-c', '--cskyx_cskyy', action='store', type='string',
        help='The center SKYX and SKYY coordinates of image',
        metavar='CSKYX_CSKYY', default='auto')                    
    parser.add_option('-l', '--linlogthre', action='store', type='float',
        help='The threshold radius of linear and log plot',
        metavar='LINLOGTHRE', default=100.)                    
    parser.add_option('-y', '--yamlfile', action='store', type='string',
                      help='Dump all classes in a yaml file',
                      metavar='YAMLFILE', default='allclasses.yaml')
    parser.add_option('-q', '--quickstart', action='store_true',
                      help='Start analysis from yamls',
                      metavar='QUICKSTART', default=False)
    parser.add_option('-e', '--endregionoutput', action='store_false',
                      help='To end region file output.',
                      metavar='ENDREGIONOUTPUT', default=True)
    parser.add_option('-p', '--placeofregiondir', action='store', type='string',
                      help='The name of the output region directory',
                      metavar='PLACEOFREGIONDIR', default='regions')
    
                                                                            
    options, args = parser.parse_args()                                                     
    #print(args)
    #print(options)

    argc = len(args)

    print("*********************************************")
    print("********** aepileupcheckup.py ***************")
    print("*********************************************")
    print(" Checks pile-up fraction of the XIS data")
    print(" Author : Shinya Yamada (yamada(at)juno.phys.s.u-tokyo.ac.jp)")
    print("")
    print("********** Start analysis of aepileupcheckup.py *************** ")


    outputtag = options.outputtag                               
    binsize   = options.binsize                                            
    xyviewsize    = options.xyviewsize
    figurefilename =  options.figurefilename    
    plotwindow =  options.plotwindow
    debug =  options.debug
    upperratio =  options.upperratio
    cskyx_cskyy = options.cskyx_cskyy        
    linlogthre = options.linlogthre
    maxradius =  options.maxradius
    endregionoutput =  options.endregionoutput
    placeofregiondir =  options.placeofregiondir
    
    Image.linlogthre = linlogthre
    Image.maxradius = maxradius
    Image.debug = debug
    Image.xyviewsize = xyviewsize
    Image.plotwindow = plotwindow
    
    yamlfile = options.yamlfile
    quickstart  = options.quickstart

    
    if not quickstart: 
        if (argc < 2):
            print('***** ERROR *****')
            print('At least 2 arguments must be passed.')
            print('Usage:')
            print("aepileupcheck.py (folder containing output of xis_extract_gradesortedimage.sh) (xis number; 0-3) [options] ")
            quit()
        
            # fitsfile, shotname (used for nxb), binsize, quickstart flag.

        #baseimage  = Image(args[0],outputtag.split('_')[0], binsize, quickstart)
        #e3image    = Image(args[1],outputtag.split('_')[1], binsize, quickstart)
        #e7image    = Image(args[2],outputtag.split('_')[2], binsize, quickstart)
        #splitimage = Image(args[3],outputtag.split('_')[3], binsize, quickstart)
        #g1image    = Image(args[4],outputtag.split('_')[4], binsize, quickstart)
        #e3splitimage = Image(args[5],outputtag.split('_')[5], binsize, quickstart)
        #e7splitimage = Image(args[6],outputtag.split('_')[6], binsize, quickstart)
        #e3g1image = Image(args[7],outputtag.split('_')[7], binsize, quickstart)
        #e7g1image = Image(args[8],outputtag.split('_')[8], binsize, quickstart)

        gradesorted_image_folder=args[0]+"/"
        xisn=int(args[1])
        baseimage  = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec0p5_10p0keVgrstd.img",outputtag.split('_')[0], binsize, quickstart)
        e3image    = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec3p0_10p0keVgrstd.img",outputtag.split('_')[1], binsize, quickstart)
        e7image    = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec7p0_10p0keVgrstd.img",outputtag.split('_')[2], binsize, quickstart)
        splitimage = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec0p5_10p0keVgrstdmul.img",outputtag.split('_')[3], binsize, quickstart)
        g1image    = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec0p5_10p0keVgr1.img",outputtag.split('_')[4], binsize, quickstart)
        e3splitimage = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec3p0_10p0keVgrstdmul.img",outputtag.split('_')[5], binsize, quickstart)
        e7splitimage = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec7p0_10p0keVgrstdmul.img",outputtag.split('_')[6], binsize, quickstart)
        e3g1image = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec3p0_10p0keVgr1.img",outputtag.split('_')[7], binsize, quickstart)
        e7g1image = Image(gradesorted_image_folder+"xi"+str(xisn)+"rp_ig8ec7p0_10p0keVgr1.img",outputtag.split('_')[8], binsize, quickstart)
        
        print("**************** Setting *******************")
        print("           imagefits1 = " + baseimage.eventfilename)
        print("           imagefits2 = " + e3image.eventfilename)
        print("           imagefits3 = " + e7image.eventfilename)
        print("           imagefits4 = " + splitimage.eventfilename)
        print("           imagefits5 = " + g1image.eventfilename)
        print("           imagefits6 = " + e3splitimage.eventfilename)
        print("           imagefits7 = " + e7splitimage.eventfilename)
        print("           imagefits8 = " + e3g1image.eventfilename)
        print("           imagefits9 = " + e7g1image.eventfilename)

        print("           figurefilename   = " + figurefilename)


        # get the center of x, y 
        if options.cskyx_cskyy is not 'auto': 
            print('not auto')
            cx = float(cskyx_cskyy.split('_')[0]) / binsize
            cy = float(cskyx_cskyy.split('_')[1]) / binsize
            print("cx cy", cx, cy)
            Image.cx = cx
            Image.cy = cy
        else:
            baseimage.cxcycalc()
            Image.cx = baseimage.cx
            Image.cy = baseimage.cy
        print("Image.cx, Image.cy", Image.cx, Image.cy)
        

        # create radial profile
        baseimage.mkrprofile('std',baseimage)
        e3image.mkrprofile('e3',baseimage)
        e7image.mkrprofile('e7',baseimage)
        splitimage.mkrprofile('split',baseimage)
        g1image.mkrprofile('g1',baseimage)

        e3splitimage.mkrprofile('e3split',baseimage)
        e7splitimage.mkrprofile('e7split',baseimage)
        e3g1image.mkrprofile('e3g1',baseimage)
        e7g1image.mkrprofile('e7g1',baseimage)
                                        

        # created ratio
        e3image.mkratiotobase(baseimage)
        e7image.mkratiotobase(baseimage)
        splitimage.mkratiotobase(baseimage)
        g1image.mkratiotobase(baseimage)

        e3splitimage.mkratiotobase(e3image)
        e7splitimage.mkratiotobase(e7image)
        e3g1image.mkratiotobase(e3image)
        e7g1image.mkratiotobase(e7image)

                
        if Image.debug:
            # plot images 
            baseimage.plotrprofile(figurefilename,plotwindow)
            baseimage.plotimage2d(figurefilename,plotwindow,xyviewsize)
            e3image.plotratiorprofile(figurefilename,plotwindow)
            e3image.plotratioimage2d(figurefilename,plotwindow,xyviewsize)
            e7image.plotratiorprofile(figurefilename,plotwindow)
            e7image.plotratioimage2d(figurefilename,plotwindow,xyviewsize)
            splitimage.plotratiorprofile(figurefilename,plotwindow)
            splitimage.plotratioimage2d(figurefilename,plotwindow,xyviewsize)
            g1image.plotratiorprofile(figurefilename,plotwindow)
            g1image.plotratioimage2d(figurefilename,plotwindow,xyviewsize)


        yf = open(yamlfile,'w')
        imagediclist = []
        imagediclist.append(dumpdic(baseimage))
        imagediclist.append(dumpdic(e3image))
        imagediclist.append(dumpdic(e7image))
        imagediclist.append(dumpdic(splitimage))
        imagediclist.append(dumpdic(g1image))
        imagediclist.append(dumpdic(e3splitimage))
        imagediclist.append(dumpdic(e7splitimage))
        imagediclist.append(dumpdic(e3g1image))
        imagediclist.append(dumpdic(e7g1image))

        
        yaml.dump_all(imagediclist, yf)
        yf.close()

        r1p = Image.plotresult(baseimage,e3image,e7image,splitimage,g1image,e3splitimage,e7splitimage,e3g1image,e7g1image,figurefilename)

        if endregionoutput:

            print(".... Creating region files .....")

            commands.getoutput('mkdir -p ' + placeofregiondir)

            inst = baseimage.instrume

            outradius = 240.0 # 4 argmin
            regiontype ={}
            regiontype['whole'] = 0.
            regiontype['pl3']= r1p[0]
            regiontype['pl1']= r1p[1]
            regiontype['r30']=30.0
            regiontype['r100']=100.0
            regiontype['r120']=120.0

            history="""# This is made from aepileupcheckup.py. """
            setcolor="""global color=green dashlist=8 3 width=1 font="helvetica 10 normal" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1"""
            setcord="physical"
            
            for ftag, inner in regiontype.iteritems():
                
                outregionfile = open(placeofregiondir + '/' + inst + '_' + ftag + '.reg','w')
                coreregion="annulus(" + str(baseimage.cy * baseimage.binsize) + "," + str(baseimage.cx * baseimage.binsize) + "," + str (inner) + "," + str(outradius) +  ")" # cx, cy refer to (SKYY, SKYX). 
                regionlist = [history,setcolor,setcord,coreregion]
#                print(regionlist)
                outreg="\n".join(regionlist)
                outregionfile.write(outreg)
                outregionfile.close()
                
        
#        yfall = open('all_' + yamlfile,'w')
#        imagediclistall = []
#        imagediclistall.append(dumpdicall(baseimage))
#        imagediclistall.append(dumpdicall(e3image))
#        imagediclistall.append(dumpdicall(e7image))
#        imagediclistall.append(dumpdicall(splitimage))
#        imagediclistall.append(dumpdicall(g1image))
#        yaml.dump_all(imagediclistall, yfall)
#        yfall.close()
#            


        

    else:

        if (argc < 1):
            print('ERROR ***** At least, 1 yamlfile must be input.')
            print('      ***** Usage: %s yamlfile  (options)')
            quit()
            
        inyamlfile = args[0]
        infile = open(inyamlfile, 'r' )
        indata = yaml.load_all(infile)
        baseimage  = indata.next()
        e3image    = indata.next()
        e7image    = indata.next()
        splitimage = indata.next()
        g1image    = indata.next()
        print("**************** Setting *******************")
        print("           imagefits1 = " + baseimage['eventfilename'])
        print("           imagefits2 = " + e3image['eventfilename'])
        print("           imagefits3 = " + e7image['eventfilename'])
        print("           imagefits4 = " + splitimage['eventfilename'])
        print("           imagefits5 = " + g1image['eventfilename'])
        print("           figurefilename   = " + figurefilename)


        cbaseimage  = Image(baseimage,outputtag.split('_')[0], binsize, quickstart)
        ce3image    = Image(e3image,outputtag.split('_')[1], binsize, quickstart)
        ce7image    = Image(e7image,outputtag.split('_')[2], binsize, quickstart)
        csplitimage = Image(splitimage,outputtag.split('_')[3], binsize, quickstart)
        cg1image    = Image(g1image,outputtag.split('_')[4], binsize, quickstart)

        Image.plotresult(cbaseimage,ce3image,ce7image,csplitimage,cg1image,figurefilename)
        

if __name__ == '__main__':
    main()
