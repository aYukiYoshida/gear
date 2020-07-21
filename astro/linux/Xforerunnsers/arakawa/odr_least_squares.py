#!/usr/bin/env python

import pylab
from matplotlib import rc
import matplotlib.pyplot as plt
import numpy as np
from scipy.odr import *
import sys

title = 'title'
xlabel = 'X'
ylabel = 'Y'
output = 'output.png'

def odr_LS(data,plot=False):
    '''
    data: x xerr y yerr
    method: Orthogonal distance regression(scipy)
    ref)http://docs.scipy.org/doc/scipy/reference/odr.html
    '''
    #############data#################
    d = np.loadtxt(data)
    x = d[:,0]
    xerr = d[:,1]
    y = d[:,2]
    yerr = d[:,3]

    #############fitting#################
    def f(B, x):
        #assume y = ax+b
        return B[0]*x + B[1]
    linear_mdl = Model(f)
    data = RealData(x, y, sx=xerr, sy=yerr)
    initial_val = [3,0]#initital value
    odr = ODR(data, linear_mdl, beta0=initial_val)
    out = odr.run()
    print 'slope = '+str(out.beta[0])+' +- '+str(out.sd_beta[0])
    print 'intercept = '+str(out.beta[1])+' +- '+str(out.sd_beta[1])

    if plot==True:
        rc('text', usetex=True)
        rc('font',**{'family':'sans-serif','sans-serif':['Helvetica'],'size':'20'})
        fig = pylab.figure(figsize=(12,10))
        ax = fig.add_subplot(111)
        plt.setp(plt.gca().get_xticklabels(), fontsize=25, visible=True)
        plt.setp(plt.gca().get_yticklabels(), fontsize=25, visible=True)
        ax.get_xticklabels(20)
        plt.xlabel(xlabel,size=25)
        plt.ylabel(ylabel,size=25)
        plt.title(title,size=25)
        xx = np.arange(0,10,0.5)
        yy = f(out.beta,xx)
        plt.plot(xx,yy,label='best fit line')
        plt.errorbar(x,y,xerr=xerr,yerr=yerr,fmt='bo')
        plt.legend(loc='upper right',numpoints=1)
        #plt.savefig(output)
        plt.show()
    else:
        pass

if __name__=="__main__":
    data = sys.argv[1]
    plt = False
    odr_LS(data,plt)
