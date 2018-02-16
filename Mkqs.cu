#include "cuda_runtime.h"

#include <fcntl.h>

#include <unistd.h>

#include <sys/stat.h>

#include <iostream>

#include <fstream>

#include "device_launch_parameters.h"

#include <stdio.h>

#include<string.h>

#include<stdlib.h>

#ifndef __CUDACC__

#define __CUDACC__

#endif

#define swap(a,b){ char *t=x[a];x[a]=x[b];x[b]=t;}

#define i2c(i)  x[i][depth]

__device__ long int min(long int a,long int b){
    return a<=b?a:b;
}

__device__ void vecswap(long int i,long int j,long int n, char *x[])
{
    while (n-- > 0) {
        swap(i, j);
        i++;
        j++;
		    }
}



__global__ void ssort1(char *x[],long int n,long int depth){
    cudaStream_t s1,s2,s3;
    long int a,b,c,d,r,v;
	 if(n<=1)
	        return ;
        a=5%n;
    swap(0,a);
    v=i2c(0);
    a=b=1;
    c=d=n-1;
    for (;;)
    {
        while(b<=c && (r=i2c(b)-v)<=0){
            if (r==0) {
                swap(a,b);a++;
	              }
		  b++;
        }



        while(b<=c && (r=i2c(c)-v)>=0){
            if (r==0) {
                swap(c,d); d--;
            }
            c--;   
     }	
        if (b>c)
            break;
        swap(b,c);
        b++;

        c--;

    }

    r=min(a,b-a);

    vecswap(0,b-r,r,x);

    r = min(d-c, n-d-1);

    vecswap(b, n-r, r, x);

    r=b-a;

        cudaStreamCreateWithFlags(&s1,cudaStreamNonBlocking);

    ssort1<<<1,1,0,s1>>>(x,r,depth);

    if (i2c(r)!=0){

                cudaStreamCreateWithFlags(&s2,cudaStreamNonBlocking);

        ssort1<<< 1,1,0,s2>>>(x+r,a+n-d-1,depth+1);

        }

    r=d-c;

        cudaStreamCreateWithFlags(&s3,cudaStreamNonBlocking);

    ssort1<<< 1,1,0,s3>>>(x+n-r,r,depth);

}

__global__ void AddressLoader( char *d_dest, char **d_s, int size, int count)

{


        d_s[0] = &d_dest[0];

        for(long int i=0;d_dest[i]!='\0';i++)

        {
           
     if(d_dest[i] == ' '||d_dest[i] == '\n')

                {

                        d_dest[i] = '\0';

                        d_s[count++] = &d_dest[i+1];

                }

        }

}

__global__ void Printer(char **d_s, long int size)

{

        long int i;

        for(i=0;i<size;i++)

        {

                printf("%s\n", d_s[i]);

        }

}

int main(int argc,char **argv)
{
        long long int i=0,now=0;

        char *input = (char*)calloc(900000000,sizeof(char));

        int fin = open(argv[1],O_RDONLY,0);

        char buf;

        while(read(fin,&buf,sizeof(char))!=0)
        {
                input[i++] = buf;

                if(buf == ' '||buf == '\n')now++;
        }

        input[i++] = '\0';

        printf("Successful\n");

        long int size = strlen(input)+1;

        int count = 1;

        printf("Size = %ld \tWords = %lld \n", size,now);
        
	cudaError_t cudaStatus;

        char *d_dest, **d_s;


        cudaStatus = cudaMalloc((void**)&d_s, sizeof(char*)*now);

        if (cudaStatus != cudaSuccess) {

        fprintf(stderr, "Malloc Fail\n");

    }



        cudaStatus = cudaMalloc((void**)&d_dest, size);

        if (cudaStatus != cudaSuccess) {

        fprintf(stderr, "Malloc Fail\n");

    }

        cudaStatus = cudaMemcpy(d_dest,input, size, cudaMemcpyHostToDevice);

        if (cudaStatus != cudaSuccess) {

        fprintf(stderr, "Malloc Fail\n");

        }

        AddressLoader<<<1,1>>>(d_dest,d_s,size,count);

        ssort1 <<< 1,1 >>>(d_s,now,0);

        Printer<<<1,1>>>(d_s,now);

        cudaDeviceSynchronize();



        //cudaMemcpy(s,d_s, size, cudaMemcpyDeviceToHost);

        //puts(s);

                /*int k;        

        for(k=0;s[k]!='\0';k++)

                printf(" %c \n", s[k] );

*/

        return 0;

}

