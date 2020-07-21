#!/usr/bin/env python

# ver0.2, 2010/10/26, we set that binsize must be 1. 


""" This is a aeattitudetuned.py aimed at correting the attitude of Suzaku sattelite  

This is a python scripts which enable you to correct attitude of Suzaku sattelite by 
using its own XIS image. This is almost based on aeattcor.sl ( Copyright (c) 2008 Massachusetts Institute of Technology written by Author:  John E. Davis "davis(at)space.mit.edu". ). 

"""

__author__ =  'Shinya Yamada (yamada(at)juno.phys.s.u-tokyo.ac.jp)'
__version__=  '0.2'


import sys
import commands
import os
import pyfits 
import numpy as np
import pickle
import matplotlib.pylab as plt
import matplotlib.mlab as mlab
from kapteyn import maputils
import optparse
import math
import matplotlib.cm as cm
from matplotlib.font_manager import fontManager, FontProperties


debug = True

class Event():
    """ This is Event class of XIS.

    .. function:: init(self.eventfile) 
   
        Read fits events file and set parameters used in this program. 

        :param eventfile: fits event file
    """

    debug = False
    
    def __init__(self,eventfile):

        self.eventfilename = eventfile
        if os.path.isfile(eventfile):            
            self.eventfits = pyfits.open(eventfile)

            self.instrume = self.eventfits[0].header['INSTRUME']
            self.clk_mode = self.eventfits[0].header['CLK_MODE']
            dicwinopt = {0:'Off',1:'1/4',2:'1/8'}
            self.winopt = dicwinopt[self.eventfits[0].header['WINOPT']]
            self.obsid = self.eventfits[0].header['OBS_ID']
            self.object = self.eventfits[0].header['OBJECT']
            self.date = self.eventfits[0].header['DATE-OBS']
            self.ontime = self.eventfits[0].header['ONTIME']
            self.tstart = self.eventfits[0].header['TSTART']
            self.tstop = self.eventfits[0].header['TSTOP']
            tmpdt = self.tstop - self.tstart
            print "-- tstart, tstop, dt", self.tstart, self.tstop, tmpdt
            self.TIME = self.eventfits[1].data.field("TIME")
            self.X = self.eventfits[1].data.field("X")
            self.Y = self.eventfits[1].data.field("Y")
            self.isexist = True
        else:
            self.isexist = False
            
    def __nonzero__(self):
        """ The flag of isexit is returned In case of unexpected errors """
        return self.isexist

    
    def computexy(self,strtimebin):
        """ Compute the time variation of X and Y 
        
        :param strtimebin: time bin size
        :param rtype: nothing
        """

        timebin = float(strtimebin)
        print "Check,  length of X = "  + str(len(self.X))
        print "Check,  length of Y = "  + str(len(self.Y))
        avex=0.
        avey=0.

        timespan = math.floor((( self.tstop - self.tstart ) / timebin)) * timebin 
        zrebinTIME = np.arange(0.5 * timebin, timespan + 0.5 * timespan, timebin )
        zrebinTIMEks = 0.001 * zrebinTIME
        zrebinX = np.zeros(len(zrebinTIME))  
        zrebinY = np.zeros(len(zrebinTIME))  
        zrebinctsperbin = np.zeros(len(zrebinTIME))  
        
        for j, localtime in enumerate(zrebinTIME):
            
            timeindex = np.where( ( (self.TIME - self.tstart) >= (localtime - 0.5 * timebin) ) & ( (self.TIME - self.tstart) < (localtime + 0.5 * timebin) ) )
            # time column of xis does not always monotonically increase. 
            # Thus, numpy.where is used to calc. light curve.
            zrebinX[j] = np.mean(self.X[timeindex])
            zrebinY[j] = np.mean(self.Y[timeindex])
            zrebinctsperbin[j] = len(self.X[timeindex])


        ldcountsthre = 10.

        ldindex = np.where(zrebinctsperbin > 10.0)
        self.rebinTIME   = zrebinTIME[ldindex]
        self.rebinTIMEks = 0.001 * self.rebinTIME
        self.rebinX = zrebinX[ldindex]
        self.rebinY = zrebinY[ldindex]
        self.rebinctsperbin = zrebinctsperbin[ldindex]
        
        self.meanX = np.mean(self.rebinX) 
        self.meanY = np.mean(self.rebinY) 

        print "meanX = ", self.meanX
        print "meanY = ", self.meanY
        if np.mean(self.rebinctsperbin) > 0. : 
            print "Counts STD ratio =", np.mean(self.rebinctsperbin), self.rebinctsperbin.std(), self.rebinctsperbin.std() / np.mean(self.rebinctsperbin) * 100.0 , "%"
        

        plotmeanx = self.meanX * np.ones(len(self.rebinX))
        plotmeany = self.meanY * np.ones(len(self.rebinY))
        
        self.rebindX = plotmeanx - self.rebinX 
        self.rebindY = plotmeany - self.rebinY 



    def createimage(self):

        self.xybinsize = 8
        xypixelmax= int(1536/self.xybinsize)
        self.image = np.arange(xypixelmax * xypixelmax)
        self.image.shape = xypixelmax,xypixelmax
    
        self.logimage = np.arange(float(xypixelmax) * float(xypixelmax))
        self.logimage.shape = xypixelmax,xypixelmax

        for x in range(xypixelmax):
                tmpxindex = np.where( (self.X >= x * self.xybinsize ) & ( self.X < (( x + 1 )* self.xybinsize)))
                tmpy = self.Y[tmpxindex]
                for y in range(xypixelmax):
                    tmpycut = tmpy[np.where( (tmpy >= y * self.xybinsize) & (tmpy < (y + 1) * self.xybinsize ) )]                    
                    self.image[x][y] = len(tmpycut)
                    if len(tmpycut) > 0:
                        self.logimage[x][y] = math.log10(len(tmpycut))
                    else:
                        self.logimage[x][y] = 0. 


    def plotxycounts(self,outputfname,isplotwindow): 
        """ plot X, Y and Counts and save as pdf 
        
        :param self: using self.rebinX, self.rebinY, self.rebinTIME
        :param outputfname: output pdf file name
        :param rtype: nothing
        """

        """ plot X """
        plt.subplot(3,1,1)

        plt.title('X and Y before correction')

        plt.plot(self.rebinTIMEks,self.rebinX,'ro', label = 'X', linewidth = 1.0, markersize=3)     
        plotmeanx = np.mean(self.rebinX) * np.ones(len(self.rebinX))
        plt.plot(self.rebinTIMEks, plotmeanx, 'r--', label = 'mean X', linewidth = 1.0)
        plt.ylabel('Sky (pixel)')
        plt.legend()

        """ plot Y """
        plt.subplot(3,1,2)
        plt.plot(self.rebinTIMEks,self.rebinY,'bo', label = 'Y', linewidth = 1.0, markersize=3) 
        plotmeany = np.mean(self.rebinY) * np.ones(len(self.rebinY))
        plt.plot(self.rebinTIMEks, plotmeany,'b--', label = 'mean Y', linewidth = 1.0)     
        plt.ylabel('Sky (pixel)')
        plt.legend()
        
        """ plot counts """ 
        plt.subplot(3,1,3)
        plt.plot(self.rebinTIMEks,self.rebinctsperbin,'go', label = 'Events', linewidth = 1.0, markersize=2) 
        plt.ylabel('Counts')
        plt.legend()
        
        plt.xlabel('Time (ks)')

        """ output pdf """
        plt.savefig(outputfname)
        if isplotwindow:
            plt.show()
        plt.clf()


    @staticmethod 
    def plotimages(beforeimg,afterimg,outputfname,isplotwindow,xyviewsize):

        font = FontProperties(size='x-small'); # used for legend

        plt.figure(figsize=(8,10))

        plt.figtext(0.375, 0.96, "AE ATTITUDE TUNED", color='black', size='large')
        plt.figtext(0.05, 0.94, "Target : " + beforeimg.object + " " + beforeimg.obsid + " Files : " + beforeimg.eventfilename, color='black', size='small')
        plt.figtext(0.05, 0.92, "Data : " + beforeimg.instrume + " " + str(beforeimg.clk_mode) + " " + str(beforeimg.winopt) + " "  + beforeimg.date, color='black', size='small')


        plt.subplot(5,1,1)

        dxy = 25 
            # plot before image 
        plt.plot(beforeimg.rebinTIMEks,beforeimg.rebinX,'bo', label = 'before', linewidth = 1.0, markersize=2, markeredgecolor="b", markerfacecolor="b" )     
        plt.plot(afterimg.rebinTIMEks,afterimg.rebinX,'ro', label = 'after', linewidth = 1.0, markersize=2, markeredgecolor="r", markerfacecolor="r" )     
        
        plt.ylabel('Sky X (pixel)')
        plt.ylim( afterimg.meanX - dxy, afterimg.meanX + dxy)
        plt.legend(numpoints=1, frameon=False, prop=font)

        plt.subplot(5,1,2)
            # plot before image 
        plt.plot(beforeimg.rebinTIMEks,beforeimg.rebinY,'bo', label = 'before', linewidth = 1.0, markersize=2, markeredgecolor="b", markerfacecolor="b" )       
        plt.plot(afterimg.rebinTIMEks,afterimg.rebinY,'ro', label = 'after', linewidth = 1.0, markersize=2, markeredgecolor="r", markerfacecolor="r" )       
        plt.ylim( afterimg.meanY - dxy, afterimg.meanY + dxy)
        plt.ylabel('Sky Y (pixel)')
        plt.legend(numpoints=1, frameon=False, prop=font)


        plt.subplot(5,1,3)
        """ plot counts """             
        plt.plot(beforeimg.rebinTIMEks,beforeimg.rebinctsperbin,'bo', label = 'before', linewidth = 1.0, markersize=3, markeredgecolor="b", markerfacecolor="b" ) 
        plt.plot(afterimg.rebinTIMEks,afterimg.rebinctsperbin,'ro', label = 'after', linewidth = 1.0, markersize=1.5, markeredgecolor="r", markerfacecolor="r" ) 
        plt.ylabel('Event Number')
        plt.legend(numpoints=1, frameon=False, prop=font)
        plt.xlabel('Time (ks)')


        plt.subplot(3,2,5)
        plt.imshow(beforeimg.logimage, interpolation='nearest', cmap=cm.jet) 
        cb = plt.colorbar()
        plt.title('Before correction', size='medium')
        plt.xlim( beforeimg.meanY/beforeimg.xybinsize - xyviewsize, beforeimg.meanY/beforeimg.xybinsize + xyviewsize)
        plt.ylim( beforeimg.meanX/beforeimg.xybinsize - xyviewsize, beforeimg.meanX/beforeimg.xybinsize + xyviewsize)
        plt.xlabel('Sky X (' + str(beforeimg.xybinsize) + 'bin )')
        plt.ylabel('Sky Y (' + str(beforeimg.xybinsize) + 'bin )')


        plt.subplot(3,2,6)
        plt.imshow(afterimg.logimage, interpolation='nearest', cmap=cm.jet) 
        cb = plt.colorbar()
        cb.set_label('LOG10(Counts)')
        plt.title('After correction', size='medium')
        plt.xlim( afterimg.meanY/afterimg.xybinsize - xyviewsize, afterimg.meanY/afterimg.xybinsize + xyviewsize)
        plt.ylim( afterimg.meanX/afterimg.xybinsize - xyviewsize, afterimg.meanX/afterimg.xybinsize + xyviewsize)
        plt.xlabel('Sky X (' + str(afterimg.xybinsize) + 'bin )')


        """ output pdf """
        plt.savefig(outputfname)
        if isplotwindow:
            plt.show()
        plt.clf()


    
class Image():
    """ This is an Image class of XIS.

    .. function:: init(self.imagefile) 
   
        Read fits image file and set parameters used in this program. 

        :param imagefile: fits event file
    """
    def __init__(self,imagefile):

        if os.path.isfile(imagefile):

            imgf = pyfits.open(imagefile)
            xybinsize = imgf[0].header['IMGBIN']

            if xybinsize == 1:
                print "fine... xybinsize = ", xybinsize 
                self.imagefits = maputils.FITSimage(imagefile)
                self.imageutil = self.imagefits.Annotatedimage()
                self.isexist = True                
            else :
                print "---------------------------------------------------------------------------"
                print "* Please make image fits again."
                print "* You must set the image fits rebinned as xybinsize of 1, not 8 or others."
                print "---------------------------------------------------------------------------"
                self.isexist = False
                quit()
        else:
            self.isexist = False
            
    def __nonzero__(self):
        """ The flag of isexit is returned In case of unexpected errors """
        return self.isexist


class Attitude():
    """ This is Attitue class of XIS.

    .. function:: init(self.attfile) 
   
        Read fits events file and set parameters used in this program. 

        :param attfile: fits event file
    """

    debug = False
    def __init__(self,attfile):

        if os.path.isfile(attfile):            
            self.eventfits = pyfits.open(attfile,mode='readonly')
            self.TIME = self.eventfits[1].data.field("TIME")
            self.EULER = self.eventfits[1].data.field("EULER")

            listra = []
            listdec90 = []

            for j in range(len(self.EULER)):
                if self.debug:
                    if j == 5:
                        print "j = 5" 
                        print self.EULER[j], len(self.EULER[j])
                        print " "
                listra.append(self.EULER[j][0])
                listdec90.append(self.EULER[j][1])

            self.isexist = True

        else:
            self.isexist = False

        self.ra = np.array(listra)
        self.dec90 = np.array(listdec90)
        self.dec = 90. - self.dec90

    def outputnewatt(self,outputfile): 

        for j in range(len(self.EULER)):
            self.EULER[j][0] = self.newra[j] 
            self.EULER[j][1] = self.newdec90[j] 

        self.eventfits.writeto(outputfile,clobber=True)
            
    def __nonzero__(self):
        """ The flag of isexit is returned In case of unexpected errors """
        return self.isexist

    def correctradec(self,event,image):
        """ correct X and Y and return to ra dec.  """

        self.newra = self.ra
        self.newdec = self.dec

        validtimeindex = np.where( (self.TIME > float(event.tstart) ) & ( self.TIME < float(event.tstop)))

        if self.debug:
            print validtimeindex 
            print self.ra[validtimeindex]

        x, y = image.imageutil.topixel( self.ra[validtimeindex], self.dec[validtimeindex])

        localtime = self.TIME[validtimeindex] - float(event.tstart)

        """ correct differences """
        dx = mlab.stineman_interp(localtime, event.rebinTIME, event.rebindX )
        dy = mlab.stineman_interp(localtime, event.rebinTIME, event.rebindY )
        newx = x + dx 
        newy = y + dy
        print "x"
        print newx, x, dx
        print "y"
        print newy, y, dy
        """ after correction """
        self.newra[validtimeindex], self.newdec[validtimeindex] = image.imageutil.toworld(newx, newy) 
        self.newdec90 = 90.0 - self.newdec 

               
def main():
            
    """
    Run process according the following parameters. 
    """

    usage = '%prog inputeventfits imagefits inattfile outattfile [-o attcor] [-t 100] [-x 100] [-f xis0_aeattitudetunde.pdf] [-w TRUE] [-d TRUE] [-c 777_777] [-s TRUE] ' 

    version = '%prog 0.0'

    parser = optparse.OptionParser(usage=usage, version=version)

    parser.add_option( '-o', '--outputtag',  action='store',  type='string',                
        help='The output file name tag. ',                           
        metavar='OUTPUTTAG', default='attcor')  

    parser.add_option( '-t', '--timebinsize', action='store', type='float',                   
        help='The time binsize of light curve',                           
        metavar='TIMEBINSIZE',default=100.)     

    parser.add_option( '-x', '--xyviewsize', action='store', type='float',                  
        help='The size (pixels) when images are plotted.',                                  
        metavar='XYVIEWSIZE', default=30.0)  

    parser.add_option('-f', '--figurefilename', action='store',type='string',               
        help='The name of output figure file name',                                         
        metavar='FIGUREFILENAME', default='result_aepileupestimate.pdf')       

    parser.add_option('-w', '--plotwindow', action='store_true',               
        help='The flag to switch matplotlib plot GUI on or off', 
        metavar='PLOTWINDOW', default=False)    

    parser.add_option('-d', '--debug', action='store_true',               
        help='The flag to switch status', 
        metavar='DEBUG', default=False) 

    parser.add_option('-c', '--cskyx_cskyy', action='store', type='string',
        help='The center SKYX and SKYY coordinates of image',
        metavar='CSKYX_CSKYY', default='auto') 

    parser.add_option('-s', '--secondstep', action='store_false',
        help='Go to second step: created attitude corrected eventfits',
        metavar='SECONDSTEP', default=True) 

    options, args = parser.parse_args()                                                     

    argc = len(args)   
                                                                                            
    print args                                                                              
    print options 
    print "********** Start analysis of aeattitudetuned.py *************** "      

    argc = len(args)
    print argc
    if (argc < 4):                                                                          
        print 'ERROR ***** At least, 4 params must be input.'                        
        print '      ***** Usage: %s inputeventsfits imagefits1 inputattitudefile outputattidudefile (options)'
        quit()
        
    eventfits = args[0]
    imagefits = args[1]
    inattfits = args[2]
    outattfits = args[3]

    outputtag = options.outputtag       
    timebinsize   = str(options.timebinsize)
    xyviewsize    = options.xyviewsize
    plotwindow =  options.plotwindow
    debug =  options.debug
    secondstep =  options.secondstep
    cskyx_cskyy = options.cskyx_cskyy
    figurefilename = options.figurefilename
    
    Event.debug = debug 
    Attitude.debug = debug 

    print "**************** Setting *******************"
    print "           eventfits = " + eventfits 
    print "           imagefits = " + imagefits 
    print "           inattfits = " +  inattfits 
    print "          outattfits = " + outattfits 
    print "       timebin (sec) = " + timebinsize
    print "  figurefilename   = " + figurefilename

               
    inevent = Event(eventfits)            
    if not inevent:
        print "ERROR: " + eventfile + " does not exist. in " + os.getcwd()
        quit()
        
    inevent.computexy(timebinsize)     

    print "secondstep"
    print secondstep
    if not secondstep:
        inevent.plotxycounts(figurefilename,plotwindow)
        quit()

        
    image = Image(imagefits)
    if not image:
        print "ERROR: " + imagefits + " does not exist. in " + os.getcwd()
        quit()
 
    inatt = Attitude(inattfits)
    if not inatt: 
        print "ERROR: " + inattfits + " does not exist. in " + os.getcwd()
        quit()

    print "******** correct radec start "
    inatt.correctradec(inevent,image)
    print "******** correct plotatt start "
    inatt.outputnewatt(outattfits)

    outputeventfits = outputtag + '_' + eventfits
   
    if secondstep: 

        print commands.getoutput('xiscoord '+'infile=' + eventfits + " outfile=" + outputeventfits + " attitude=" + outattfits + ' pointing=KEY')
        

        outevent = Event(outputeventfits)            
        if not outevent:
            print "ERROR: " + outputeventfits + " does not exist. in " + os.getcwd()
            quit()


        outevent.computexy(timebinsize)     

        inevent.createimage()                
        outevent.createimage()                
        Event.plotimages(inevent, outevent, figurefilename, plotwindow, xyviewsize)
        
        "Finish."


if __name__ == '__main__':
    main()

