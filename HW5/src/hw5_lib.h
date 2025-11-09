typedef unsigned long long uint64;
extern void rand_vector(void *v, uint n, uint elem_size);
extern void usage(int i, char **opt_names);
extern uint get_uint(int argc, char **argv, const char **optnames, int i, uint v0);
extern double get_double(int argc, char **argv, const char **optnames, int i, double v0);
extern double mean(uint n, double sum);
extern double stdev(uint n, double sum, double sum_sq);
extern void _cudaTry(cudaError_t cuda_return, const char *FileName, int line);

// cudaTry(CUDACall)
//   call a function in the CUDA API.  If it fails, print an error message
//   and exit.
#define cudaTry(cudaStatus) _cudaTry(cudaStatus, __FILE__, __LINE__)
