#CC should be gnu for gdr/ucx at the moment
#CXX should be gnu for gdr/ucx at the moment
#gdrcopy needs edit tests/Makefile to add -arch=sm_XX to exes nvcc target manually for gdrcopy_pplat, line 60 directly after $(NVCC)
#ucx needs edit test/apps/Makefile.am to add -arch=sm_XX to line 109 $NVCC target manually


BUILDPARENT="/home/user/"
NVHPC_HOME="/opt/nvhpc"
cd $BUILDPARENT/
mkdir nvmpi
cd nvmpi

mkdir gdr_install
mkdir ucx_install
mkdir mpi_install
mkdir bm_install
git clone https://github.com/openucx/ucx.git
git clone https://github.com/NVIDIA/gdrcopy.git
wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.8.tar.gz
tar -xzvf openmpi-5.0.8.tar.gz
wget https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-7.5.1.tar.gz
tar -xzvf osu-micro-benchmarks-7.5.1.tar.gz
 
GPUARCH=XX
CPUPROCS=YY
CUDAVER=ZZ

cd gdrcopy
make -j$YY prefix="$BUILDPARENT/nvmpi/gdr_install" CUDA="$NVHPC_HOME/cuda" driver lib
make -j$YY prefix="$BUILDPARENT/nvmpi/gdr_install" CUDA="$NVHPC_HOME/cuda" LDFLAGS="-lpthread -ldl -lrt -lgdrapi -lcuda" NVCCFLAGS="-arch=sm_XX" exes
make -j$YY prefix="$BUILDPARENT/nvmpi/gdr_install" install
 
 
cd ../ucx
./autogen.sh
 
NVCCFLAGS="-arch=sm_XX" LDFLAGS="-L$NVHPC_HOME/cuda/lib64 -L$BUILDPARENT/nvmpi/gdr_install/lib" \
LIBS="-lgdrapi -lcuda" \
./configure \
    --prefix="$BUILDPARENT/nvmpi/ucx_install" \
    --with-cuda="$NVHPC_HOME/cuda" \
    --with-gdrcopy="$BUILDPARENT/nvmpi/gdr_install" \
    --enable-mt
 
make -j$YY prefix="$BUILDPARENT/nvmpi/ucx_install" install
cd ../openmpi-5.0.8
NVCCFLAGS="-arch=sm_XX" ./configure  CC=$NVHPC_HOME/compilers/bin/nvc CXX=$NVHPC_HOME/compilers/bin/nvc++ --prefix=$BUILDPARENT/nvmpi/mpi_install --with-cuda=$NVHPC_HOME/cuda --enable-mca-dso=btl-smcuda,rcache-rgpusm,rcache-gpusm,accelerator-cuda --with-ucx=$BUILDPARENT/nvmpi/ucx_install --with-cuda-libdir=$NVHPC_HOME/cuda/$ZZ/lib64/stubs --with-gdrcopy="$BUILDPARENT/nvmpi/gdr_install"
make -j$YY prefix="$BUILDPARENT/nvmpi/mpi_install" install
 
 
cd ../osu-micro-benchmarks-7.5.1/
./configure CC=$BUILDPARENT/nvmpi/mpi_install/bin/mpicc \
            CXX=$BUILDPARENT/nvmpi/mpi_install/bin/mpicxx \
            --prefix=$BUILDPARENT/nvmpi/bm_install \
            --enable-cuda \
            --with-cuda-include=$NVHPC_HOME/cuda/include \
            --with-cuda-libpath=$NVHPC_HOME/cuda/lib64
 
make -j$YY prefix="$BUILDPARENT/nvmpi/bm_install" install
 
 
#export OPAL_PREFIX=$BUILDPARENT/nvmpi/mpi_install
#UCX_TLS=rc_x,cuda_copy,cuda_ipc,gdr_copy UCX_IB_GPU_DIRECT_RDMA=yes UCX_LOG_FILE=LOG.TXT UCX_LOG_LEVEL=DEBUG $BUILDPARENT/nvmpi/mpi_install/bin/mpirun -n 2 --map-by ppr:1:node:PE=1 --report-bindings $BUILDPARENT/nvmpi/bm_install/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bw -d cuda D D
