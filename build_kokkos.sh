#!/bin/bash -e

show_help() {
    echo "usage: source $(basename "$BASH_SOURCE") [OPTION]"
    echo "options:"
    echo "  --kokkos_build_type=<serial|openmp|pthreads|cuda|hip>"
    echo "  --help"
    return 1
}


kokkos_build_type=""
num_jobs=1
valid_kokkos_build_types=("serial" "openmp" "pthreads" "cuda" "hip")
for arg in "$@"; do
    case "$arg" in
        --kokkos_build_type=*)
            option="${arg#*=}"
            if [[ " ${valid_kokkos_build_types[*]} " == *" $option "* ]]; then
                kokkos_build_type="$option"
            else
                echo "error: invalid --kokkos_build_type"
                show_help
                return 1
            fi
            ;;
        --help)
            show_help
            return 1
            ;;
        *)
            echo "error: invalid arg(s)"
            show_help
            return 1
            ;;
    esac
done

if [ -z "$kokkos_build_type" ]; then
    echo "error: --kokkos_build_type is required"
    show_help
    return 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR=$(dirname $(dirname "${SCRIPT_DIR}"))
LIB_DIR="$PARENT_DIR/lib"
mkdir -p "$LIB_DIR"
KOKKOS_SOURCE_DIR="$LIB_DIR/kokkos"
KOKKOS_INSTALL_DIR="$LIB_DIR/kokkos/install_kokkos_$kokkos_build_type"
KOKKOS_BUILD_DIR="$LIB_DIR/kokkos/build_kokkos_$kokkos_build_type"

if [ ! -d "$KOKKOS_SOURCE_DIR" ]; then
  echo "kokkos doesn't exist in '$LIB_DIR', downloading kokkos..."
  git clone --depth 1 https://github.com/kokkos/kokkos.git "$KOKKOS_SOURCE_DIR"
else
  echo "kokkos exists in '$LIB_DIR', skipping download..."
fi

cmake_options=(
    -D CMAKE_BUILD_TYPE=Release
    -D CMAKE_INSTALL_PREFIX="${KOKKOS_INSTALL_DIR}"
    -D CMAKE_CXX_STANDARD=17
    -D Kokkos_ENABLE_SERIAL=ON
    -D Kokkos_ARCH_NATIVE=ON
    -D Kokkos_ENABLE_TESTS=OFF
    -D BUILD_TESTING=OFF
)

if [ "$kokkos_build_type" = "openmp" ]; then
    cmake_options+=(
        -D Kokkos_ENABLE_OPENMP=ON
    )
elif [ "$kokkos_build_type" = "pthreads" ]; then
    cmake_options+=(
        -D Kokkos_ENABLE_THREADS=ON
    )
elif [ "$kokkos_build_type" = "cuda" ]; then
    cmake_options+=(
        -D Kokkos_ENABLE_CUDA=ON
        -D Kokkos_ENABLE_CUDA_CONSTEXPR=ON
        -D Kokkos_ENABLE_CUDA_LAMBDA=ON
        -D Kokkos_ENABLE_CUDA_RELOCATABLE_DEVICE_CODE=ON
    )
elif [ "$kokkos_build_type" = "hip" ]; then
    cmake_options+=(
        -D CMAKE_CXX_COMPILER=hipcc
        -D Kokkos_ENABLE_HIP=ON
        -D Kokkos_ENABLE_HIP_RELOCATABLE_DEVICE_CODE=ON
    )
fi

cmake "${cmake_options[@]}" -B "$KOKKOS_BUILD_DIR" -S "$KOKKOS_SOURCE_DIR"
echo "building kokkos..."
make -C "$KOKKOS_BUILD_DIR" -j"$num_jobs"

echo "installing kokkos..."
make -C "$KOKKOS_BUILD_DIR" install

echo "kokkos installation complete"
