#include "utils.cuh"
#include "nj_read.cuh"

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define TPB 32

__global__ void getQMatrix(Matrix D, Vector S, Matrix Q);
__global__ void getMinQReduction(Matrix Q);
__global__ void getMinQUnroll8(Matrix Q);
__global__ void getMinQUnroll16(Matrix Q);

int main(int argc, char const *argv[])
{
    int N, iter;

    dim3 dimThread(TPB, TPB);

    nj_read read;
    Matrix h_D, d_D, d_Q;
    Vector h_S, d_S;
    size_t size_D, size_S;

    read = read_matrix("/content/drive/MyDrive/colab-data/nj-data/gen_100.ent");
    if(read.error) goto EXIT;
    
    size_D = read.size_D;
    size_S = read.size_SUM;
    h_D = read.D;
    h_S = read.SUM;
    N = read.N;

    h_D.n = N;
    h_S.size = N;
    d_D.n = N;
    d_S.size = N;
    d_Q.n = N;

    iter = N;

    cudaMalloc(&d_D.elements, size_D);
    cudaMalloc(&d_S.elements, size_S);
    cudaMemcpy(d_D.elements, h_D.elements, size_D, cudaMemcpyHostToDevice);
    cudaMemcpy(d_S.elements, h_S.elements, size_S, cudaMemcpyHostToDevice);

    cudaMalloc(&d_Q.elements, size_D);

    // A EXECUCAO DO NJ É "LINEAR" (dependente de uma situcao anteior)
    // Somente e possivel calcular as novas distancias depois de selecionar o par
    

    while(iter == N){
        int gridX = (iter+dimThread.x -1)/(dimThread.x);
        int gridY = (iter+dimThread.y -1)/(dimThread.y);
        printf("%d x %d %d x %d\n", gridX, gridY, dimThread.x, dimThread.y);
        dim3 dimGrid(gridX, gridY);
        getQMatrix<<<dimGrid, dimThread>>>(d_D, d_S, d_Q);

        dim3 dimGrid8(dimGrid.x/8, dimGrid.y/8);
        getMinQUnroll8<<<dimGrid, dimThread>>>(d_Q);
        cudaDeviceSynchronize();

        iter--;
    }

    cudaFree(d_D.elements);
    cudaFree(d_S.elements);
    cudaFree(d_Q.elements);

    free(h_D.elements);
    free(h_S.elements);

    return 0;

    EXIT:
    cudaFree(d_D.elements);
    cudaFree(d_S.elements);
    cudaFree(d_Q.elements);
    return 1;

    return 0;
}

__global__ void getQMatrix(Matrix D, Vector S, Matrix Q){
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    float value, d_rc;
    if(row == col) return;
    if(row >= D.n || col >=D.n) return;

    d_rc = d_get_matrix_position(D, row, col);
    value = (D.n-2)*d_rc - S.elements[row] - S.elements[col];

    d_set_matrix_position(Q, row, col, value);
    //printf("%.2f %f\n", value, d_rc);
}

__global__ void getMinQReduction(Matrix Q){
    // row y, col x

}

__global__ void getMinQUnroll8(Matrix Q){
    int row = threadIdx.y;
    int col = threadIdx.x;

    int idx = blockIdx.x * blockDim.x * 8 + threadIdx.x;
    int idy = blockIdx.y * blockDim.y * 8 + threadIdx.y;

    float min_8 = 0, element;

    //__shared__ float* datax = Q.elements + blockIdx.x * blockDim.x * 8;
    //__shared__ float* datay = Q.elements + blockIdx.x * blockDim.x * 8;

    float* datax = Q.elements + blockIdx.x * blockDim.x * 8;
    float* datay = Q.elements + blockIdx.y * blockDim.y * 8;

    int id_i, id_j;

    if(idx + 7 * blockDim.x < Q.n && idy + 7 * blockDim.y < Q.n){
        for (int i = 0; i < 8; i++){
            id_i = idy + i*blockDim.y;

            for(int j = 0; j < 8; j++){
                id_j = idx + i*blockDim.x;
                element = d_get_matrix_position(Q, id_i, id_j);

                if(element < min_8){
                    min_8 = element;
                }
            }
        }
    }

    __syncthreads();

    for (int stride_i = blockDim.y/2; stride_i > 0; stride_i >>= 1){

        if(row < stride_i){
            if(datay[row] > datay[row + stride_i]){
                datay[row] = datay[row + stride_i];
            }
        }
        __syncthreads();
    }

    for(int stride_j = blockDim.x/2; stride_j < 8; stride_j >>=1){
        if( col < stride_j){
            if(datax[col] > datay[col + stride_j]){
                datax[col] = datay[col + stride_j];
            }
        }
        __syncthreads();
    }

    if(datax[col] < min_8) min_8 = datax[col];
    __syncthreads();
    if(datay[row] < min_8) min_8 = datay[row];
    __syncthreads();



    if(col == 0 && row == 0){
        d_set_matrix_position(Q, blockIdx.y, blockIdx.x, min_8);
        //printf("%f\n", min_8);
    }
}

