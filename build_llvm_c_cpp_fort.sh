#!/bin/bash -e

show_help() {
    echo "usage: source $(basename "$BASH_SOURCE") [OPTION]"
    echo "options:"
    echo "  --help"
    return 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLANG_VERSION="16.0.6"
LLVM_SOURCE_DIR="${SCRIPT_DIR}/llvm-project"
LLVM_BUILD_DIR="${SCRIPT_DIR}/llvm-project/build"
CLANG_INSTALL_DIR="${SCRIPT_DIR}/install_clang_${CLANG_VERSION}"


num_jobs=${num_jobs:-$(nproc || echo 1)}


if [ ! -d "$LLVM_SOURCE_DIR" ]; then
    echo "llvm(c,cpp,f) not found, cloning v.${CLANG_VERSION}..."
    git clone -b "llvmorg-${CLANG_VERSION}" --depth 1 https://github.com/llvm/llvm-project.git "$LLVM_SOURCE_DIR"
else
    echo "llvm(c,cpp,f) found in '$LLVM_SOURCE_DIR', skipping clone..."
fi


if [ -d "$CLANG_INSTALL_DIR" ]; then
    echo "clang found in '$CLANG_INSTALL_DIR', delete '$CLANG_INSTALL_DIR' and '$LLVM_BUILD_DIR'."
    return 0
fi

#-DLLVM_TARGETS_TO_BUILD="Native;SPIRV"
#-DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;flang;lld;lldb;mlir";libclc
cmake_options=(
    -DCMAKE_INSTALL_PREFIX=${CLANG_INSTALL_DIR}
    -DLLVM_ENABLE_ASSERTIONS=OFF
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_C_COMPILER=gcc
    -DCMAKE_CXX_COMPILER=g++
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;flang;lld;lldb;mlir"
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind;openmp"
    -DLLVM_BUILD_LLVM_DYLIB=ON
    -DLLVM_LINK_LLVM_DYLIB=ON
)


echo "configuring llvm(c,cpp,f)..."
mkdir -p "$LLVM_BUILD_DIR"
cd "$LLVM_BUILD_DIR"
cmake "${cmake_options[@]}" "$LLVM_SOURCE_DIR/llvm"

echo "building llvm(c,cpp,f)..."
make -j"$num_jobs"

echo "installing llvm(c,cpp,f)..."
make install

echo "llvm(c,cpp,f) installation complete"
echo "export PATH=${CLANG_INSTALL_DIR}/bin:\$PATH"
