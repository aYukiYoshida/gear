////////////////////////////////////////////////////////////////////////////////
// hxdpselczfill.c
// HXD-PSE lightcurve‚ÌRATE‚ª0‚Ìbin‚ð–„‚ß‚é
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
//  Redaction HistoryUpdate
////////////////////////////////////////////////////////////////////////////////
// Ver.  | Date       | Author   | 
//-------------------------------------------------------------------------------
// 1.0.0 | 2015.06.03 | yyoshida | prototype
//


#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#define num 99999


int main(void){
  int i=0,j=0,k=0,l=0,m=0,n=0,p=0,q=0;
  int org=0;
  int row[num]={0};
  int nzrow[num]={0};
  int row_min=0,row_max=0;
  int start=0,step=0,width;
  double t[num]={0.};
  double nzt[num]={0.};
  double r[num]={0.};
  double nzr[num]={0.};
  double r_err[num]={0.};
  double nzr_err[num]={0.};
  double fe[num]={0.};
  double nzfe[num]={0.};
  double true_r=0.0,true_r_err=0.0;
  FILE *fp;



  if((fp=fopen("pselc.dat","r"))!=NULL){
    while(
	  fscanf(fp,"%d %lf %lf %lf %lf",&row[i],&t[i],&r[i],&r_err[i],&fe[i]
		 )!=EOF){
      i++;
    }
    fclose(fp);
  }

  else{
    printf("Error!! pselc.dat is Opened.\n"); 
    exit(1); 
  } 
  
  row_min=row[0];
  row_max=row[i-1]; //printf("%d\n",row_max);
  for(j=0;j<i;j++){
    if(r[j] > 0.0){
      nzrow[k]=row[j];
      k++;
    }
  }
  //printf("row_min=%d nzrow[0]=%d\n",row_min,nzrow[0]); //DEBUG
  
  for(l=0;l<i;l++){
    if(r[l] > 0.0){
      for(m=1;m<i;m++){
	if(r[l+m]!=0.0){
	  step=m;
	  break;
	}
      }
      start=l;
      true_r=r[start]/step; //printf("true_r=%.8e\n",true_r);
      true_r_err=r_err[start]/step; //printf("true_r_err=%.8e\n",true_r_err);
      
      for(n=start;n<=start+step;n++){
      	nzr[n]=true_r; // printf("nzr[%d] %.8e\n",n,nzr[n]);
	nzr_err[n]=true_r_err; //printf("nzr_err[%d] %.8e\n",n,nzr_err[n]);
      }
    }
    //printf("q=%d %.8e %.8le %.8le %.8le\n",l,t[l],r[l],nzr[l],nzr_err[l]); 
  }
  
  
  if((fp=fopen("pselcout.dat","w"))!=NULL){
    if(nzrow[0]!=row_min){
      //printf("not eqaul\n"); //DEBUG
      for(p=0;p<nzrow[0]-1;p++){ 
	//printf("p=%d %.8le %.8le %.8le %.8le\n",p,t[p],r[p],r_err[p],fe[p]); 
	fprintf(fp,"%.16le %.16le %.16le %.16le\n",t[p],r[p],r_err[p],fe[p]); 
      }
      for(q=nzrow[0]-1;q<i;q++){	
	//printf("q=%d %.8le %.8le %.8le %.8le\n",q,t[q],nzr[q],nzr_err[q],fe[q]); 
	fprintf(fp,"%.16le %.16le %.16le %.16le\n",t[q],nzr[q],nzr_err[q],fe[q]); 
      }
    }
    else{
      //printf("eqaul\n"); //DEBUG
      //printf("i=%d\n",i); //DEBUG
      for(p=0;p<i;p++){ 
	//printf("p=%d %.8le %.8le %.8le %.8le\n",p,t[p],r[p],r_err[p],fe[p]); 
	fprintf(fp,"%.16le %.16le %.16le %.16le\n",t[p],nzr[p],nzr_err[p],fe[p]); 
      }
    }
      
    fclose(fp);   
  } 
  
  else{ 
    printf("File Open Error!\n"); 
    exit(1); 
  }
  
  
  return 0;
}
