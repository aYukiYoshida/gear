#!/usr/bin/awk -f

BEGIN{oneday=24.0*3600.0;dummy=1;di=1;
    intl=ceil((mjdstart-epoch)*oneday/period);
    tail=ceil((mjdstop-epoch)*oneday/period);
    #printf("%2d %2d\n",intl,tail);
    for(i=intl ; i<=tail ; i+=di){
	iset_a=(epoch-mjdref)*oneday+period*(i+iph_a);
	tset_a=(epoch-mjdref)*oneday+period*(i+tph_a);
	iset_b=(epoch-mjdref)*oneday+period*(i+iph_b);
	tset_b=(epoch-mjdref)*oneday+period*(i+tph_b);
	printf("%17.15e %17.15e\n",iset_a,tset_a);
	printf("%17.15e %17.15e\n",iset_b,tset_b);
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
