#!/usr/bin/awk -f

BEGIN{
    PI=atan2(0,-1);num=100;
    n=2*PI/P;const=((1-e^2)^1.5)/n;
    sphista=n*(obsta/86400+mjdz-orbz-1); #unit of radian
    sphistp=n*(obstp/86400+mjdz-orbz+1); #unit of radian
    df=(sphistp-sphista)/num;
    dp=sphistp/1.0e+8;
    #printf "!PI     %17.15f\n",PI;
    #printf "!orbit  %17.15f\n",P;
    #printf "!ecc    %17.15f\n",e;
    #printf "!mjdz   %17.15f\n",mjdz;
    #printf "!orbz   %17.15f\n",orbz;
    #printf "!tstart %17.15e\n",obsta;
    #printf "!tstop  %17.15e\n",obstp;
    #printf "!start  %17.15f\n",sphista;    
    #printf "!stop   %17.15f\n",sphistp;
    #printf "!df    %17.15f\n",df;
    #printf "!dp    %17.15e\n",dp;
    
    for(f=sphista;f<=sphistp;f+=df){
    #f=2*PI; ## for DEBUG
	t=0.0;
	for(p=0;p<=f;p+=dp){
	    eq=(1+e*cos(p))^(-2);
	    deq=(1+e*cos(p+dp))^(-2);
	    t=t+(eq+deq)*dp*0.5; 
	}
	printf "%17.15f %17.15f\n",f,t*const 
        ## t*const=day from orbzero
	## f : in unit of radian
    }
}

