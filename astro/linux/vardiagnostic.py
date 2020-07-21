#!/usr/bin/env python

import sys
import getopt
import os
import numpy as np
import pandas as pd

from matplotlib import pyplot as plt
from matplotlib import gridspec
import matplotlib.ticker as ticker

import lmfit as lf
import lmfit.models as lfm

import warnings;warnings.filterwarnings('ignore')
from ROOT import TMath
from ROOT import Math #Math.normal_cdf_c(x,sigma,x0)


###-------------------------------------------------------------------------
class variationdiagnostic:
###-------------------------------------------------------------------------
    ###---------------------------------------------------------------------
    def __init__(self,datafl,asyerr=False,imgflg=False):
    ###---------------------------------------------------------------------
        self.datafl = datafl
        self.flogfl = datafl.replace('.csv','_vardiagnostic.log')
        self.imgflg = imgflg
        self.asyerr = asyerr
        self.colname1 = ['xd','xe','yd','ye']
        self.colname2 = ['xd','xe','yd','ype','yme']

        
    ###---------------------------------------------------------------------
    def read_param(self):
    ###---------------------------------------------------------------------
        print "READING DATA..."
        
        self.df = pd.read_csv(self.datafl,
                              header = 0,
                              index_col = False)
        print self.df
        for name in self.df.columns.values:
            if name not in self.colname1 + self.colname2:
                self.message
                sys.exit(1)

        
    ###---------------------------------------------------------------------
    def message(self):
    ###---------------------------------------------------------------------
        print "The column names of your data must be followings:"
        print "column names = "+str(self.colname1)+" or "+str(self.colname2)

        
    ###---------------------------------------------------------------------
    def reduction(self):
    ###---------------------------------------------------------------------
        self.xd = np.array(self.df['xd'].dropna())
        self.xe = np.array(self.df['xe'].dropna())

        if self.asyerr is True:
            self.df['ayd'] = self.df['yd']+(self.df['ype']
                                                -self.df['yme'])*0.5
            self.df['aye'] = (self.df['ype']+self.df['yme'])*0.5

            self.yd = np.array(self.df['ayd'].dropna())
            self.ye = np.array(self.df['aye'].dropna())            

        else:
            self.yd = np.array(self.df['yd'].dropna())
            self.ye = np.array(self.df['ye'].dropna())            


        self.parval = np.average(self.yd, weights = self.ye)
        self.parmin = np.min(self.yd)
        self.parmax = np.max(self.yd)

        
    ###---------------------------------------------------------------------
    def diagnostic(self):
    ###---------------------------------------------------------------------
        self.read_param()
        self.reduction()

        print 'Fit the input data'

        model = lfm.ConstantModel()
        param = model.make_params()        

        for name in model.param_names:
            param.add(name,vary=True,value=self.parval,
                      min=self.parmin,max=self.parmax)
            
        result = model.fit(x=self.xd,data=self.yd,weights=self.ye**(-1),
                           params=param,method='leastsq')
        chisqr = result.chisqr
        dgfrdm = result.nfree  #d.o.f.
        redchi = result.redchi
        prbrty = TMath.Prob(chisqr,dgfrdm) #p-value
        
        log = open(self.flogfl,'w')
        log.write("--------------------------------------------------------------------\n")
        log.write(result.fit_report())
        #log.write("[[Confidence Intervals]]\n")
        #log.write(result.ci_report())
        log.write("\n")
        log.write("--------------------------------------------------------------------\n")
        log.write(" Chi-squared value / d.o.f. = %.5f / %d\n" %(chisqr,dgfrdm))
        log.write(" Reduced Chi-squared value  = %.5f\n" %(redchi))  
        log.write(" p-value                    = %7.5e\n" %(prbrty))
        log.write("\n")            
        log.close()
        print 'Fitting results were recorded to %s.' %(self.flogfl)
        

###-------------------------------------------------------------------------
class setenv:
###-------------------------------------------------------------------------
    ###---------------------------------------------------------------------
    def __init__(self,argvs):
    ###---------------------------------------------------------------------
        self.cmd = os.path.basename(argvs[0])
        self.par = argvs[1:]

        
    ###---------------------------------------------------------------------
    def usage(self):
    ###---------------------------------------------------------------------
        print 'USAGE:'
        print '  '+self.cmd+' [-u|--usage] [--asyerr] --datafl=<FILE>'
        #[-i|--imgout] 
        sys.exit()
        

    ###---------------------------------------------------------------------
    def setparam(self):
    ###---------------------------------------------------------------------
        try:
            opts, args = getopt.getopt(self.par, "ui",
                                       ['usage','datafl=','imgout',
                                        'asyerr'])
            
        except getopt.GetoptError, err:
            print str(err) # will print something like "option -a not recognized"
            sys.exit()
        
        #print 'opts',opts ##DEBUG
        #print 'args',args ##DEBUG

        imgflg = False
        asyerr = False
        datafl = None

        for o, a in opts:
            if o in ("-u","--usage"):
                self.usage(cmd)
            elif o in ("--datafl"):
                datafl = a
            elif o in ("-i","--imgout"):
                imgflg = True
            elif o in ("--asyerr"):
                asyerr = True
            else:
                assert False, "unhandled option"

        return datafl,asyerr,imgflg


###-------------------------------------------------------------------------
### main
###-------------------------------------------------------------------------
if __name__ == '__main__':
    #argvs = sys.argv  #
    #argc = len(argvs)  #
    
    setenv = setenv(sys.argv)
    datafl,asyerr,imgflg = setenv.setparam()
    
    if datafl is None:
        setenv.usage()
    else:
        diagnostic = variationdiagnostic(datafl,asyerr,imgflg)
        diagnostic.diagnostic()
        sys.exit()
   
