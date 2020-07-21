#include<stdio.h>
#include<stdlib.h>
#include<math.h>

int main(void)
{
  int i=0;
  int j=0;
  int k=0;
  int l=0;
  double srct[99999]={0.};
  double srct_err[99999]={0.};
  double srcr[99999]={0.};
  double srcr_err[99999]={0.};
  double put[99999]={0.};
  double put_err[99999]={0.};
  double pur[99999]={0.};
  double pur_err[99999]={0.};
  double put0=0.;

  char src_file[128];
  char pinud_file[128];
  char out_file[128];

  FILE *fp;

  printf("enter source file pinud file >\n");
  scanf("%s %s",src_file,pinud_file);
  printf("enter output file >\n");
  scanf("%s",out_file);

  //source file reading

  fp = fopen(src_file,"r");
  if(fp == NULL){
    printf("can not open source file\n");
    exit(1);
  }
  printf("source file open success\n");

  while(fscanf(fp,"%lf\t%lf\t%lf\t%lf",&srct[i],&srct_err[i],&srcr[i],&srcr_err[i])!=EOF){
    i ++;
  }
  fclose(fp);

  //pinud file reading

  fp = fopen(pinud_file,"r");
  if(fp == NULL){
    printf("can not open pinud file\n");
    exit(1);
  }
  printf("pinud file open success\n");

  while(fscanf(fp,"%lf\t%lf\t%lf\t%lf",&put[j],&put_err[j],&pur[j],&pur_err[j])!=EOF){
    j ++;
  }
  fclose(fp);

  put0=put[0];

  for(l=0;l<j;l++){
    put[l] = put[l] - put0;
  }

  fp = fopen(out_file,"w");
  if(fp == NULL){
    printf("can not open pinud file\n");
    exit(1);
  }

  printf("output file open success\n");

  for(k=0;k<i;k++){
    for(l=0;l<j;l++){
      if(srct[k] == put[l]){
	fprintf(fp,"%.16le %.16le %.16le %.16le %.16le %.16le\n",srct[k],srct_err[k],srcr[k],srcr_err[k],pur[l],pur_err[l]);
      }
    }
  }

  fclose(fp);

  return 0;
}
