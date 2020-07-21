////////////////////////////////////////////////////////////////////////////////
// lcuniform.c
// HXDのlightcurveのTIMEのcolumeがそろっていないのをそろえる
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
//  Redaction HistoryUpdate
////////////////////////////////////////////////////////////////////////////////
// Ver.  | Date       | Author   | 内容
//-------------------------------------------------------------------------------
// 1.0.0 | 2015.06.03 | yyoshida | prototype
//


#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#define num 99999


int main(void){
  int i=0,j=0,k=0,l=0;
  double t1[num]={0.};
  double t2[num]={0.};
  double r1[num]={0.};
  double r2[num]={0.};
  double r1_err[num]={0.};
  double r2_err[num]={0.};
  double fe1[num]={0.};
  double fe2[num]={0.};
  //char lc1_file[128];
  //char lc2_file[128];
  //char out_file[128];

  FILE *fp;

  //printf("enter source file pinud file >\n");
  //scanf("%s %s",src_file,pinud_file);
  //printf("enter output file >\n");
  //scanf("%s",out_file);

  //READ lc1.dat

  if((fp=fopen("line.dat","r"))!=NULL){
    while(
	  fscanf(fp,"%lf %lf %lf %lf",&t1[i],&r1[i],&r1_err[i],&fe1[i]
		 )!=EOF){
      i++;
    }
    fclose(fp);
  }
  else{
    printf("Error!! line.dat is Opened.\n"); 
    exit(1); 
  } 
  
  //READ lc2.dat
  
  if((fp=fopen("base.dat","r"))!=NULL){ 
     while( 
	   fscanf(fp,"%lf %lf %lf %lf",&t2[j],&r2[j],&r2_err[j],&fe2[j] 
		  )!=EOF){ 
       j++; 
     } 
     fclose(fp); 
   } 
   else{ 
     printf(" Error!! base.dat is Opened.\n"); 
     exit(1); 
   } 
  
  
  if((fp=fopen("lineout.dat","w"))!=NULL){
     for(k=0;k<i;k++){ 
       for(l=0;l<j;l++){ 
	 if(t1[k]==t2[l]){ 
	   fprintf(fp,"%.16le %.16le %.16le %.16le\n",t1[k],r1[k],r1_err[k],fe1[k]); 
 	} 
       } 
     } 
     fclose(fp); 
   } 
   else{ 
     printf("File Open Error!\n"); 
     exit(1); 
   } 

  
  /*
    if((fp=fopen("lc2out.dat","w"))!=NULL){ 
    for(k=0;k<j;k++){ 
    for(l=0;l<i;l++){ 
    if(t2[k]==t1[l]){
    fprintf(fp,"%.16le %.16le %.16le\n",t2[k],r2[k],r2_err[k]);
    }
    }
    }
    fclose(fp);
    }
    else{
    printf("File Open Error!\n");
    exit(1);
    }
  */
  
  return 0;
}
