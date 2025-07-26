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
                echo "Error: Invalid --kokkos_build_type specified."
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
MATAR_SOURCE_DIR="$LIB_DIR/MATAR"
MATAR_INSTALL_DIR="$LIB_DIR/MATAR/install_MATAR_$kokkos_build_type"
MATAR_BUILD_DIR="$LIB_DIR/MATAR/build_MATAR_$kokkos_build_type"
KOKKOS_INSTALL_DIR="${LIB_DIR}/kokkos/install_kokkos_$kokkos_build_type"

if [ ! -d "$MATAR_SOURCE_DIR" ]; then
  echo "matar doesn't exist in '$LIB_DIR', downloading matar..."
  git clone --depth 1 https://github.com/lanl/MATAR.git "$MATAR_SOURCE_DIR"
else
  echo "matar exists in '$LIB_DIR', skipping download..."
fi

cmake_options=(
    -D CMAKE_INSTALL_PREFIX="${MATAR_INSTALL_DIR}"
    -D CMAKE_PREFIX_PATH="${KOKKOS_INSTALL_DIR}"
)

if [ "$kokkos_build_type" = "none" ]; then
    cmake_options+=(
        -D Matar_ENABLE_KOKKOS=OFF
    )
else
    cmake_options+=(
        -D Matar_ENABLE_KOKKOS=ON
    )
fi


cmake "${cmake_options[@]}" -B "${MATAR_BUILD_DIR}" -S "${MATAR_SOURCE_DIR}"
echo "building matar..."
make -C ${MATAR_BUILD_DIR} -j"$num_jobs"

echo "installing matar..."
make -C ${MATAR_BUILD_DIR} install

echo "matar installation complete"
