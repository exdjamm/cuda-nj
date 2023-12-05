#include "utils.cuh"

int h_get_pos(int i, int j){
    int pos;

    if(i==j)
        return -1;

    pos = i*(i-1)/2 + j;
    if(i < j)
        pos = j*(j-1)/2 + i;

    return pos;
}

__device__ int d_get_pos(int i, int j){
    int pos;

    if(i==j)
        return -1;

    pos = i*(i-1)/2 + j;
    if(i < j)
        pos = j*(j-1)/2 + i;

    return pos;
}

void h_set_matrix_position(Matrix D, int i, int j, float value){
    int pos;

    if(i==j)
      return;

    pos = i*(i-1)/2 + j;
    if(i < j)
        pos = j*(j-1)/2 + i;
    // pos = i*D.n + j;
    D.elements[pos] = value;
}

__device__ void d_set_matrix_position(Matrix D, int i, int j, float value){
    int pos;

    if(i==j)
        return;

    pos = i*(i-1)/2 + j;
    if(i < j)
        pos = j*(j-1)/2 + i;
    pos = i*D.n + j;
    D.elements[pos] = value;
}

__device__ float d_get_matrix_position(Matrix D, int i, int j){
    int pos;

    if(i==j)
         return 0;

    pos = i*(i-1)/2 + j;
    if(i < j)
         pos = j*(j-1)/2 + i;
    //pos = i*D.n + j;
    return D.elements[pos] ;
}
