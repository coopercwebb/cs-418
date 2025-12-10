#ifndef HW6_MEM
#define HW6_MEM

#include "hw6_types.h"

typedef uint (*ElValFun)(int i, int n, uint *params);

typedef struct ArrayInit
{
    ElValFun val_fun;
    uint param[10]; // simple if you at most 10 parameters
    uint *params;
} ArrayInit;

ArrayInit *ai_const(ArrayInit *ai, uint c);
ArrayInit *ai_const(ArrayInit *ai);
ArrayInit *ai_rand(ArrayInit *ai, uint m);
ArrayInit *ai_seq(ArrayInit *ai, uint v0, uint dv, uint m);
ArrayInit *ai_seq(ArrayInit *ai, uint v0, uint dv);
ArrayInit *ai_seq(ArrayInit *ai, uint dv);
ArrayInit *ai_seq(ArrayInit *ai);

class Gmem_data
{ // data for measuring global memory access times
private:
    void init();     // called by constructor
    void clean_up(); // called by destructor

public:
    uint n;                // number of elements of v_host and v_dev
    int n_blk;             // number of blocks to use for the CUDA kernel
    int threads_per_block; // number of threads per block for the CUDA kernel

    // v_host and v_host are the "big" arrays that we will repeatedly read.
    //   See the comment for the stride arrays for a description of the access patterns.
    //   The v arrays each have n elements.
    uint *v_host, *v_dev;

    // Each CUDA thread has a global index: blockDim.x*blockIdx.x + threadIdx.x.
    // Call this my_idx.  The thread reads from:
    //   v[my_idx], v[my_idx + stride[my_idx]], v[my_idx + 2*stride[my_idx]], ...
    // with all of the indices mod n.  The user can create different access
    // patterns by changing how the stride[arrays] are initialized.
    // The stride arrays each have n_thr() elements.
    uint *stride_host, *stride_dev;

    // Our kernel computes the sum of the elements accessed and stores the
    // result in the sums array.  This makes sure the compiler sees us doing
    // something with the values we read from global memory so that these reads
    // can't be eliminated when the compiler generates optimized code.  They
    // also give us a way to test that the CPU and GPU versions of the computation
    // produce the same result.
    // The sums arrays
    uint *sum_host, *sum_dev;

    // our constructor
    Gmem_data(uint n, int n_blk, int threads_per_block,
              ArrayInit *s_init, ArrayInit *v_init),
        ~Gmem_data(); // our destructor
    int n_threads();
};

bool gmem_test(Gmem_data *data, int n_read);
float gmem_time(Gmem_data *data, int n_read);
void print_time(double t);

#endif
