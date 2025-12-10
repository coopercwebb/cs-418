#include "hw6_lib.h"

// Feel free to change V_SH_DIM if you want
#define V_SH_DIM 1024 // size of v_sh array (in shared memory)

/*****************************************************************************
 *                                                                           *
 * Here is template code for Q2.  I'm releasing it *very* late.  If you      *
 *   already did your own implementation, that's OK.  It doesn't have to     *
 *   fit this template.  It just needs to be documented well enough that     *
 *   we can understand what you did and why.                                 *
 *                                                                           *
 * If you use this template, there is one function you need to write for     *
 *   HW6, Q2:                                                                *
 *     smem_fetch(uint *v, uint n, uint *stride, uint *sum, int n_read)      *
 *   You also need to initialize data->stride to avoid (or create)           *
 *     shared memory bank conflicts.  Search for "you need to" in the main() *
 *     function, and you will find the code that needs to be filled in.      *
 *                                                                           */


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

/* I defined my own struct here.  See @351_f2.
struct foo { struct foo *next; }; */

__global__ void smem_fetch(uint *v, uint n, uint *stride, uint *sum, int n_read) {
    // you need to write this

    // You'll probably declare an array in shared memory here.

    // Then, you'll want to initialize the array.
    //   My solution uses values from v because it's bigger than stride.
    //   Other solutions are possible.

    // Each thread performs n_read loads from the shared memory array

    // Finally, write *something* to sum[my_idx].
    //   Otherwise, compiler optimizations can discard all of your shared
    //   memory reads!
}


// Options: add something useful to smem_cpu(data, n_read).
//   I didn't get to it.  But having this may help you test/debug your code
void smem_cpu(Gmem_data *data, int n_read) {
    // write something here if you find it helpful
}


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
int main(int argc, char **argv) {
    // read our command line parameters
    const char *opt_names[] =
        { "mem", "n", "threads_per_block", "n_read",
	  "coalesced", "time_or_test",
	  "which_test" };
    if(argc > 1 && strcmp(argv[1], "--help") == 0) {
        printf("usage: %s", argv[0]);
	for(int i = 1; i < 7; i++) 
            printf(" %s", opt_names[i]);
	printf("\n");
	exit(0);
    }
    int tpb = get_int(argc, argv, opt_names, 2, 256); // number of threads per block
    int n_read = get_int(argc, argv, opt_names, 3, 50000); // number global memory reads performed by each thread
    bool coalesced = (argc < 5) || (argv[4][0] == '-') || (argv[4][0] == 't');
    bool measure_time = (argc < 6) || (argv[5][0] == '-')
                                   || (argv[5][0] == 't' && argv[5][1] == 'i');
    int which_test;
    if( (argc < 7) || (argv[6][0] == '-') ||
            (argv[6][0] == 'g') || (argv[6][0] == 'G')) {
        which_test = GMEM_TEST;
    } else {
        which_test = SMEM_TEST;
    }
    int default_n;
    if(which_test == GMEM_TEST) {
      // Make a *big* array in the global memory.
      // IIRC, student accounts have a limit of 1GByte of memory per process.
      // 2^26*sizeof(int) is (1/4)GByte.  That should be safe.
      default_n = 1 << 26;
    } else { // shared memory conflict tests
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
    int n_dev;  // number of available GPUs on this machine
    cudaDeviceProp prop;

    // find out our device properties
    CudaTry(cudaGetDeviceCount(&n_dev));
    if(n_dev == 0) {
	fprintf(stderr, "No GPU found.\n");
	exit(-1);
    }
    CudaTry(cudaGetDeviceProperties(&prop, 0));
    if(tpb > prop.maxThreadsPerBlock) {
	fprintf(stderr, "tpb too large.  tpb = %d,  max threads per block = %d\n",
		tpb, prop.maxThreadsPerBlock);
	exit(-1);
    }
    n_blk = prop.multiProcessorCount *
	    min((prop.maxThreadsPerMultiProcessor/tpb), prop.maxBlocksPerMultiProcessor);

    // create a Gmem_data object
    ArrayInit s_init, v_init;
    int n_threads = n_blk*tpb;
    if((which_test == GMEM_TEST) && coalesced) {
	ai_const(&s_init, n_threads);
	ai_rand(&v_init, n);
    } else if((which_test == GMEM_TEST) && !coalesced) {
	ai_rand(&s_init, n_threads);
	ai_rand(&v_init, n);
    } else if(which_test == SMEM_TEST) {
	if((which_test == SMEM_TEST) && (n > V_SH_DIM)) {
	    fprintf(stderr, "the data array size, n, must be at most %d, got %d\n",
		    V_SH_DIM, n);
	    exit(-1);
	}
	ai_const(&s_init, 0);
	// Note: my solution initiales v_init to be used by my smem_fetch to create
	//   the desired access patterns.  My smem_fetch ignores the stride array
	//   and I just used ai_const(&s_init, 0) as a placeholder.
	if(coalesced) {
	    // You need to write this
	    fprintf(stderr, "You need to initialize the arrays data values and strides %s\n",
		    "to create shared-memory accesses without bank conflicts");
	    exit(-1);
	} else {
	    // You need to write this
	    fprintf(stderr, "You need to initialize the arrays data values and strides %s\n",
		    "to create shared-memory accesses with bank conflicts");
	    exit(-1);
	}
    } else {
	fprintf(stderr, "bad value from which_test, %d,  -- how did that happen?!\n",
	        which_test);
	exit(-1);
    }
    Gmem_data *data = new Gmem_data(n, n_blk, tpb, &s_init, &v_init);

    // run the test
    if(measure_time) {
	print_time(mem_time(data, n_read, which_test));
    } else {
	int n_read_test = 4;  // should be enough to catch bugs, and should run fast
        bool passed = mem_test(data, n_read_test, which_test);;
	printf("The results%s match!\n", passed ? "" : " don't");
    }

    // clean up
    delete(data);
    exit(0);
}

