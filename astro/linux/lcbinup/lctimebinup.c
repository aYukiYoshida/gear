#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#define bin 2000.0000

main()
{
   int i;
   int t=0,N;
   FILE *fp;
   float time[100000]={0};
   float count[100000]={0};
   float terror[100000]={0};
   float cerror[100000]={0};
   float test[100000]={0};
   float time_iv=0.0000;
   float time_sum=0.00000;
   double count_sum=0.0000;
   float terror_sum=0.0000;
   double cerror_sum=0.0000;
   float ave_time,ave_terror,test1;
   double ave_count=0.000000000,ave_cerror=0.0000000000;
   fp = fopen("test2.qdp","r");
   for(N=0;N<100000;N++){
     fscanf(fp,"%f %f %G %G %f\n",&time[N],&terror[N],&count[N],&cerror[N],&test[N]);
   }
fclose(fp);
  printf("READ SERR 1 2\n");
  printf("!\n");
  printf("lw 5 \n");
  printf("cs 1.3\n");
  printf("la x Time (s)\n");
  printf("la y Counts/s \n");
 for(N=0;N<100000;N++){
   //if(cerror[N] != 0.000000){
   if((fabs(time[N+1]-time[N]))<=bin){
     time_sum +=time[N];
     if(cerror[N] != 0.000000){
       count_sum +=count[N]/cerror[N]/cerror[N];
       terror_sum +=terror[N];
       cerror_sum +=1/cerror[N]/cerror[N];
     }
     t++;
   }
   else if((fabs(time[N+1]-time[N]))>bin){
       time_sum +=time[N];
       if(cerror[N] != 0.000000){
	 count_sum +=count[N]/cerror[N]/cerror[N];
	 terror_sum +=terror[N];
	 cerror_sum +=1/cerror[N]/cerror[N];
       }
       t++;
       time_iv=time[N]-time[N-t+1];
       ave_time=time_sum/t;
       ave_count=count_sum/cerror_sum;
       ave_terror=terror_sum/t;
       ave_cerror=1/sqrt(cerror_sum);
       printf("%f %f %f %f \n",ave_time,time_iv*0.5,ave_count,ave_cerror);
       time_sum=0;
       count_sum=0;
       t=0;
       terror_sum=0;
       cerror_sum=0;
     }
     /*     else if ((fabs(time[N+1]-time[N]))>2500.0000&&(cerror[N] == 0.000000)){
     //time_sum +=time[N];
     //count_sum +=count[N]/cerror[N]/cerror[N];
     //terror_sum +=terror[N];
     //cerror_sum +=1/cerror[N]/cerror[N];
     //t++;
     time_iv=time[N]-time[N-t+1];
     ave_time=time_sum/t;
     ave_count=count_sum/cerror_sum;
     ave_terror=terror_sum/t;
     ave_cerror=1/sqrt(cerror_sum);
     printf("%f %f %f %f \n",ave_time,time_iv*0.5,ave_count,ave_cerror);
     time_sum=0;
     count_sum=0;
     t=0;
     terror_sum=0;
     cerror_sum=0;
     }
     */
     }
 }
