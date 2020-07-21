#!/usr/bin/env python

#ref: https://github.com/benlawson/course-2016-spr-proj-two/blob/master/balawson/scic_stat_tests.py
import sys
import getopt
import os
import math

#import warnings;warnings.filterwarnings('ignore')


###---------------------------------------------------------------------------
class stat(object):
###---------------------------------------------------------------------------
    def __init__(self):
        self.EPS = sys.float_info[8];print self.EPS
        self.FPMIN = sys.float_info[3]/self.EPS
        self.SWITCH = 3000


    ###-----------------------------------------------------------------------
    def gammln(self,xx):
    ###-----------------------------------------------------------------------
        """ 
        returns the natuaral logarithm of the gamma function at xx
        Uses: the factorial of xx-1 can be computed by doing
        math.exp( gammln( xx ) ) about eqaul to math.factorial(xx-1)
        ( This is a more efficeint computation. )
        """
        cof = [ 57.1562356658629235,-59.5979603554754912,
                14.1360979747417471,-0.491913816097620199,
                0.339946499848118887e-4, 0.465236289270485756e-4,
                -0.983744753048795646e-4,0.158088703224912494e-3,
                -0.210264441724104883e-3,0.217439618115212643e-3,
                -0.164318106536763890e-3, 0.844182239838527433e-4,
                -0.261908384015814087e-4,0.368991826595316234e-5 ]
        if( xx <= 0 ):
            raise Exception("bad arg in gammln")
        y=x=xx
        tmp = x+5.24218750000000000
        tmp = (x+0.5)*math.log(tmp)-tmp        
        ser = 0.999999999999997092
        for j in cof:
            y+=1
            ser += j/y

        return tmp+math.log(2.5066282746310005*ser/x)


    ###-----------------------------------------------------------------------
    def betai(self,a,b,x):
    ###-----------------------------------------------------------------------
        #Return incomplete beta funciton I_x(a,b) for a,b>0, and 0<x<1.

        if(a<=0.0 or b<=0.0): raise Exception("Bad a or b in routine betai")
        if(x<0.0 or x > 1.0): raise Exception("Bad x in rountine betai")
        if(x == 0.0 or x == 1.0): return x
        if(a > self.SWITCH and b > self.SWITCH): return self.betaiapprox(a,b,x)
        bt=math.exp(self.gammln(a+b)-self.gammln(a)-self.gammln(b)+a*math.log(x)+b*math.log(1.0-x))
        if(x<(a+1.0)/(a+b+2.0)): return bt*self.betacf(a,b,x)/a
        else: return 1.0-bt*self.betacf(b,a,1.0-x)/b


    ###-----------------------------------------------------------------------
    def betacf(self,a,b,x):
    ###-----------------------------------------------------------------------
        """
        Evaluates continued fraction for incomplete beta funciton by modified Lentz's
        method. User should not call directly.
        """
        qab=a+b
        qap=a+1.0
        qam=a-1.0
        c=1.0
        d=1.0-qab*x/qap
        if( abs(d) < self.FPMIN): d=self.FPMIN
        d=1.0/d
        h=d
        for m in range(1,10000):
            m2=2*m
            aa=m*(b-m)*x/((qam+m2)*(a+m2))
            d=1.0+aa*d
            if(abs(d)<self.FPMIN): d=self.FPMIN
            c=1.0+aa/c
            if(abs(c)<self.FPMIN): c=self.FPMIN
            d=1.0/d
            h *= d*c
            aa = -(a+m)*(qab+m)*x/((a+m2)*(qap+m2))
            d=1.0+aa*d
            if(abs(d)<self.FPMIN): d=self.FPMIN
            c=1.0+aa/c
            if(abs(c)<self.FPMIN): c=self.FPMIN
            d=1.0/d
            dl = d*c
            h *= dl
            if(abs(dl-1.0)<=self.EPS): break
        return h
    
                
    ###-----------------------------------------------------------------------
    def betaiapprox(self,a,b,x):
    ###-----------------------------------------------------------------------
        #Incomplete beta by quadrature. Reutrns I_x(a,b). User should not call directly.
        a1=a-1.0
        b1=b-1.0
        mu=a/(a+b)
        lnmu=math.log(mu)
        lnmuc=math.log(1.0-mu)
        t = math.sqrt(a*b/( ((a+b)**2)*(a+b+1.0)))
        if(x> a/(a+b)):
            if(x>=1.0): return 1.0
            xu = min(1.0, max(mu+10.0*t, x+5.0*t))
        else:
            if(x<=0.0): return 0.0
            xu = max(0.0, min(mu-10.0*t, x-5.0*t))
        sm = 0.0
        for j in range(0,18):
            t = x + (xu-x)*self.y[j]
            sm += w[j]*math.exp(a1*(log(t)-lnmu)+b1*(log(1-t)-lnmuc))
        ans = sum*(xu-x)*math.exp(a1*lnmu-self.gammln(a)+b1*lnmuc-self.gammln(b)+self.gammln(a+b))
        if(ans>0.0): return 1.0-ans
        else: return -ans
        

###---------------------------------------------------------------------------
class press_ftest(stat):
###---------------------------------------------------------------------------
    ###-----------------------------------------------------------------------
    def __init__(self,chi1,chi2,dof1,dof2):
    ###-----------------------------------------------------------------------
        self.chi1 = float(chi1)
        self.chi2 = float(chi2)
        self.dof1 = float(dof1)
        self.dof2 = float(dof2)
        self.stat = super(press_ftest,self)
        self.stat.__init__()

        
    ###-----------------------------------------------------------------------
    def calc_prob(self):
    ###-----------------------------------------------------------------------
        var1 = self.chi1/self.dof1
        var2 = self.chi2/self.dof2

        if self.chi1 > self.chi2:
            f = var1 / var2
            df1 = self.dof1-1
            df2 = self.dof2-1
        else:
            f = var2 / var1
            df1 = self.dof2-1
            df2 = self.dof1-1

        prob = 2.0*self.stat.betai(0.5*df2,0.5*df1,df2/(df2+df1*f));
        if prob > 1.0:
            prob = 2.0 - prob

        self.fval = f
        self.prob = prob*0.5
        

    ###------------------------------------------------------------
    def show_message(self):
    ###------------------------------------------------------------
        print 'chi1(dof1) = %g(%i)' %(self.chi1,self.dof1)
        print 'chi2(dof2) = %g(%i)' %(self.chi2,self.dof2)
        print 'F statistical value = %g'%(self.fval)
        print 'The probability of chance improvement of the chi-square = %e' %(self.prob)



###---------------------------------------------------------------------------
class setenv:
###---------------------------------------------------------------------------
    ###-----------------------------------------------------------------------
    def __init__(self,arg):
    ###-----------------------------------------------------------------------
        self.cmd = os.path.basename(arg[0])
        self.par = arg[1:]
        self.ref = 'Press, W. H. et al. 2007, F-Test for Significantly Different Variances (14.2.2), Numerical Recipes: The Art of Scientific Computing (3rd ed.; Cambridge: Cambridge Univ. Press)'

        
    ###-----------------------------------------------------------------------
    def title(self):
    ###-----------------------------------------------------------------------
        print '%s -- F-test routine' %(self.cmd)
        print 'This routine is refered to',self.ref
        print ''

        
    ###-----------------------------------------------------------------------
    def usage(self):
    ###-----------------------------------------------------------------------
        print 'USAGE:'
        print '  '+self.cmd+' [-u|--usage] --c1=<CHI1> --c2=<CHI2> --d1=<dof1> --d2=<dof2>'
        sys.exit()
    

    ###-----------------------------------------------------------------------
    def param(self):
    ###-----------------------------------------------------------------------
        try:
            opts, args = getopt.getopt(self.par, "uit",
                                       ['usage','show-title',
                                        'd1=','d2=','c1=','c2='])
        except getopt.GetoptError, err:
            print str(err) # will print something like "option -a not recognized"
            sys.exit()
        
        #print 'opts',opts ##DEBUG
        #print 'args',args ##DEBUG

        chi1 = None
        chi2 = None
        dof1 = None
        dof2 = None                        
        tflg = False
        
        for o, a in opts:
            if o in ("-u","--usage"):
                self.title()
                self.usage()

            elif o in ('-t',"--show-title"):
                tflg = True

            elif o in ("--c1"):
                chi1 = a

            elif o in ("--c2"):
                chi2 = a

            elif o in ("--d1"):
                dof1 = a

            elif o in ("--d2"):
                dof2 = a

            else:
                assert False, "unhandled option"

        return chi1,chi2,dof1,dof2,tflg


###---------------------------------------------------------------------------
### main
###---------------------------------------------------------------------------
if __name__ == '__main__':
    #argvs = sys.argv  #
    #argc = len(argvs)  #
    
    setenv = setenv(sys.argv)
    chi1,chi2,dof1,dof2,tflg = setenv.param()

    if tflg is True: setenv.title()    
    
    if chi1 is None or chi2 is None or dof1 is None or dof2 is None:
        setenv.usage()
    else:
        ftest = press_ftest(chi1,chi2,dof1,dof2)    
        ftest.calc_prob()
        ftest.show_message()        
        sys.exit()
   


#EOF#
