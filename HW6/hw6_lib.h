#ifndef HW6_LIB
#define HW6_LIB

#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#include <cassert>
#include <string>
#include <cmath>

typedef unsigned int uint;

// Andrew's improved version of CudaTry
#define CudaTry(ans)                          \
    {                                         \
        gpuAssert((ans), __FILE__, __LINE__); \
    }
__inline __host__ void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr, "CudaTry ASSERTION FAILED: %s %s, line %d\n", cudaGetErrorString(code), file, line);
        if (abort)
            exit(code);
    }
}

/************************************************************************/
/*                                                                      */
/*  Functions exported by hw6_lib.cu                                    */
/*                                                                      */
/************************************************************************/

// get_int(argc, argv, opt_names, i, v0): return the i^th command line argument as an int.
int get_int(int argc, char **argv, const char **opt_names, int i, int v0);

// get_uint(argc, argv, opt_names, i, v0): return the i^th command line argument as an unsigned int.
uint get_uint(int argc, char **argv, const char **opt_names, int i, uint v0);

// get_uint(argc, argv, opt_names, i, v0): return the i^th command line argument as an unsigned int.
double get_double(int argc, char **argv, const char **opt_names, int i, double v0);

// mean(n, sum): return the mean of n samples where sum is the sum of the samples.
double mean(uint n, double sum);

// stdev(n, sum, sum_sq): return the standard-deviation of n samples
double stdev(uint n, double sum, double sum_sq);

/************************************************************************/
/*                                                                      */
/*  Header files from other modules                                     */
/*                                                                      */
/************************************************************************/

#include "hw6_mem.h"
#include "hw6.h"

#endif
