#include <stdio.h>
#include <iostream>
#include "CImg.h"
#include <math.h>
#include <omp.h>

using namespace std;
using namespace cimg_library;


typedef CImg<unsigned char> IC;
typedef CImg<float> IF;
typedef float F;
typedef int I;


template <size_t s>
IF convolution(IC img, int mask[s][s], int size)
{
	IF imgt(img.width(), img.height(),1,3,0);
	float dim = size*1.0;
	size/=2;
	cout<<"size: "<<size<<endl;
	for (int i = size; i<img.width() - size; i++)
		for (int j = size; j<img.height() - size; j++)
		{
			float cont1 = 0.0, cont2 = 0.0, cont3 = 0.0;
			for (int k = -size; k <= size; k++)
			{
				for (int k1 = -size; k1 <= size; k1++)
				{
					cont1 += (img(i + k1, j + k, 0)*mask[k1 + size][k + size]);
					cont2 += (img(i + k1, j + k, 1)*mask[k1 + size][k + size]);
					cont3 += (img(i + k1, j + k, 2)*mask[k1 + size][k + size]);													
				}
				
			}					
			
			//cout<<cont1<<" "<<cont2<<" "<<cont3<<endl;
			cont1 *= 1.0;	
			cont2 *= 1.0;
			cont3 *= 1.0;
			
			cont1 /= dim;
			cont2 /= dim;
			cont3 /= dim;
			
			imgt(i, j,0) = cont1;
			imgt(i, j,1) = cont2;
			imgt(i, j,2) = cont3;
			
			//if(j==size) break;
		}
	img.get_normalize(0,255);
	return imgt;
}



int main()
{
	IC img("parrot.ppm");
	
	int gx[3][3] = { { -1, -2, -1 }, { 0, 0, 0 }, { 1, 2, 1 } };
	int gy[3][3] = { { 1, 0, -1 }, { 2, 0, -2 }, { 1, 0, -1 } };
	int s3[3][3] = { { 1, 1, 1 }, { 1, 1, 1}, { 1, 1, 1 } };
	int s5[5][5] = { {1, 1, 1, 1,1 }, { 1,1, 1, 1,1}, { 1,1, 1, 1,1 }, { 1,1, 1, 1,1 }, { 1,1, 1, 1,1 }};
	int s7[7][7] = { {1, 1, 1, 1,1,1,1 }, {1,1, 1, 1,1,1,1}, { 1,1, 1, 1,1,1,1 }, { 1,1, 1, 1,1,1,1 }, { 1,1, 1, 1,1,1,1 }, { 1,1, 1, 1,1,1,1 }, { 1,1, 1, 1,1,1,1 }};
	int s11[11][11] = { {1, 1, 1, 1,1,1,1,1,1,1,1 }, {1,1, 1, 1,1,1,1,1,1,1,1}, {1,1, 1, 1,1,1,1,1,1,1,1}, {1,1, 1, 1,1,1,1,1,1,1,1}, {1,1,1,1,1,1,1,1,1,1,1 },
					 { 1,1, 1, 1,1,1,1,1,1,1,1 }, {1,1, 1, 1,1,1,1,1,1,1,1}, {1,1, 1, 1,1,1,1,1,1,1,1}, {1,1, 1, 1,1,1,1,1,1,1,1}, {1,1,1,1,1,1,1,1,1,1,1}, {1,1,1,1,1,1,1,1,1,1,1} };
	
	
	//IF smooth = convolution<3>(img,s3,3);
	//IF smooth = convolution<5>(img,s5,5);
	//IF smooth = convolution<7>(img,s7,7);
	//IF smooth = convolution<11>(img,s11,11);
	//smooth.display();
	//img.display();
	
	int nthreads, tid;

/* Fork a team of threads giving them their own copies of variables */
#pragma omp parallel private(nthreads, tid)
  {

  /* Obtain thread number */
  tid = omp_get_thread_num();
  printf("Hello World from thread = %d\n", tid);

  /* Only master thread does this */
  if (tid == 0) 
    {
    nthreads = omp_get_num_threads();
    printf("Number of threads = %d\n", nthreads);
    }

  }  /* All threads join master thread and disband */

	
	return 0;
	
}
