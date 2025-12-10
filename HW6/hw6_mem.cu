#include "hw6_lib.h"

#define V_SH_DIM 1024 // size of v_sh array (in shared memory)

static void ar_initialize(uint *ar, int n, ArrayInit *ai)
{
    for (int i = 0; i < n; i++)
        ar[i] = ai->val_fun(i, n, ai->params);
}

ArrayInit *ai_const(ArrayInit *ai, uint c)
{
    return (ai_seq(ai, c, 0, 0));
}
ArrayInit *ai_const(ArrayInit *ai) { return (ai_const(ai, 0)); }

static uint elval_rand(int i, int n, uint *params)
{
    uint r = rand();
    if (params[0] == 0)
        return (r);
    else
        return (r % params[0]);
}

ArrayInit *ai_rand(ArrayInit *ai, uint m)
{
    ai->val_fun = elval_rand;
    ai->param[0] = m;
    ai->params = &(ai->param[0]);
    return (ai);
}

// elval_rot: treat i as a w bit word, and rotate the bits of i by
//   r positions to the right, where r = params[0] and w = params[1].
//   For example, if i = 010011, r = 2 and w = 6, then elval_rot returns 110100.
static uint elval_rot(int i, int n, uint *params)
{
    uint r = params[0];
    uint w = params[1];
    uint lo_mask = (1 << r) - 1;
    uint hi_mask = ((1 << (w - r)) - 1) << r;
    uint ret = ((i & hi_mask)) >> r | ((i & lo_mask) << (w - r));

    return (ret);
}

// ai_rot(ai, r, w)
//   This inialization sets ar[i] to the rotation of the w least significant
//   bits of i by r positions to the right.  The other bits of i are masked out.
ArrayInit *ai_rot(ArrayInit *ai, uint r, uint w)
{
    ai->val_fun = elval_rot;
    ai->param[0] = r;
    ai->param[1] = w;
    ai->params = &(ai->param[0]);
    return (ai);
}

static uint elval_seq(int i, int n, uint *params)
{
    uint v = params[0] + params[1] * i;
    if (params[2] == 0)
        return (v);
    else
        return (v % params[2]);
}

ArrayInit *ai_seq(ArrayInit *ai, uint v0, uint dv, uint m)
{
    ai->val_fun = elval_seq;
    ai->param[0] = v0;
    ai->param[1] = dv;
    ai->param[2] = m;
    ai->params = &(ai->param[0]);
    return (ai);
}

ArrayInit *ai_seq(ArrayInit *ai, uint v0, uint dv) { return (ai_seq(ai, v0, dv, 0)); }
ArrayInit *ai_seq(ArrayInit *ai, uint dv) { return (ai_seq(ai, 0, dv)); }
ArrayInit *ai_seq(ArrayInit *ai) { return (ai_seq(ai, 1)); }

Gmem_data::Gmem_data(uint n, int n_blk, int threads_per_block,
                     ArrayInit *s_init, ArrayInit *v_init)
{
    this->n = n;
    this->n_blk = n_blk;
    this->threads_per_block = threads_per_block;

    // allocate and initialize data on host
    // HELP: I tried using new uint[n], and new uint[n_threads()] to allocate
    // the host arrays, but the corresponding deletes failed.  I reverted
    // to using malloc.  Maybe one of the TAs or someone in the class
    // can teach me some C++.
    size_t v_size = n * sizeof(uint);
    size_t stride_size = n_threads() * sizeof(uint);
    v_host = (uint *)malloc(v_size);
    stride_host = (uint *)malloc(stride_size);
    sum_host = (uint *)malloc(stride_size);
    // make sure new succeeded -- it could fail if n or n_threads() is too big
    if ((v_host == NULL) || (stride_host == NULL) || (sum_host == NULL))
    {
        fprintf(stderr, "Gmem_data(%u, %d, %d): new failed?!\n",
                n, n_blk, threads_per_block);
        if (this->v_host == NULL)
            fprintf(stderr, "  v_host == NULL\n");
        if (stride_host == NULL)
            fprintf(stderr, "  stride_host == NULL\n");
        if (sum_host == NULL)
            fprintf(stderr, "  sum_host == NULL\n");
        exit(-1);
    }

    // default for vi: v_host[i] = rand() % n;
    ArrayInit default_vi, default_si;
    ArrayInit *vi = (v_init == NULL) ? ai_rand(&default_vi, n) : v_init;
    ArrayInit *si = (s_init == NULL) ? ai_const(&default_si, 1) : s_init;
    ar_initialize(v_host, n, vi);
    ar_initialize(stride_host, n_threads(), si);

    // allocate and initialize data on the device
    CudaTry(cudaMalloc(&v_dev, v_size));
    CudaTry(cudaMalloc(&stride_dev, stride_size));
    CudaTry(cudaMalloc(&sum_dev, stride_size));
    CudaTry(cudaMemcpy(v_dev, v_host, v_size, cudaMemcpyHostToDevice));
    CudaTry(cudaMemcpy(stride_dev, stride_host, stride_size, cudaMemcpyHostToDevice));
}

Gmem_data::~Gmem_data()
{
    CudaTry(cudaFree(sum_dev));
    CudaTry(cudaFree(stride_dev));
    CudaTry(cudaFree(v_dev));
    free(sum_host);
    free(stride_host);
    free(v_host);
}

int Gmem_data::n_threads()
{
    return (n_blk * threads_per_block);
}

/* gmem_fetch(uint *v, uint n, uint *stride, uint *sum, int n_read)
 *   Perform lots of global memory reads to measure the impact of global reference coalescing.
 *
 *   Let my_idx = blockDim.x*blockIdx.x + threadIdx.x in the comments below.
 *   Parameters:
 *     uint *v: an array of n values.
 *     uint n:  the number of elements of v
 *     uint *stride:
 *       We read locations of v starting at v[my_idx] and increasing the array index
 *       by stride[my_idx] with each iteration, wrapping around when crossing n.
 *     n_read: perform n_read such global memory reads.
 *
 *   Precondition:  gridDim.x*blockDim.x <= n.
 *     We don't check for this, but this code can incur a memory violation if
 *       there are more threads in the kernel than elements of v.
 *
 *   Effect:
 *     the sum of the values that we read is stored in sum[my_idx].
 */
__global__ void gmem_fetch(uint *v, uint n, uint *stride, uint *sum, int n_read)
{
    uint my_idx = blockDim.x * blockIdx.x + threadIdx.x;
    uint my_stride = stride[my_idx];
    uint acc = 0;
    uint m = my_idx;
    for (uint j = 0; j < n_read; j++)
    {
        acc += v[m];
        m += my_stride;
        if (m >= n)
            m -= n;
    }
    sum[my_idx] = acc;
}

/* smem_fetch: perform lots of shared memory reads to measure the impact     *
 *   of shared memory conflicts.                                             *
 *                                                                           *
 * Description adapted from gmem_fetch in hw6_lib.cu.                        *
 *   If you haven't read the gmem_fetch source code yet,                     *
 *   you really should.                                                      *
 *                                                                           *
 *   Let my_idx = blockDim.x*blockIdx.x + threadIdx.x in the comments below. *
 *   Parameters:                                                             *
 *     uint *v: an array of n values.                                        *
 *     uint n:  the number of elements of v                                  *
 *     uint *stride:                                                         *
 *       We read locations of v starting at v[my_idx] and increasing the     *
 *       array index by stride[my_idx] with each iteration, wrapping around  *
 *       when crossing n.                                                    *
 *     n_read: perform n_read such global memory reads.                      *
 *                                                                           *
 *   Precondition:  blockDim.x <= n                                          *
 *     We don't check for this, but this code can incur a memory violation   *
 *       if there are more threads in the kernel than elements of v.         *
 *                                                                           *
 *   Effect:                                                                 *
 *     sum[my_idx] should be updated with something that depends on what     *
 *     gets computed in your for-loop that performs n_read loads (per        *
 *     thread) from shared memory.                                           *
 *                                                                           */

__global__ void smem_fetch(uint *v, uint n, uint *stride, uint *sum, int n_read)
{
    // Executes once per block
    __shared__ uint v_sh[V_SH_DIM];
    // Everything below executes per thread

    uint my_idx = blockDim.x * blockIdx.x + threadIdx.x;

    // Transfer from global memory to shared memory (coalescence will speed it up here)
    if (threadIdx.x < n)
    {
        v_sh[threadIdx.x] = v[threadIdx.x];
    }

    __syncthreads();

    uint acc = 0;
    uint m = threadIdx.x;
    uint my_stride = stride[my_idx];
    for (int j = 0; j < n_read; j++)
    {
        acc += v_sh[m];
        m += my_stride;
        if (m >= n)
        {
            m -= n;
        }
    }

    sum[my_idx] = acc;
}

// Options: add something useful to smem_cpu(data, n_read).
//   I didn't get to it.  But having this may help you test/debug your code
void smem_cpu(Gmem_data *data, int n_read)
{
    // write something here if you find it helpful
}

/* gmem_cpu(data, n_read)
 *   CPU version of gmem_fetch.
 *   Parameters:
 *     data: a Gmem_data object
 *     n_read: number of memory accesses for each "thread"
 */
void gmem_cpu(Gmem_data *data, int n_read)
{
    uint n = data->n, n_stride = data->n_threads();
    uint *v = data->v_host, *stride = data->stride_host, *sum = data->sum_host;
    for (uint my_idx = 0; my_idx < n_stride; my_idx++)
    { // for each "thread"
        uint my_stride = stride[my_idx];
        uint acc = 0;
        uint m = my_idx;
        for (uint j = 0; j < n_read; j++)
        {
            acc += v[m];
            m += my_stride;
            if (m >= n)
                m -= n;
        }
        sum[my_idx] = acc;
    }
}

__global__ void gmem_dummy(uint *x, int n)
{
    uint my_idx = blockDim.x * blockIdx.x + threadIdx.x;
    if (my_idx < n)
        x[my_idx] = 0;
}

// measure the kernel execution time.
float mem_time(Gmem_data *data, int n_read, int which_test)
{
    cudaEvent_t kernelStart, kernelStop;
    CudaTry(cudaEventCreate(&kernelStart));
    CudaTry(cudaEventCreate(&kernelStop));

    // Even with the call to cudaDeviceSynchronize() below, the invocation of a
    // kernel seems to take extra time, presumably to finish the big Memcpy's.
    // I'm adding a dummy kernel launch to make sure we really have a clean
    // start for our timing measurements.
    uint x;
    gmem_dummy<<<data->n_blk, data->threads_per_block>>>(data->sum_dev, data->n_threads());
    cudaMemcpy(&x, data->sum_dev, sizeof(uint), cudaMemcpyDeviceToHost);
    CudaTry(cudaDeviceSynchronize());

    CudaTry(cudaEventRecord(kernelStart));

    // launch the kernel
    if (which_test == GMEM_TEST)
    {
        gmem_fetch<<<data->n_blk, data->threads_per_block>>>(data->v_dev, data->n, data->stride_dev, data->sum_dev, n_read);
    }
    else
    {
        smem_fetch<<<data->n_blk, data->threads_per_block, data->threads_per_block * sizeof(uint)>>>(data->v_dev, data->n, data->stride_dev, data->sum_dev, n_read);
    }

    CudaTry(cudaGetLastError());
    CudaTry(cudaEventRecord(kernelStop));

    // cudaEventSynchronize waits for the all existing events in the CUDA stream to complete
    CudaTry(cudaEventSynchronize(kernelStop));

    float kernelMilliseconds = 0.0f;
    CudaTry(cudaEventElapsedTime(&kernelMilliseconds, kernelStart, kernelStop));
    return (kernelMilliseconds / 1000.0);
}

float gmem_time(Gmem_data *data, int n_read)
{
    return (mem_time(data, n_read, GMEM_TEST));
}

void print_time(double t)
{
    if (t < 1.0e-3)
        printf("Kernel execution time: %.4f microseconds\n", 1.0e6 * t);
    else if (t < 1.0)
        printf("Kernel execution time: %.4f milliseconds\n", 1.0e3 * t);
    else
        printf("Kernel execution time: %.4f seconds\n", t);
}

bool mem_test(Gmem_data *data, int n_read, int which_test)
{
    if (which_test == GMEM_TEST)
    {
        if (data->n_threads() > data->n)
        {
            fprintf(stderr,
                    "mem_test(...): please be reasonable %s\n",
                    "and have at most one thread per element of v");
            fprintf(stderr,
                    "n = %u, n_threads = %d, n_blocks = %d, threads_per_block = %d\n",
                    data->n, data->n_threads(), data->n_blk, data->threads_per_block);
            exit(-1);
        }
        gmem_fetch<<<data->n_blk, data->threads_per_block>>>(data->v_dev, data->n, data->stride_dev, data->sum_dev, n_read);
    }
    else
    {
        if (data->threads_per_block > data->n)
        {
            fprintf(stderr, "mem_test(...): please be reasonable and have at most %s\n",
                    "one thread_per_block per element of v");
            fprintf(stderr,
                    "n = %u, threads_per_block = %d\n",
                    data->n, data->threads_per_block);
            exit(-1);
        }
        smem_fetch<<<data->n_blk, data->threads_per_block>>>(data->v_dev, data->n, data->stride_dev, data->sum_dev, n_read);
    }
    uint sum_size = data->n_threads() * sizeof(uint);
    uint *sum_from_dev = (uint *)malloc(sum_size);
    CudaTry(cudaMemcpy(sum_from_dev, data->sum_dev, sum_size, cudaMemcpyHostToDevice));
    if (which_test == GMEM_TEST)
    {
        gmem_cpu(data, n_read);
    }
    else
    {
        smem_cpu(data, n_read);
    }
    bool outcome = true; // innocent until proven guilty
    for (int i = 0; i < data->n_threads(); i++)
    {
        if (sum_from_dev[i] != data->sum_host[i])
        {
            printf("gmem_test: sum_from_dev[%d] = %u != sum_host[%d] = %u\n",
                   i, sum_from_dev[i], i, data->sum_host[i]);
            outcome = false;
            break;
        }
    }
    free(sum_from_dev);
    return (outcome);
}

bool gmem_test(Gmem_data *data, int n_read)
{
    return (mem_test(data, n_read, GMEM_TEST));
}
