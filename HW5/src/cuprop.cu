#include <stdio.h>
#include <math.h>

#ifdef HIDE
// cudaDeviceProp definition from
//   /cs/local/lib/pkg/cudatoolkit-11.0.3/include/driver_types.h
// line 1250 ff
struct __device_builtin__ cudaDeviceProp
{
    char   name[256];                  /**< ASCII string identifying device */
    size_t totalGlobalMem;             /**< Global memory available on device in bytes */
    size_t sharedMemPerBlock;          /**< Shared memory available per block in bytes */
    int    regsPerBlock;               /**< 32-bit registers available per block */
    int    warpSize;                   /**< Warp size in threads */
    size_t memPitch;                   /**< Maximum pitch in bytes allowed by memory copies */
    int    maxThreadsPerBlock;         /**< Maximum number of threads per block */
    int    maxThreadsDim[3];           /**< Maximum size of each dimension of a block */
    int    maxGridSize[3];             /**< Maximum size of each dimension of a grid */
    int    clockRate;                  /**< Clock frequency in kilohertz */
    size_t totalConstMem;              /**< Constant memory available on device in bytes */
    int    major;                      /**< Major compute capability */
    int    minor;                      /**< Minor compute capability */
    size_t textureAlignment;           /**< Alignment requirement for textures */
    size_t texturePitchAlignment;      /**< Pitch alignment requirement for texture references bound to pitched memory */
    int    deviceOverlap;              /**< Device can concurrently copy memory and execute a kernel. Deprecated. Use instead asyncEngineCount. */
    int    multiProcessorCount;        /**< Number of multiprocessors on device */
    int    kernelExecTimeoutEnabled;   /**< Specified whether there is a run time limit on kernels */
    int    integrated;                 /**< Device is integrated as opposed to discrete */
    int    canMapHostMemory;           /**< Device can map host memory with cudaHostAlloc/cudaHostGetDevicePointer */
    int    computeMode;                /**< Compute mode (See ::cudaComputeMode) */
    int    maxTexture1D;               /**< Maximum 1D texture size */
    int    maxTexture1DMipmap;         /**< Maximum 1D mipmapped texture size */
    int    maxTexture1DLinear;         /**< Maximum size for 1D textures bound to linear memory */
    int    maxTexture2D[2];            /**< Maximum 2D texture dimensions */
    int    maxTexture2DMipmap[2];      /**< Maximum 2D mipmapped texture dimensions */
    int    maxTexture2DLinear[3];      /**< Maximum dimensions (width, height, pitch) for 2D textures bound to pitched memory */
    int    maxTexture2DGather[2];      /**< Maximum 2D texture dimensions if texture gather operations have to be performed */
    int    maxTexture3D[3];            /**< Maximum 3D texture dimensions */
    int    maxTexture3DAlt[3];         /**< Maximum alternate 3D texture dimensions */
    int    maxTextureCubemap;          /**< Maximum Cubemap texture dimensions */
    int    maxTexture1DLayered[2];     /**< Maximum 1D layered texture dimensions */
    int    maxTexture2DLayered[3];     /**< Maximum 2D layered texture dimensions */
    int    maxTextureCubemapLayered[2];/**< Maximum Cubemap layered texture dimensions */
    int    maxSurface1D;               /**< Maximum 1D surface size */
    int    maxSurface2D[2];            /**< Maximum 2D surface dimensions */
    int    maxSurface3D[3];            /**< Maximum 3D surface dimensions */
    int    maxSurface1DLayered[2];     /**< Maximum 1D layered surface dimensions */
    int    maxSurface2DLayered[3];     /**< Maximum 2D layered surface dimensions */
    int    maxSurfaceCubemap;          /**< Maximum Cubemap surface dimensions */
    int    maxSurfaceCubemapLayered[2];/**< Maximum Cubemap layered surface dimensions */
    size_t surfaceAlignment;           /**< Alignment requirements for surfaces */
    int    concurrentKernels;          /**< Device can possibly execute multiple kernels concurrently */
    int    ECCEnabled;                 /**< Device has ECC support enabled */
    int    pciBusID;                   /**< PCI bus ID of the device */
    int    pciDeviceID;                /**< PCI device ID of the device */
    int    pciDomainID;                /**< PCI domain ID of the device */
    int    tccDriver;                  /**< 1 if device is a Tesla device using TCC driver, 0 otherwise */
    int    asyncEngineCount;           /**< Number of asynchronous engines */
    int    unifiedAddressing;          /**< Device shares a unified address space with the host */
    int    memoryClockRate;            /**< Peak memory clock frequency in kilohertz */
    int    memoryBusWidth;             /**< Global memory bus width in bits */
    int    l2CacheSize;                /**< Size of L2 cache in bytes */
    int    maxThreadsPerMultiProcessor;/**< Maximum resident threads per multiprocessor */
    int    streamPrioritiesSupported;  /**< Device supports stream priorities */
    int    globalL1CacheSupported;     /**< Device supports caching globals in L1 */
    int    localL1CacheSupported;      /**< Device supports caching locals in L1 */
    size_t sharedMemPerMultiprocessor; /**< Shared memory available per multiprocessor in bytes */
    int    regsPerMultiprocessor;      /**< 32-bit registers available per multiprocessor */
    int    managedMemory;              /**< Device supports allocating managed memory on this system */
    int    isMultiGpuBoard;            /**< Device is on a multi-GPU board */
    int    multiGpuBoardGroupID;       /**< Unique identifier for a group of devices on the same multi-GPU board */
};
#endif

int main(int argc, char **argv) {
    int ndev;
    cudaDeviceProp prop;
    cudaError_t err_code  = cudaGetDeviceCount(&ndev);
    if(err_code != cudaSuccess) {
      printf( "%s in cudGetDevicedCount\n", cudaGetErrorString( err_code ));
      ndev = 1;
    } else printf("This machine has %d CUDA device%s.\n", ndev, (ndev == 1) ? "" : "s");
    const char *indent = (ndev == 0) ? "" : "  ";
    for(int i = 0; i < ndev; i++) {
        cudaGetDeviceProperties(&prop, i);
        if(ndev > 0)
            printf("GPU %2d:\n", i);
        printf("%s%-20s = %12s; %s\n",  indent, "name", prop.name, "/**< ASCII string identifying device */");
        printf("%s%-20s = %d.%d; %s\n",  indent, "major.minor", prop.major, prop.minor, "/**< CUDA compute capability */");
        printf("%s%-20s = %12ld; %s\n", indent, "totalGlobalMem",  prop.totalGlobalMem, "/**< Global memory available on device in bytes */");
        printf("%s%-20s = %12ld; %s\n", indent, "sharedMemPerBlock", prop.sharedMemPerBlock, "/**< Shared memory available per block in bytes */");
        printf("%s%-20s = %12d; %s\n", indent, "regsPerBlock", prop.regsPerBlock, "/**< 32-bit registers available per block */");
        printf("%s%-20s = %12d; %s\n", indent, "regsPerMultiprocessor", prop.regsPerMultiprocessor, "/**< 32-bit registers available per SM */");
        printf("%s%-20s = %12d; %s\n", indent, "warpSize", prop.warpSize, "/**< Warp size in threads */");
        printf("%s%-20s = %12ld; %s\n", indent, "memPitch", prop.memPitch, "/**< Maximum pitch in bytes allowed by memory copies */");
        printf("%s%-20s = %12d; %s\n", indent, "maxThreadsPerBlock", prop.maxThreadsPerBlock, "/**< Maximum number of threads per block */");
        printf("%s%-20s = %12d; %s\n", indent, "maxThreadsPerMultiProcessor", prop.maxThreadsPerMultiProcessor, "/**< Maximum number of threads per SM */");
        printf("%s%-20s = {%d,%d,%d}; %s\n", indent, "maxThreadsDim[3]", prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2],
                "/**< Maximum size of each dimension of a block */");
        printf("%s%-20s = {%d,%d,%d}; %s\n",
	       indent, "maxGridSize[3]",
	       prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2],
               "/**< Maximum size of each dimension of a grid */");
        printf("%s%-20s = %12d; %s\n", indent, "clockRate", prop.clockRate, "/**< Clock frequency in kilohertz */");
        printf("%s%-20s = %12ld; %s\n", indent, "totalConstMem", prop.totalConstMem, "/**< Constant memory available on device in bytes */");
        printf("%s%-20s = %12d; %s\n", indent, "major", prop.major, "/**< Major compute capability */");
        printf("%s%-20s = %12d; %s\n", indent, "minor", prop.minor, "/**< Minor compute capability */");
        printf("%s%-20s = %12ld; %s\n", indent, "textureAlignment", prop.textureAlignment, "/**< Alignment requirement for textures */");
        printf("%s%-20s = %12ld; %s\n", indent, "texturePitchAlignment", prop.texturePitchAlignment, "/**< Pitch alignment requirement for texture references bound to pitched memory */");
        printf("%s%-20s = %12d; %s\n", indent, "multiProcessorCount", prop.multiProcessorCount, "/**< Number of multiprocessors on device */");
        printf("%s%-20s = %12d; %s\n", indent, "kernelExecTimeoutEnabled", prop.kernelExecTimeoutEnabled, "/**< Specified whether there is a run time limit on kernels */");
        printf("%s%-20s = %12d; %s\n", indent, "integrated", prop.integrated, "/**< Device is integrated as opposed to discrete */");
        printf("%s%-20s = %12d; %s\n", indent, "canMapHostMemory", prop.canMapHostMemory, "/**< Device can map host memory with cudaHostAlloc/cudaHostGetDevicePointer */");
        printf("%s%-20s = %12d; %s\n", indent, "l2CacheSize", prop.l2CacheSize, "/**< Size of L2 cache in bytes */");
    }
    exit(0);
}
