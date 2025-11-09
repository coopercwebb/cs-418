#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>
#include "hw5_lib.h"

// henon32: GPU kernel that implements the Hénon map using 32-bit floating point arirhmetic.
//   x0: the initial values for x, one value per CUDA thread (pointer to device memory)
//   y0: the initial values for y, one value per CUDA thread (pointer to device memory)
//   s2: write the final sum of the squared step-lengths here, see note below
//   s4: write the final sum of the fourth-powers of step-lengths here, see note below
//   n_data: total number of data values in x0, y0, xm, and ym.
//   n_iter: perform n_iter iterations of the Hénon map.
//   a, b: parameters for the Hénon map.
// See:
//   https://en.wikipedia.org/wiki/Hénon_map
//   Note about s2 and s4.
//    Let (x_{i-1},y_{i-1}) and (x_i, y_i) be the values of x and y at the
//    beginning and //    end (respectively) of one iteration of the Hénon map.
//    The Euclidean distance between (x_{i-1},y_{i-1}) and (x_{i+2},y_{i+2}) is
//      sqrt((x_i-x_{i-1})^2 + (y_i+-y_{i-1})^2).
//    Square-roots are slow, so, we'll just compute the average of
//      (x_i-x_{i-1})^2 + (y_i-y_{i-1})^2.
//    To do so, we compute:
//      s2 = sum_{i=1}^{n_data} (x_i-x_{i-1})^2 + (y_i-y_{i-1})^2).
//    The average, squared step-length is s2/n_data.
//    We are also interested in the variation of the squared-step size.  To
//    compute the variance, we
//      s4 = sum_{i=1}^{n_data} (x_i-x_{i-1})^2 + (y_i-y_{i-1})^2)^2,
//    i.e. sum of the the step-lengths to the fourth power.  The host function
//    that invokes this kernel uses the var funtion to compute the variance.

// henon32: the henon recurrence computing with 32-bit floating point
__global__ void henon32(float *x0, float *y0, float *s2, float *s4,
			uint n_data, uint n_iter, float a, float b) {
  // you need to write this
}

// henon64: the henon recurrence computing with 64-bit floating point
__global__ void henon64(double *x0, double *y0, double *s2, double *s4,
			uint n_data, uint n_iter, double a, double b) {
  // you need to write this
}

// henon_gpu: wrapper for launching a CUDA kernel to compute the Hénon map.
//   x0: the initial values for x, one value per CUDA thread (pointer to host memory)
//   y0: the initial values for y, one value per CUDA thread (pointer to host memory)
//   s2: write the final sum of the squared step-lengths here, see note below
//   s4: write the final sum of the fourth-powers of step-lengths here, see note below
//   n_blocks: lauch a kernel with n_blocks blocks.
//   threads_per_block: each block has threads_per_block threads
//   a, b: parameters for the Hénon map.
// Return value:
//   t_elapsed: the amount of time (in seconds) that it took to execute the kernel.
// Side-effects:
//   s2 is updated with the sum of the squares of the step lengths.
//   s4 is updated with the sum of the step lengths to the fourth power.
// Description:
//   This function handles the allocation and freeing of GPU memory,
//   launching the kernel, and error reporting.
double henon_gpu(void *x0, void *y0, void *s2, void *s4,
                 uint elem_size, uint n_blocks, uint threads_per_block, uint n_iter,
		 double a, double b) {

  void *d_x0, *d_y0, *d_s2, *d_s4;
  struct rusage r0, r1; // for timing measurements
  uint n_data = n_blocks * threads_per_block;
  int sz = n_data * elem_size;

  // Allocate memory on the GPU for all of the arrays.
  cudaTry(cudaMalloc(&d_x0, sz));
  cudaTry(cudaMalloc(&d_y0, sz));
  cudaTry(cudaMalloc(&d_s2, sz));
  cudaTry(cudaMalloc(&d_s4, sz));
  
  // Copy over the input arrays.
  cudaTry(cudaMemcpy(d_x0, x0, sz, cudaMemcpyHostToDevice));
  cudaTry(cudaMemcpy(d_y0, y0, sz, cudaMemcpyHostToDevice));

  // Calculate the recurrence.
  getrusage(RUSAGE_SELF, &r0); // push the "stop button" on our stopwatch
  if(elem_size == 4)
    henon32<<<n_blocks, threads_per_block>>>
           ((float *)d_x0, (float *)d_y0, (float *)d_s2, (float *)d_s4,
	   n_data, n_iter, (float)a, (float)b);
  else if(elem_size == 8)
    henon64<<<n_blocks, threads_per_block>>>
           ((double *)d_x0, (double *)d_y0, (double *)d_s2, (double *)d_s4,
	   n_data, n_iter, a, b);
  else {
    fprintf(stderr, "henon_gpu: elem_size must be 4, or 8, got %u\n", elem_size);
    exit(-1);
  }
  cudaTry(cudaDeviceSynchronize());
  getrusage(RUSAGE_SELF, &r1); // push the "stop button" on our stopwatch
  double t_elapsed =   (r1.ru_utime.tv_sec - r0.ru_utime.tv_sec)
		     + 1e-6*(r1.ru_utime.tv_usec - r0.ru_utime.tv_usec);

  // Copy back the result.
  cudaTry(cudaMemcpy(s2, d_s2, sz, cudaMemcpyDeviceToHost));
  cudaTry(cudaMemcpy(s4, d_s4, sz, cudaMemcpyDeviceToHost));

  // Free up the arrays on the GPU.
  cudaTry(cudaFree(d_x0));
  cudaTry(cudaFree(d_y0));
  cudaTry(cudaFree(d_s2));
  cudaTry(cudaFree(d_s4));
  return(t_elapsed);
}

// henon_cpu32: reference implementation of the Hénon map on a CPU
//   implemented using 32-bit floating point
void henon_cpu32(float *x0, float *y0, float *s2, float *s4,
		 uint n_data, uint n_iter, float a, float b) {

  for(uint j = 0; j < n_data; j++) {
    // Iterate over elements of the input array.
    float x_curr = x0[j];
    float y_curr = y0[j];
    float sum_d2 = 0.0;
    float sum_d4 = 0.0;
    for(uint i = 0; i < n_iter; i++) {
      // Iterate the recurrence on this element.
      float x_next = 1.0f - a * x_curr * x_curr + y_curr;
      float y_next = b * x_curr;
      float dx = x_next - x_curr;
      float dy = y_next - y_curr;
      float d2 = dx*dx + dy*dy;
      sum_d2 += d2;
      sum_d4 += d2*d2;
      x_curr = x_next;
      y_curr = y_next;
    }
    s2[j] = sum_d2;
    s4[j] = sum_d4;
  }
}


// henon_cpu64: reference implementation of the Hénon map on a CPU
//   implemented using 64-bit floating point
void henon_cpu64(double *x0, double *y0, double *s2, double *s4,
		 uint n_data, uint n_iter, double a, double b) {
  // you need to write this
}

  
double henon_cpu(void *x0, void *y0, void *s2, void *s4,
                 uint elem_size, uint n_data, uint n_iter, double a, double b) {
  struct rusage r0, r1; // for timing measurements
  getrusage(RUSAGE_SELF, &r0); // push the "start button" on our stopwatch
  switch(elem_size) {
    case 4:
      henon_cpu32((float *)x0, (float *)y0, (float *)s2, (float *)s4,
		  n_data, n_iter, (float)a, (float)b);
      break;
    case 8:
      henon_cpu64((double *)x0, (double *)y0, (double *)s2, (double *)s4,
		  n_data, n_iter, (double)a, (double)b);
  }
  getrusage(RUSAGE_SELF, &r1); // push the "stop button" on our stopwatch
  double t_elapsed =   (r1.ru_utime.tv_sec - r0.ru_utime.tv_sec)
		     + 1e-6*(r1.ru_utime.tv_usec - r0.ru_utime.tv_usec);
  return(t_elapsed);
}


double rms(void *sums, uint elem_size, uint n_data, uint n_iter) {
  double n = ((double)n_data) * ((double)n_iter);
  double sum = 0.0;
  float *fsums = (float *)sums;
  double *dsums = (double *)sums;
  for(uint i = 0; i < n_data; i++) {
    double v;
    switch(elem_size) {
      case 4: v = fsums[i]; break;
      case 8: v = dsums[i];
    }
    sum += v;
  }
  return(sum/n);
}

double var(void *s2, void *s4, uint elem_size, uint n_data, uint n_iter) {
  double n = ((double)n_data) * ((double)n_iter);
  double sum2 = 0.0;
  double sum4 = 0.0;
  float  *fs2 = (float *)s2,  *fs4 = (float *)s4;
  double *ds2 = (double *)s2, *ds4 = (double *)s4;
  for(uint i = 0; i < n_data; i++) {
    double v2, v4;
    switch(elem_size) {
      case 4: v2 = fs2[i]; v4 = fs4[i]; break;
      case 8: v2 = ds2[i]; v4 = ds4[i];
    }
    sum2 += v2;
    sum4 += v4;
  }
  return((sum4 - (sum2*sum2)/n)/(n-1.0));
}


// main:  top-level for Hénon map.
//     usage:  henon n_blocks threads_per_block n_iter n_trials elem_size
//  Description:
//    Create n_data = n_blocks*threads_per_block initial points for the
//    Hénon map.  Apply the map n_iter times using the GPU kernel.
//    If elem_size=4, call the single-precision kernel.
//    Else if elem_size=8, call the double-precision kernel.
//    Measure the elapsed times for n_trials such launches of the GPU kernel.
//    Report the mean and standard deviation.
//      If the total amount of computation is small enough, we also perform
//    the computation (once) on the host CPU and report the results.
int main(int argc, char **argv) {
  // get the command line arguments (or defaults)
  const char *opt_names[] =
    {"henon", "n_blocks", "threads_per_block", "n_iter", "n_trials", "elem_size", NULL};
  uint n_blocks          = get_uint(argc, argv, opt_names, 1, 100);
  uint threads_per_block = get_uint(argc, argv, opt_names, 2, 1024);
  uint n_iter            = get_uint(argc, argv, opt_names, 3, 1000000);
  uint n_trials          = get_uint(argc, argv, opt_names, 4, 5);
  uint elem_size         = get_uint(argc, argv, opt_names, 5, 4);

  uint n_data = n_blocks*threads_per_block;
  double a = 1.3;
  double b = 0.3;
  void *x0 = malloc(n_data*elem_size);
  void *y0 = malloc(n_data*elem_size);
  void *s2 = malloc(n_data*elem_size);
  void *s4 = malloc(n_data*elem_size);
  void *s2_cpu = malloc(n_data*elem_size);
  void *s4_cpu = malloc(n_data*elem_size);

  rand_vector(x0, n_data, elem_size);
  rand_vector(y0, n_data, elem_size);

  double t_sum=0.0, t2_sum = 0.0;
  for(int i = 0; i < n_trials; i++) {
    double t_elapsed = henon_gpu(x0, y0, s2, s4, elem_size, n_blocks, threads_per_block, n_iter, a, b);
    t_sum += t_elapsed;
    t2_sum += t_elapsed*t_elapsed;
  }
  if((((double)(n_data) * (double)(n_iter)) < 1.0e8)) { // compare with CPU
    double t_elapsed = henon_cpu(x0, y0, s2_cpu, s4_cpu, elem_size, n_data, n_iter, a, b);
    double rms_cpu = rms(s2_cpu, elem_size, n_data, n_iter);
    double var_cpu = var(s2_cpu, s4_cpu, elem_size, n_data, n_iter);
    printf("CPU: rms-step-size = %5.3lf, var = %5.3lf\n", rms_cpu, var_cpu);
    printf("CPU: n_data=%6u, n_iter=%8u, t_elapsed=%12.4g\n", n_data, n_iter, t_elapsed);
  }
  double rms_gpu = rms(s2, elem_size, n_data, n_iter);
  double var_gpu = var(s2, s4, elem_size, n_data, n_iter);
  printf("GPU: rms-step-size = %5.3lf, var = %5.3lf\n", rms_gpu, var_gpu);
  if(n_trials == 0) printf("done: n_trial = %d\n", n_trials);
  if(n_trials == 1) printf("time elapsed = %12.4g\n", t_sum);
  if(n_trials > 1)
    printf("GPU, n_blocks=%3u, tpb=%4u, n_iter=%8u, %s-precision, time elapsed: mean = %12.4g, stdev = %12.4g\n",
           n_blocks, threads_per_block, n_iter,
	   (elem_size == 4) ? "single" : "double",
	   mean(n_trials, t_sum), stdev(n_trials, t_sum, t2_sum));
  exit(0);
}
