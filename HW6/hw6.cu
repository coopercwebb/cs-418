#include "hw6_lib.h"

/* usage mem n threads_per_block n_read coalesced measure_time             *
 *   Where                                                                 *
 *     n: number of words in the data array.                               *
 *          default 2^26                                                   *
 *     threads_per_block: number of threads in a block                     *
 *          default 256                                                    *
 *     n_read: number of global memory reads performed by each thread      *
 *          default 50,000                                                 *
 *     coalesced:                                                          *
 *         if "true" (actually, anthing that starts with 't'),             *
 *             we generate an access pattern where each global memory read *
 *             by each warp is coalesced;                                  *
 *         otherwise (e.g. if argv[4]="false") each warp performs reads    *
 *             that are (with high probability) not coalesced.             *
 *         default true                                                    *
 *     time_or_test:                                                       *
 *         if "test" (or anything that starts with "ti"),                  *
 *             we report the time it takes for the kernel to execute;      *
 *         otherwise, (e.g. if the argv[5]="test") we perform the          *
 *             computation on both the GPU and the CPU and compare the     *
 *             results.                                                    *
 *         default "time"                                                  *
 *    Notes:                                                               *
 *      If fewer than five arguments are provided, the omitted ones        *
 *          recieve their default values as described above.               *
 *      If "-" is given for an argument, that argument gets its default    *
 *          value.                                                         */
int main(int argc, char **argv)
{
    const char *opt_names[] =
        {"mem", "n", "n_block", "threads_per_block",
         "coalesced", "time_or_test"};
    uint n = get_int(argc, argv, opt_names, 1, 1 << 26);   // number of data elements in the data array
    int tpb = get_int(argc, argv, opt_names, 2, 256);      // number of threads per block
    int n_read = get_int(argc, argv, opt_names, 3, 50000); // number global memory reads performed by each thread
    bool coalesced = (argc < 5) || (argv[4][0] == '-') || (argv[4][0] == 't');
    bool measure_time = (argc < 6) || (argv[5][0] == '-') || (argv[5][0] == 't' && argv[5][1] == 'i');
    int n_blk;
    int n_dev; // number of available GPUs on this machine
    cudaDeviceProp prop;

    // find out our device properties
    CudaTry(cudaGetDeviceCount(&n_dev));
    if (n_dev == 0)
    {
        fprintf(stderr, "No GPU found.\n");
        exit(-1);
    }
    CudaTry(cudaGetDeviceProperties(&prop, 0));
    if (tpb > prop.maxThreadsPerBlock)
    {
        fprintf(stderr, "tpb too large.  tpb = %d,  max threads per block = %d\n",
                tpb, prop.maxThreadsPerBlock);
        exit(-1);
    }
    n_blk = prop.multiProcessorCount *
            min((prop.maxThreadsPerMultiProcessor / tpb), prop.maxBlocksPerMultiProcessor);

    // creat Gmem_data object
    ArrayInit s_init, v_init;
    int n_threads = n_blk * tpb;
    if (coalesced)
        ai_const(&s_init, n_threads);
    else
        ai_rand(&s_init, n_threads);
    ai_rand(&v_init, n);
    Gmem_data *data = new Gmem_data(n, n_blk, tpb, &s_init, &v_init);

    if (measure_time)
    {
        printf("n_threads: %d\n", n_threads);
        print_time(gmem_time(data, n_read));
    }
    else
        printf("The results%s match!\n", gmem_test(data, 4) ? "" : " don't");

    delete (data);
}
