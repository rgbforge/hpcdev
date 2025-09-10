BUILDPATH=$(pwd)

NCPUS=XX

mkdir $BUILDPATH/CMAKE
mkdir $BUILDPATH/CMAKE/install
cd $BUILDPATH/CMAKE

wget https://github.com/Kitware/CMake/archive/refs/tags/v3.30.9.tar.gz
tar xzf v3.30.9.tar.gz

cd CMake-3.30.9

CC=gcc CXX=g++ ./configure --prefix=$BUILDPATH/CMAKE/install --parallel=$NCPUS

make -j$NCPUS
make install
