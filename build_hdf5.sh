#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR=$(dirname $(dirname "${SCRIPT_DIR}"))
LIB_DIR="$PARENT_DIR/lib"
mkdir -p "$LIB_DIR"
HDF5_SOURCE_DIR="$LIB_DIR/hdf5"
HDF5_INSTALL_DIR="$LIB_DIR/hdf5/install_hdf5"
HDF5_BUILD_DIR="$LIB_DIR/hdf5/build_hdf5"

if [ ! -d "$HDF5_SOURCE_DIR" ]; then
  echo "hdf5 doesn't exist in '$LIB_DIR', downloading..."
  git clone --depth 1 https://github.com/HDFGroup/hdf5.git "$HDF5_SOURCE_DIR"
else
  echo "hdf5 exists in '$LIB_DIR', skipping download..."
fi


if [ -d "$HDF5_INSTALL_DIR" ]; then
    echo "hdf5 already installed, delete $HDF5_INSTALL_DIR and $HDF5_BUILD_DIR"
    return 0
fi

echo "CMake Options: ${cmake_options[@]}"
cmake_options=(
    -D CMAKE_INSTALL_PREFIX="$HDF5_INSTALL_DIR"
    -D CMAKE_BUILD_TYPE=Release
    -D HDF5_BUILD_FORTRAN=ON
    -D HDF5_ENABLE_PARALLEL=ON
    -D BUILD_TESTING=OFF
)
cmake "${cmake_options[@]}" -B "$HDF5_BUILD_DIR" -S "$HDF5_SOURCE_DIR"

echo "building hdf5..."
make -C "$HDF5_BUILD_DIR" -j"$num_jobs"

echo "installing hdf5..."
make -C "$HDF5_BUILD_DIR" install

echo "hdf5 installation complete"
