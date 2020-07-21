////////////////////////////////////////////////////////////////////////////////
// hxdlcoffset.c
// HXD lightcurve‚ÌTIME‚ª0‚©‚çŠJŽn‚É‚·‚é
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
//  Redaction HistoryUpdate
////////////////////////////////////////////////////////////////////////////////
// Ver.  | Date       | Author   | 
//-------------------------------------------------------------------------------
// 1.0.0 | 2015.06.0 | yyoshida | prototype
//


#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#define num 99999


int main(void){
  int i=0,j=0;
  int row[num]={0};
  double t[num]={0.};
  double r[num]={0.};
  double r_err[num]={0.};
  double fe[num]={0.};
  double t_min=0.0;
  FILE *fp;



  if((fp=fopen("lc.dat","r"))!=NULL){
    while(
	  fscanf(fp,"%d %lf %lf %lf %lf",&row[i],&t[i],&r[i],&r_err[i],&fe[i]
		 )!=EOF){
      i++;
    }
    fclose(fp);
  }

  else{
    printf("Error!! lc.dat is Opened.\n"); 
    exit(1); 
  } 
  
  t_min=t[0]; //printf("%d\n",t_min);

  if((fp=fopen("lcoffset.dat","w"))!=NULL){
      for(j=0;j<i;j++){ 
	//printf("p=%d %.8le %.8le %.8le %.8le\n",t[j],r[j],r_err[j],fe[j]); 
	fprintf(fp,"%.16le %.16le %.16le %.16le\n",t[j]-t_min,r[j],r_err[j],fe[j]);
      }
      fclose(fp);   
  } 
  
  else{ 
    printf("File Open Error!\n"); 
    exit(1); 
  }
  
  return 0;
}
