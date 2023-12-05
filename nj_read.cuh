#ifndef _H_NJ_READ_
#define _H_NJ_READ_

#include "utils.cuh"

typedef struct {
    Matrix D;
    Vector SUM;

    size_t size_D;
    size_t size_SUM;
    
    int N; 
    
    int error;
} nj_read ;

nj_read read_matrix(const char* filename);

#endif

