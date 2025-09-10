#!/bin/bash -e

show_help() {
    echo "usage: source $(basename "$BASH_SOURCE") [OPTION]"
    echo "options:"
    echo "  --help"
    return 1
}

#intel options
export CC=icx
export CXX=icpx
export FC=ifx
export F77=ifx
export F90=ifx
export I_MPI_CC=icx
export I_MPI_CXX=icpx
export I_MPI_FC=ifx

#nvhpc or nvmpi options
#export CC=nvc
#export CXX=nvc++
#export FC=nvfortran
#export F77=nvfortran
#export F90=nvfortran



export MPICC=mpicc
export MPICXX=mpicxx
export MPIFC=mpifort



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR=$(dirname "${SCRIPT_DIR}")
LIB_DIR="$PARENT_DIR/lib"
mkdir -p "$LIB_DIR"
LIBXC_SOURCE_DIR="$LIB_DIR/libxc-7.0.0"
LIBXC_INSTALL_DIR="$LIB_DIR/install_libxc_7.0.0"
LIBXC_BUILD_DIR="$LIB_DIR/libxc-7.0.0/build_libxc"

if [ ! -d "$LIBXC_SOURCE_DIR" ]; then
    echo "libxc source not found in '$LIB_DIR', downloading..."
    wget -P "$LIB_DIR" "https://gitlab.com/libxc/libxc/-/archive/7.0.0/libxc-7.0.0.tar.gz"
    tar -C "$LIB_DIR" -zxvf "$LIB_DIR/libxc-7.0.0.tar.gz"
else
    echo "libxc found in '$LIB_DIR', skipping download..."
fi

if [ -d "$LIBXC_INSTALL_DIR" ]; then
    echo "libxc found in '$LIBXC_INSTALL_DIR', delete '$LIBXC_INSTALL_DIR' and '$LIBXC_BUILD_DIR'."
    return 0
fi

cmake_options=(
    -DCMAKE_INSTALL_PREFIX=${LIBXC_INSTALL_DIR}
    -DCMAKE_BUILD_TYPE=Release                
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON       
    -DBUILD_SHARED_LIBS=ON                     
    -DENABLE_FORTRAN=ON               
)

mkdir -p "$LIBXC_BUILD_DIR"
cd "$LIBXC_BUILD_DIR"
cmake "${cmake_options[@]}" "$LIBXC_SOURCE_DIR"

echo "building libxc..."
make

echo "installing libxc..."
make install

echo "libxc installation complete"
