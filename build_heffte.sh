#!/bin/bash -e

show_help() {
    echo "usage: source $(basename "$BASH_SOURCE") [OPTION]"
    echo "required:"
    echo "  --heffte_build_type=<fftw|cufft|rocfft>"
    echo " "
    echo "optional:"
    echo "  --build_fftw: builds fftw"
    echo "  --help"
    return 1
}


heffte_build_type=""
build_fftw=0
valid_heffte_build_types=("fftw" "cufft" "rocfft")

for arg in "$@"; do
    case "$arg" in
        --heffte_build_type=*)
            option="${arg#*=}"
            if [[ " ${valid_heffte_build_types[*]} " == *" $option "* ]]; then
                heffte_build_type="$option"
            else
                echo "error: invalid --heffte_build_type"
                show_help
                return 1
            fi
            ;;
        --build_fftw) 
            build_fftw=1
            ;;
        --help)
            show_help
            return 1
            ;;
        *)
            echo "error: invalid arg"
            show_help
            return 1
            ;;
    esac
done

if [ -z "$heffte_build_type" ]; then
    echo "error: --heffte_build_type is required"
    show_help
    return 1
fi



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR=$(dirname $(dirname "${SCRIPT_DIR}"))
LIB_DIR="$PARENT_DIR/lib"
mkdir -p "$LIB_DIR"
HEFFTE_SOURCE_DIR="$LIB_DIR/heffte"
HEFFTE_INSTALL_DIR="$LIB_DIR/heffte/install_heffte_$heffte_build_type"
HEFFTE_BUILD_DIR="$LIB_DIR/heffte/build_heffte_$heffte_build_type"


if [ "$heffte_build_type" = "fftw" ] && [ "$build_fftw" -eq 1 ]; then
  FFTW_INSTALL_SCRIPT="$PARENT_DIR/scripts/install_scripts/install_fftw.sh"
  source "$FFTW_INSTALL_SCRIPT" --num_jobs=$num_jobs
  FFTW_INSTALL_DIR="$LIB_DIR/fftw-3.3.10/install_fftw"
fi

if [ ! -d "$HEFFTE_SOURCE_DIR" ]; then
  echo "heffte doesn't exist in '$LIB_DIR', downloading..."
  git clone --depth 1 https://github.com/icl-utk-edu/heffte.git "$HEFFTE_SOURCE_DIR"
else
  echo "heffte exists in '$LIB_DIR', skipping download..."
fi

cmake_options=(
    -D CMAKE_BUILD_TYPE=Release
    -D CMAKE_INSTALL_PREFIX="$HEFFTE_INSTALL_DIR"
    -D BUILD_SHARED_LIBS=ON
)

if [ "$heffte_build_type" = "fftw" ]; then
    cmake_options+=(
        #-D Heffte_ENABLE_AVX=ON
        #-D Heffte_ENABLE_AVX512=ON
        -D Heffte_ENABLE_FFTW=ON
        #-D FFTW_ROOT="$FFTW_DIR"
    )
    if [ "$build_fftw" -eq 1 ]; then
      cmake_options+=(
        -D FFTW_ROOT="$FFTW_INSTALL_DIR"
      )
    fi
elif [ "$heffte_build_type" = "cufft" ]; then
    cmake_options+=(
        -D Heffte_ENABLE_CUDA=ON
        -D Heffte_DISABLE_GPU_AWARE_MPI=ON
    )
elif [ "$heffte_build_type" = "rocfft" ]; then
    cmake_options+=(
        -D CMAKE_CXX_COMPILER=hipcc
        -D Heffte_ENABLE_ROCM=ON
        -D Heffte_DISABLE_GPU_AWARE_MPI=ON
    )
fi

cmake "${cmake_options[@]}" -B "$HEFFTE_BUILD_DIR" -S "$HEFFTE_SOURCE_DIR"
echo "building heffte..."
make -C "$HEFFTE_BUILD_DIR" -j"$num_jobs"

echo "installing heffte..."
make -C "$HEFFTE_BUILD_DIR" install

echo "heffte installation complete"
