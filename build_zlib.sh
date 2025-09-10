#!/bin/bash -e
 
ZLIB_VERSION="1.3.1"
CURR_DIR="$(pwd)"
LIB_DIR="build"
mkdir -p "$LIB_DIR"
 
wget https://zlib.net/zlib-1.3.1.tar.gz
tar -xzvf zlib-1.3.1.tar.gz

cd  zlib-1.3.1

export CC="gcc"
export CFLAGS="-O3 -march=native -fPIC"
 
./configure --prefix="${CURR_DIR}/build"
make
make test
make install
 
cd $CURR_DIR
 
cat << EOF > test.c
#include <stdio.h>
#include <zlib.h>
 
int main(){
        printf("TEST zlib version %s\n", zlibVersion());
        return 0;
}
EOF
 
 
gcc test.c -o test -I$LIB_DIR/lib/install_zlib_1.3.1/include -L$LIB_DIR/lib/install_zlib_1.3.1/lib -lz
./test
