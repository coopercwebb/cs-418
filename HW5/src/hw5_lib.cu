#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <cuda_fp16.h>
#include "hw5_lib.h"

// _cudaTry -- function used by the cudaTry macro
void _cudaTry(cudaError_t cudaStatus, const char *fileName, int lineNumber) {
  if(cudaStatus != cudaSuccess) {
    fprintf(stderr, "%s in %s line %d\n",
        cudaGetErrorString(cudaStatus), fileName, lineNumber);
    exit(1);
  }
}

// usage(i, opt_names) -- report a command-line usage error
//   i is the index of argv that caused the error.
//   opt_names is an NULL-terminated array of strings for the option names.
//     opt_names[0] is the name of the program.
//     opt_names[i] is a descriptive name for argv[i]
void usage(int i, const char **opt_names, const char *opt, const char *type_name) {
  uint n_opt;
  for(n_opt = 0; (n_opt < 20) && opt_names[n_opt]; n_opt++);
  fprintf(stderr, "usage:");
  for(uint j = 0; j <= i; j++)
    if(j < n_opt) fprintf(stderr, " %s", opt_names[j]);
    else fprintf(stderr, " !unknown-option!");
  if(i+1 < n_opt) {
    fprintf(stderr, " [");
    for(uint j = i+1; j < n_opt; j++)
      fprintf(stderr, "%s%s", j > i+1 ? " " : "", opt_names[j]);
    fprintf(stderr, "]");
  }
  fprintf(stderr, "\n");
  fprintf(stderr, "  %s must be %s, got %s.\n", opt_names[i], type_name, opt);
  exit(-1);
}

// get_uint(argc, argv, opt_names, i, v0): return the i^th command line argument as an unsigned int.
//   opt_names is an array of strings giving the name of the program
//     and descriptive names of the arguments (for error messages).
//   v0 is the default value to return if argc < i.
uint get_uint(int argc, char **argv, const char **opt_names, int i, uint v0) {
  if(argc <= i) return(v0);
  if(argv[i][0] == '-') return(v0);
  // make argv[i] is an integer
  for(int j = 0; argv[i][j]; j++)
    if(!isdigit(argv[i][j]))
      usage(i, opt_names, argv[i], "an integer");
  return((uint)(atof(argv[i])));
}

// get_double(argc, argv, opt_names, i, v0): return the i^th command line argument as a double.
//   opt_names is an array of strings giving the name of the program
//     and descriptive names of the arguments (for error messages).
//   v0 is the default value to return if argc < i.
double get_double(int argc, char **argv, const char **opt_names, int i, double v0) {
  if(argc <= i) return(v0);
  if(argv[i][0] == '-') return(v0);
  return(atof(argv[i]));
}


// mean(n, sum): return the mean of n samples where sum is the sum of the samples.
double mean(uint n, double sum) {
  return(sum/n);
}

// stdev(n, sum, sum_sq): return the standard-deviation of n samples
//   n: the number of samples
//   sum: the sum of the samples
//   sum_sq: the sum of the squares of the samples
// Remark: there are other formulation that are less susceptible to round-off
//   if stdev << mean, but we should't be pushing extreme cases in CPSC 418.
double stdev(uint n, double sum, double sum_sq) {
  return(sqrt((sum_sq - sum*sum/n)/(n-1)));
}

// rand_vector(v, n, elem_size)
//   generate n random values and store them in the vector n.
//   The distribution here is choses so that most point are in the
//   convergence region of the Hénon map -- i.e. repeatedly applying the
//   map doesn't head off to infinity.  I should probably write a more
//   general purpose version some day.
void rand_vector(void *v, uint n, uint elem_size) {
  double s32 = (double)(1l << 32);
  float *v32 = (float *)(v);
  double *v64 = (double *)(v);
  for(uint i = 0; i < n; i++) {
    float f1 = rand()/s32, f2 = rand()/s32;
    if(elem_size == 4) {
      v32[i] = f1-0.5f;
    } else if(elem_size == 8) {
      v64[i] = f1 + f2/s32 - 0.5;
    } else {
      fprintf(stderr,
              "rand_vector(*v, n=%u, elem_size=%u): elem_size must be 2, 4, or 8\n",
	      n, elem_size);
      exit(1);
    }
  }
}


