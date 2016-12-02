#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <iostream>
#include "CImg.h"
#include <math.h>
#include <chrono>

using namespace std;
using namespace cimg_library;


typedef CImg<unsigned char> IC;
typedef CImg<float> IF;
typedef float F;
typedef int I;


//Calculates the borders of an image using a convolution mask(Sobel operator)
IF convolution(IC img, int mask[3][3])
{
	IF imgt(img.width(), img.height());
	for (int i = 1; i<img.width() - 1; i++)
		for (int j = 1; j<img.height() - 1; j++)
		{
			float cont = 0.0;
			for (int k = -1; k <= 1; k++)
				for (int k1 = -1; k1 <= 1; k1++)
					cont += (img(i + k1, j + k)*mask[k1 + 1][k + 1]);
			float dim = 9 * 1.0;
			cont *= 1.0;
			cont /= dim;
			imgt(i, j) = cont;
		}
	//img.get_normalize(0,255);
	return imgt;
}

//Transforms an image into a vector
float* create_fils(IF img, int Width, int Height)
{
	float * fils = (float*)malloc(Height*Width*sizeof(float));
	int cont = 0;
	for (int i = 0; i < Height; i++)
		for (int j = 0; j < Width; j++)
		{
			fils[cont] = img(j, i);
			cont++;
		}
	return fils;
}

//Displays the image contained in a vector
void draw_fils(float * fils, int Width, int Height)
{
	IF tmp(Width, Height);
	int cont = 0;
	for (int i = 0; i < Height; i++)
		for (int j = 0; j < Width; j++)
		{
			tmp(j, i) = fils[cont];
			cont++;
		}
	tmp.display();
}


//Calculates the gradients of an image contained in a vector in Cuda
__global__ void dev_gauss(float *dev_fils, int Width, int Height, float *dev_result, int size)
{
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	int N = Width * Height;
	int sm = size / 2;
	//while (tid < N){
	while (tid < (N - sm*Width) && tid >(sm*Width) && (tid %Width >sm) && (tid %Width)< (Width - sm)){
		float media=0.0;
		int beginning = tid - size*Width - sm;
		for (int l = 0; l < size; l++)
		{
			int tmp = beginning;
			for (int k = 0; k < size; k++)
			{
				media += dev_fils[tmp];
				tmp++;
			}
			beginning += Width;
		}
		media /= size;

		dev_result[tid] = media;
		tid += blockDim.x * gridDim.x;
	}

}

int main()
{
	IC img("ironman.bmp");
	IF red = img.get_channel(0);

	//-------------------------------------------------------------------------------
	//-----------------------------------------CUDA CODE-----------------------------
	//-------------------------------------------------------------------------------

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);


	int Width = red.width(), Height = red.height();
	int N = Width*Height;
	int size = 13;
	int MaxThreads = 1024;


	float * fils = create_fils(red, Width, Height);
	float * gxy = (float*)malloc(Width*Height*sizeof(float) - Width);

	float * dev_fils;	cudaMalloc((void**)&dev_fils, Width*Height*sizeof(float));
	float * dev_result;	cudaMalloc((void**)&dev_result, Width*Height*sizeof(float) - Width);

	cudaMemcpy(dev_fils, fils, Width*Height*sizeof(float), cudaMemcpyHostToDevice);

	//KERNEL EXECUTION
	cudaEventRecord(start);
	dev_gauss << <(N + MaxThreads - 1) / MaxThreads, MaxThreads >> >(dev_fils, Width, Height, dev_result,size);
	cudaEventRecord(stop);


	cudaMemcpy(gxy, dev_result, Width*Height*sizeof(float) - Width, cudaMemcpyDeviceToHost);

	cudaEventSynchronize(stop);


	//PRINTING PARALLEL PROCESSING TIME: 76.123 milisegundos

	float milliseconds = 0;
	cout << "time spent" << endl;
	cudaEventElapsedTime(&milliseconds, start, stop);
	cout << milliseconds << endl;
	cout << "time spent" << endl;

	//Freeing memory
	cudaFree(dev_fils);
	cudaFree(dev_result);


	cout << "Displaying computed image in cuda: " << endl;
	draw_fils(gxy, Width, Height - 1);

	return 0;

}
