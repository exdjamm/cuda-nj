#include "nj_read.cuh"

#include <stdio.h>
#include <stdlib.h>

nj_read read_matrix(const char* filename){
    int N;
    float value, sum_i, sum_j;
    size_t size_D, size_S;

    nj_read result;
    result.error = 0;

    FILE* f = fopen(filename, "r");
    if(!f) goto EXIT;

    if (fscanf(f,"%d ",&N) != 1) goto READERRO;

    result.N = N;
    
    size_D = (N*N)*sizeof(float);
    result.D.elements = (float*) malloc(size_D);
    if(result.D.elements == NULL) goto EXIT;

    size_S = N*sizeof(float);
    result.SUM.elements = (float*) calloc(N, sizeof(float));
    if(result.SUM.elements == NULL) goto EXIT;

    result.size_SUM = size_S;
    result.size_D = size_D;

    // Distancias
    for(int i = 0; i < N; ++i)
    {
        for (int j = 0; j < i; ++j)
        {
            if(fscanf(f, "%f;", &value) != 1) goto READERRO;
            h_set_matrix_position(result.D, i, j, value);
            h_set_matrix_position(result.D, j, i, value);

            sum_i = result.SUM.elements[i];
            sum_j = result.SUM.elements[j];

            result.SUM.elements[i] = sum_i + value;
            result.SUM.elements[j] = sum_j + value;
            // printf("%f, %d-%d\n", value, i, j);
        }
        h_set_matrix_position(result.D, i, i, 0.0);
    }

    fclose(f);
    
    return result;

    READERRO:
    printf("Erro de leitura");
    goto EXIT;

    EXIT:
    fclose(f);
    free(result.D.elements);
    free(result.SUM.elements);
    result.error = 1;
    return result;
}
