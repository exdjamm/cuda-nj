#ifndef _H_UTILS_NJ_
#define _H_UTILS_NJ_

typedef struct{
    int size;
    float *elements;
} Vector;

typedef struct{
    int n;
    float *elements;
} Matrix;


__device__ int d_get_pos(int i, int j);
int h_get_pos(int i, int j);

// Matrix
__device__ float d_get_matrix_position(Matrix D, int i, int j);
// float h_get_position(Matrix D, int i, int j);

__device__ void d_set_matrix_position(Matrix D, int i, int j, float value);
void h_set_matrix_position(Matrix D, int i, int j, float value);


#endif