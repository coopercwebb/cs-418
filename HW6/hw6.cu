#include "hw6_lib.h"

#define V_SH_DIM 1024 // size of v_sh array (in shared memory)

/* usage mem n threads_per_block n_read coalesced measure_time which_test  *
 *   Where                                                                 *
 *     n: number of words in the data array.                               *
 *          default: 2^26, if which_test==1                                *
 *                   2^10, otherwise.                                      *
 *     threads_per_block: number of threads in a block                     *
 *          default: 256                                                   *
 *     n_read: number of global/shared memory reads performed by each      *
 *          default: 50,000                                                *
 *     coalesced_or_conflict_free:                                         *
 *         if "true" (actually, anthing that starts with 't'),             *
 *             we generate an access pattern where each global memory read *
 *             by each warp is coalesced, or where shared memory accesses  *
 *             are conflict free;                                          *
 *         otherwise (e.g. if argv[4]="false") each warp performs reads    *
 *             that are (with high probability) non-coalesced global       *
 *             memory accesses or conflicting shared memory accesses.      *
 *         default: true.                                                  *
 *         See which_test below to see how to specify whether the test     *
 *           is for global memory accesses being coalesced, or for shared  *
 *           memory accesses having conflicts.                             *
 *     time_or_test:                                                       *
 *         if "time" (or anything that starts with "ti"),                  *
 *             we report the time it takes for the kernel to execute;      *
 *         otherwise, (e.g. if the argv[5]="test") we perform the          *
 *             computation on both the GPU and the CPU and compare the     *
 *             results.                                                    *
 *         default: "time"                                                 *
 *     which_test:                                                         *
 *       If which_test = gmem (or anything that starts with "g" or "G",    *
 *         we perform the kernel for coalesced (or not) global memory      *
 *         accesses;                                                       *
 *       otherwise (e.g. if argv[6]=="smem"), we perform the time or       *
 *         kernel for shared memory accesses.                              *
 *         conflicting (or not) shared memory accesses.                    *
 *       default: 1, i.e. global memory access experiments.                *
 *    Notes:                                                               *
 *      If fewer than six arguments are provided, the omitted ones         *
 *          recieve their default values as described above.               *
 *      If "-" is given for an argument, that argument gets its default    *
 *          value.                                                         */
int main(int argc, char **argv)
{
    // read our command line parameters
    const char *opt_names[] =
        {"mem", "n", "threads_per_block", "n_read",
         "coalesced", "time_or_test",
         "which_test"};
    if (argc > 1 && strcmp(argv[1], "--help") == 0)
    {
        printf("usage: %s", argv[0]);
        for (int i = 1; i < 7; i++)
            printf(" %s", opt_names[i]);
        printf("\n");
        exit(0);
    }
    int tpb = get_int(argc, argv, opt_names, 2, 256);      // number of threads per block
    int n_read = get_int(argc, argv, opt_names, 3, 50000); // number global memory reads performed by each thread
    bool coalesced = (argc < 5) || (argv[4][0] == '-') || (argv[4][0] == 't');
    bool measure_time = (argc < 6) || (argv[5][0] == '-') || (argv[5][0] == 't' && argv[5][1] == 'i');
    int which_test;
    if ((argc < 7) || (argv[6][0] == '-') ||
        (argv[6][0] == 'g') || (argv[6][0] == 'G'))
    {
        which_test = GMEM_TEST;
    }
    else
    {
        which_test = SMEM_TEST;
    }
    int default_n;
    if (which_test == GMEM_TEST)
    {
        // Make a *big* array in the global memory.
        // IIRC, student accounts have a limit of 1GByte of memory per process.
        // 2^26*sizeof(int) is (1/4)GByte.  That should be safe.
        default_n = 1 << 26;
    }
    else
    { // shared memory conflict tests
        // make an array that's big enough to make conflict tests easy,
        // and small enough that we can have many blocks running on an SM to
        // ensure full thread-occupancy.  An SM has 100KBytes (1024 byte KBytes)
        // of shared memory and can execute at most 16 blocks, see Table 30 in
        //   https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html
        // That means each block can be guaranteed 6400 bytes, which is 1600 ints.
        // We'll set default n to 1024 = 2^10, the largest power of 2 that is <= 1600.
        default_n = 1 << 10;
    }
    printf("which_test = %d, GMEM_TEST = %d, SMEM_TEST = %d\n", which_test, GMEM_TEST, SMEM_TEST);
    uint n = get_int(argc, argv, opt_names, 1, default_n);

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

    // create a Gmem_data object
    ArrayInit s_init, v_init;
    int n_threads = n_blk * tpb;
    if ((which_test == GMEM_TEST) && coalesced)
    {
        ai_const(&s_init, n_threads);
        ai_rand(&v_init, n);
    }
    else if ((which_test == GMEM_TEST) && !coalesced)
    {
        ai_rand(&s_init, n_threads);
        ai_rand(&v_init, n);
    }
    else if (which_test == SMEM_TEST)
    {
        ai_rand(&v_init, n);
        if (n > V_SH_DIM)
        {
            fprintf(stderr, "the data array size, n, must be at most %d, got %d\n",
                    V_SH_DIM, n);
            exit(-1);
        }
        if (coalesced)
        {
            ai_const(&s_init, 1);
        }
        else
        {
            ai_rand(&s_init, n);
        }
    }
    else
    {
        fprintf(stderr, "bad value from which_test, %d,  -- how did that happen?!\n",
                which_test);
        exit(-1);
    }
    Gmem_data *data = new Gmem_data(n, n_blk, tpb, &s_init, &v_init);

    // run the test
    if (measure_time)
    {
        print_time(mem_time(data, n_read, which_test));
    }
    else
    {
        int n_read_test = 4; // should be enough to catch bugs, and should run fast
        bool passed = mem_test(data, n_read_test, which_test);
        ;
        printf("The results%s match!\n", passed ? "" : " don't");
    }

    // clean up
    delete (data);
    exit(0);
}
