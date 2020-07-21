#!/usr/bin/awk -f

BEGIN{oneday=24.0*3600.0;dummy=1;di=1;
    intl=ceil((mjdstart-epoch)*oneday/period);
    tail=ceil((mjdstop-epoch)*oneday/period);
    #printf("%2d %2d\n",intl,tail);
    for(i=intl ; i<=tail ; i+=di){
	iset=(epoch-mjdref)*oneday+period*(i+iph);
	tset=(epoch-mjdref)*oneday+period*(i+tph);
	printf("%17.15e %17.15e\n",iset,tset);
	#printf("%2d %17.15e %17.15e\n",i,iset,tset);
    }
}


function ceil(num) {
    if (int(num) == num) {
        return num;
    } 
    else if (num > 0) {
        return int(num) + 1;
    } 
    else {
        return num;
    }
}


#EOF# 
