#ifndef HW6
#define HW6

__global__ void smem_fetch(uint *v, uint n, uint *stride, uint *sum, int n_read);
void smem_cpu(Gmem_data *data, int n_read);
#endif
