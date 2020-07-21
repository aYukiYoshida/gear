#!/usr/bin/env python

import sys
import getopt
import os
import numpy as np
import pandas as pd
import subprocess as subproc

from matplotlib import pyplot as plt
from matplotlib import gridspec
import matplotlib.ticker as ticker

from astropy.io import fits as pyfits

import warnings;warnings.filterwarnings('ignore')


###-----------------------------------------------------------------------------
class bpsearch:
###-----------------------------------------------------------------------------
    ###-------------------------------------------------------------------------
    def __init__(self,lcfits,numbin,srstep,imgflg):
    ###-------------------------------------------------------------------------
        self.lcfits = lcfits
        self.numbin = numbin # Number of Periods to Search
        self.srstep = srstep
        self.imgflg = imgflg

        
    ###-------------------------------------------------------------------------
    def run_efsearch(self,period,srstep,esfits='tmpbpsearch.fes'):
    ###-------------------------------------------------------------------------
        DEVNULL = open(os.devnull,'w')
        subproc.call(['efsearch', self.lcfits, 'window="-"',
                      'sepoch=INDEF','dper='+str(period),
                      'nbint=INDEF','nphase='+str(self.numbin),
                      'dres='+str(srstep),'nper=INDEF',
                      'outfile='+esfits,'plot=no' ],
                     stdout=DEVNULL,stderr=subproc.STDOUT)
        DEVNULL.close()
        return esfits
    
        
    ###-------------------------------------------------------------------------
    def read_fits(self,fits,ext=1):
    ###-------------------------------------------------------------------------
        hdulst = pyfits.open(fits)
        dat = hdulst[ext].data
        hdr = hdulst[ext].header
        hdulst.close()
        return dat,hdr

    
    ###-------------------------------------------------------------------------
    def set_period_search_step(self):
    ###-------------------------------------------------------------------------
        if self.srstep is None:
            lcdat,lchdr = self.read_fits(self.lcfits,1)
            timedel = lchdr['TIMEDEL']
            telapse = lchdr['TELAPSE']
            self.srstep = timedel/telapse
        mindigit = int(np.log10(self.srstep))
        digitary = np.logspace(-1,mindigit,abs(mindigit))
        return digitary


    ###-------------------------------------------------------------------------
    def search_best_period(self,period):
    ###-------------------------------------------------------------------------
        stepary = self.set_period_search_step()

        for step in stepary:
            esfits = self.run_efsearch(period,step)
            esdat,eshdr = self.read_fits(esfits,1)
            fesdf = pd.DataFrame({'PERIOD':esdat['PERIOD'],
                                  'CHISQRD':esdat['CHISQRD1'],
                                  'ERROR':esdat['ERROR1']})
            maxchi = fesdf['CHISQRD'].max()
            period = fesdf['PERIOD'][fesdf['CHISQRD'].idxmax()]
        
        lcdat,lchdr = self.read_fits(self.lcfits,1)
        telapse = lchdr['TELAPSE']
        self.pererr = self.estimate_period_error(period,telapse,maxchi)
        self.bstper = period

        return esfits
        
        
    ###-------------------------------------------------------------------------
    def set_best_period(self,ip_esfits,op_esfits):
    ###-------------------------------------------------------------------------
        esdat,eshdr = self.read_fits(ip_esfits,1)
        eshdr['PERIOD'] = (self.bstper,'Best period (s)')
        eshdr['PERERR'] = (self.pererr,'Error of best period (s)')
        pyfits.writeto(op_esfits,esdat,eshdr,overwrite=True)
        if os.path.isfile(op_esfits) is True:
            print op_esfits,'was generated.'
            cmd = ['rm', '-f', ip_esfits ]; subproc.call(cmd)
            

    ###-------------------------------------------------------------------------
    def estimate_period_error(self,period,telapse,chisq):
    ###-------------------------------------------------------------------------
        err = 0.5*0.71*period/telapse*(chisq/(self.numbin-1)-1)**(-0.63)
        return err
    
    
    ###-------------------------------------------------------------------------
    def plot_periodogram(self,dat,hdr):
    ###-------------------------------------------------------------------------
        ###---------------------------------------------------------------------
        ### visual setting
        ###---------------------------------------------------------------------
        fsize = 25.0    # font size 
        lafsize = 20.0  # font size for label
        lgfsize = 20.0  # font size for legend
        tkfsize = 25.0  # font size for ticks
        valign = 'center'   # vertival alignment
        halign = 'center'   # horizontal alignment
        lstyle = '-'
        lwidth = 3.0   # line width
        symbol = '.'   # marker
        msize = 3      # mark size
        mkcol = 'r'    # mark color
        fmt = ','   # format for plot with errors
        
        plt.rcParams['font.family'] = 'Times New Roman'
        plt.rcParams['mathtext.fontset'] = 'cm'
        plt.rcParams['mathtext.rm'] = 'serif'
        plt.rcParams['axes.linewidth'] = lwidth
        plt.rcParams['grid.linestyle'] = 'solid'
        plt.rcParams['grid.linewidth'] = 1.0
        plt.rcParams['grid.alpha'] = 0.2
        plt.rcParams['xtick.major.size'] = 8
        plt.rcParams['xtick.minor.size'] = 5
        plt.rcParams['xtick.major.width'] = lwidth
        plt.rcParams['xtick.minor.width'] = lwidth
        plt.rcParams['xtick.major.pad'] = 5
        plt.rcParams['ytick.major.size'] = 8
        plt.rcParams['xtick.top'] = True
        plt.rcParams['ytick.minor.size'] = 5
        plt.rcParams['ytick.major.width'] = lwidth
        plt.rcParams['ytick.minor.width'] = lwidth
        plt.rcParams['ytick.major.pad'] = 3.5
        plt.rcParams['xtick.direction'] = 'in'
        plt.rcParams['ytick.direction'] = 'in'
        plt.rcParams['xtick.labelsize'] = tkfsize
        plt.rcParams['ytick.labelsize'] = tkfsize
        plt.rcParams['ytick.right'] = True

        
        ###---------------------------------------------------------------------
        ### environment of plotting setting
        ###---------------------------------------------------------------------
        print "PLOTTING PERIODOGRAM..."
        fig = plt.figure(figsize=(10,6))
        gs = gridspec.GridSpec(1,1)
        gs.update(left=0.15,right=0.95,bottom=0.15,top=0.90,
                  wspace=0.02,hspace=0.02)
        ax = fig.add_subplot(gs[0,0])
        

        ###---------------------------------------------------------------------
        ### Main plotting
        ###---------------------------------------------------------------------
        ax.plot(dat['PERIOD'],dat['CHISQRD1'], 
                marker=symbol,ms=msize,drawstyle='steps-mid',
                color=mkcol,ls=lstyle,lw=lwidth)

        ax.set_title(hdr['OBJECT'],fontsize=fsize)        
        ax.xaxis.set_major_locator(ticker.MultipleLocator(2.0))
        ax.xaxis.set_minor_locator(ticker.MultipleLocator(0.5))        
        ax.xaxis.set_major_formatter(ticker.FormatStrFormatter('%d'))
        ax.yaxis.set_major_locator(ticker.AutoLocator())
        ax.yaxis.set_minor_locator(ticker.AutoMinorLocator())
        ax.get_yaxis().get_major_formatter().set_useOffset(False)
        ax.set_xlabel('test period (s)',fontsize=fsize)
        ax.set_ylabel(r'$\chi^{2}$',fontsize=fsize)        
        ax.text(0.98, 0.96, r'$P_{\rm best}$=%.5f$\pm$%.5f s'%(hdr['PERIOD'],
                                                               hdr['PERERR']),
                transform=ax.transAxes,
                fontsize=lafsize, va='top', ha='right',
                bbox = dict(boxstyle='square', alpha=0.0, 
                            edgecolor='none', pad=0.01))
        
        
        ###---------------------------------------------------------------------
        ### save figure
        ###---------------------------------------------------------------------
        if self.imgflg is True:
            fltype='pdf'
            outimg = self.lcfits.replace('.lc','_fes.'+fltype)
            fig.savefig(outimg,format=fltype,dpi=150, 
                        transparent=True,bbox_inches='tight')
            print(outimg+' is generated')
            plt.close(fig)
            
        else:
            plt.pause(1.0)
            plt.draw()
            plt.show()

            
###-----------------------------------------------------------------------------
class setenv:
###-----------------------------------------------------------------------------
    ###-------------------------------------------------------------------------
    def __init__(self,args):
    ###-------------------------------------------------------------------------
        self.cmd = os.path.basename(args[0])
        self.par = args[1:]
        
        
    ###-------------------------------------------------------------------------
    def usage(self):
    ###-------------------------------------------------------------------------
        print 'Searching period with efsearch'
        print '  USAGE:'
        print '    '+self.cmd+' [OPTION] <LCFITS> <PERIOD> [NUMBIN] [SRSTEP] [ESFITS]'
        print '  EXAMPLE:'
        print '    LCFITS           lightcurve FITS file'
        print '    PERIOD           initial value of period'
        print '    NUMBIN           number of bin in the folded light (default=256)'
        print '    SRSTEP           period step to search (assign minimum value; <0.1)'
        print '    ESFITS           output fes file'
        print '  OPTION:'
        print '    -u --usage       show this help message'
        print '    -i --imgout      generate image file of periodogram'
        sys.exit()
    

    ###-------------------------------------------------------------------------
    def setparam(self):
    ###-------------------------------------------------------------------------
        try:
            opts, args = getopt.getopt(self.par, 'uih',
                                       ['usage','help','imgout',
                                        'lcfits=','period=','srstep=',
                                        'numbin=','esfits='])
            
        except getopt.GetoptError, err:
            print str(err) # will print something like "option -a not recognized"
            sys.exit()
            
        #print 'opts',opts ##DEBUG
        #print 'args',args ##DEBUG

        lcfits = None
        period = None
        numbin = 256
        esfits = None
        srstep = None
        imgflg = False 
        
        for o, a in opts:
            if o in ('-u','--usage','-h','--help'):
                self.usage()
            elif o in ('--lcfits'):
                lcfits = str(a)
            elif o in ('--period'):
                period = float(a)
            elif o in ('--esfits'):
                esfits = str(a)
            elif o in ('--numbin'):
                numbin = float(a)
            elif o in ('--srstep'):
                srstep = float(a)
            elif o in ('-i','--imgout'):
                imgflg = True
            else:
                assert False, "unhandled option"

        return lcfits,period,numbin,esfits,srstep,imgflg


###------------------------------------------------------------------------------ 
if __name__ == '__main__':
###------------------------------------------------------------------------------ 
    #argvs = sys.argv   #
    #argc = len(argvs)  #

    setenv = setenv(sys.argv)
    lcfits,period,numbin,esfits,srstep,imgflg = setenv.setparam()

    if lcfits is None or period is None :
        setenv.usage()
    else:
        if esfits is None:
            esfits = lcfits.replace('.lc','.fes')
            
        psearch = bpsearch(lcfits,numbin,srstep,imgflg)
        tmpesfits = psearch.search_best_period(period)
        psearch.set_best_period(tmpesfits,esfits)
        ip_pltesfits = psearch.run_efsearch(period,0.1)
        op_pltesfits = esfits.replace('.fes','_plt.fes')
        psearch.set_best_period(ip_pltesfits,op_pltesfits)
        esdat,eshdr = psearch.read_fits(op_pltesfits,1)
        psearch.plot_periodogram(esdat,eshdr)

    sys.exit()

#EOF#
