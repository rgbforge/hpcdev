#!/bin/bash -e

show_help() {
    echo "usage: source $(basename "$BASH_SOURCE") [OPTION]"
    echo "options:"
    echo "  --help: help message"
    return 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR=$(dirname $(dirname "${SCRIPT_DIR}"))
LIB_DIR="$PARENT_DIR/lib"
mkdir -p "$LIB_DIR"

FFTW_SOURCE_DIR="$LIB_DIR/fftw-3.3.10"
FFTW_INSTALL_DIR="$LIB_DIR/fftw-3.3.10/install_fftw"
FFTW_BUILD_DIR="$LIB_DIR/fftw-3.3.10/build_fftw"


if [ ! -d "$FFTW_SOURCE_DIR" ]; then
  echo "fftw doesn't exist in '$LIB_DIR', downloading fftw..."
  wget -P "$LIB_DIR" "http://www.fftw.org/fftw-3.3.10.tar.gz"
  tar -C "$LIB_DIR" -zxvf "$LIB_DIR/fftw-3.3.10.tar.gz"
else
  echo "fftw exists in '$LIB_DIR', skipping download..."
fi

if [ -d "$FFTW_INSTALL_DIR" ]; then
    echo "fftw already installed, delete $FFTW_INSTALL_DIR and $FFTW_BUILD_DIR"
    return 0
fi

config_options=(
    CFLAGS='-O3 -DNDEBUG -fPIC'
    --prefix=${FFTW_INSTALL_DIR}
    --enable-mpi
    --enable-threads
    --enable-openmp
    #--enable-avx
    #--enable-avx2
    #--enable-avx512
)

# have to mkdir/cd because their configure doesn't provide build_dir
current_dir=$(pwd)
mkdir -p "$FFTW_BUILD_DIR"
cd "$FFTW_BUILD_DIR"
# double precision configure
"$FFTW_SOURCE_DIR/configure" "${config_options[@]}"

echo "building double precision fftw..."
make -C "$FFTW_BUILD_DIR" -j"$num_jobs"

echo "installing double precision fftw..."
make -C "$FFTW_BUILD_DIR" install

# cleanup before installing single precision
make distclean

# single precision option
config_options+=(
    --enable-float
)

# single precision configure
"$FFTW_SOURCE_DIR/configure" "${config_options[@]}"

echo "building single precision fftw..."
make -C "$FFTW_BUILD_DIR" -j"$num_jobs"

echo "installing single precision fftw..."
make -C "$FFTW_BUILD_DIR" install

make distclean
cd "$current_dir"

echo "fftw installation complete"
