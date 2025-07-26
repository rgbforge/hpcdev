#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

read -p "enter your nvhpc modpath (e.g. nvhpc/xx.yy): " nvmodpath


usage(){ echo "Usage: $0 -b [hdf5|netcdf|gklib|metis|parmetis|scotch|all]"; exit 1; }

BUILD_HDF5=false
BUILD_NETCDF=false
BUILD_GKLIB=false
BUILD_METIS=false
BUILD_PARMETIS=false
BUILD_SCOTCH=false

[ $# -eq 0 ] && usage
while getopts ":b:" opt; do
  case ${opt} in
    b)
      case ${OPTARG} in
        hdf5)     BUILD_HDF5=true ;;
        netcdf)   BUILD_NETCDF=true ;;
        gklib)    BUILD_GKLIB=true ;;
        metis)    BUILD_METIS=true ;;
        parmetis) BUILD_PARMETIS=true ;;
        scotch)   BUILD_SCOTCH=true ;;
        all)      BUILD_HDF5=true; BUILD_NETCDF=true; BUILD_GKLIB=true; BUILD_METIS=true; BUILD_PARMETIS=true; BUILD_SCOTCH=true ;;
        *) usage ;;
      esac ;;
    \?|:) usage ;;
  esac
done

module load $nvmodpath

export CC=nvc
export CXX=nvc++
export FC=nvfortran
export F77=nvfortran
export F90=nvfortran

export MPICC=mpicc
export MPICXX=mpicxx
export MPIFC=mpifort

export INSTALL_DIR="$(pwd)/install"
mkdir -p "${INSTALL_DIR}"

if $BUILD_HDF5 && [ ! -f "${INSTALL_DIR}/lib/libhdf5.so" ]; then
  echo "building hdf5..."
  ver="1.14.6"
  wget -nc -O "hdf5-${ver}.tar.gz" "https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_${ver}.tar.gz"
  rm -rf "hdf5-hdf5_${ver}" && tar -xf "hdf5-${ver}.tar.gz"
  cmake -S "hdf5-hdf5_${ver}" -B hdf5-build \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_C_COMPILER="${MPICC}" \
        -DCMAKE_Fortran_COMPILER="${MPIFC}" \
        -DHDF5_ENABLE_PARALLEL=ON -DHDF5_BUILD_FORTRAN=ON \
        -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build hdf5-build -j"$(nproc)"
  cmake --install hdf5-build
fi

if $BUILD_NETCDF && [ ! -f "${INSTALL_DIR}/lib/libnetcdf.so" ]; then
  echo "building netcdf-c and netcdf-fortran..."
  export LD_LIBRARY_PATH="${INSTALL_DIR}/lib:${LD_LIBRARY_PATH:-}"
  verC="4.9.3"
  wget -nc -O "netcdf-c-${verC}.tar.gz" "https://github.com/Unidata/netcdf-c/archive/refs/tags/v${verC}.tar.gz"
  rm -rf "netcdf-c-${verC}" && tar -xf "netcdf-c-${verC}.tar.gz"
  cmake -S "netcdf-c-${verC}" -B ncc-build \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_PREFIX_PATH="${INSTALL_DIR}" -DCMAKE_C_COMPILER="${MPICC}" \
        -DNETCDF_ENABLE_NETCDF_4=ON -DNETCDF_ENABLE_PARALLEL4=ON \
        -DBUILD_SHARED_LIBS=ON -DNETCDF_ENABLE_DAP=OFF -DCMAKE_BUILD_TYPE=Release
  cmake --build ncc-build -j"$(nproc)"
  cmake --install ncc-build

  export PKG_CONFIG_PATH="${INSTALL_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
  verF="4.6.1"
  wget -nc -O "netcdf-fortran-${verF}.tar.gz" "https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v${verF}.tar.gz"
  rm -rf "netcdf-fortran-${verF}" && tar -xf "netcdf-fortran-${verF}.tar.gz"
  cmake -S "netcdf-fortran-${verF}" -B ncf-build \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_PREFIX_PATH="${INSTALL_DIR}" -DCMAKE_Fortran_COMPILER="${MPIFC}" \
        -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build ncf-build -j"$(nproc)"
  cmake --install ncf-build
fi

if $BUILD_GKLIB && [ ! -f "${INSTALL_DIR}/lib/libGKlib.a" ]; then
  echo "building gtklib..."
  git clone --depth 1 https://github.com/KarypisLab/GKlib.git GKlib || true
  cmake -S GKlib -B gklib-build \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_C_COMPILER="${CC}" -DSHARED=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DOPENMP=ON
  cmake --build gklib-build -j"$(nproc)"
  cmake --install gklib-build
fi

if $BUILD_METIS && [ ! -f "${INSTALL_DIR}/lib/libmetis.so" ]; then
  echo "building metis..."
  export LD_LIBRARY_PATH="${INSTALL_DIR}/lib:${LD_LIBRARY_PATH:-}"
  git clone https://github.com/KarypisLab/METIS.git METIS || true
  cd METIS
  make distclean || true
  make config cc="${CC}" prefix="${INSTALL_DIR}" gklib_path="${INSTALL_DIR}" shared=1
  make -j"$(nproc)"
  make install
  cd ..
fi

if $BUILD_SCOTCH && [ ! -f "${INSTALL_DIR}/lib/libscotch.a" ]; then
  echo "building scotch..."
  ver="7.0.4"
  wget -nc -O "scotch-${ver}.tar.gz" \
       "https://gitlab.inria.fr/scotch/scotch/-/archive/v${ver}/scotch-v${ver}.tar.gz"
  rm -rf "scotch-v${ver}" && tar -xf "scotch-${ver}.tar.gz"

  export CFLAGS="-I${INSTALL_DIR}/include -fPIC -O3 ${CFLAGS:-}"
  export LDFLAGS="-L${INSTALL_DIR}/lib ${LDFLAGS:-}"
  export PKG_CONFIG_PATH="${INSTALL_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

  cmake -S "scotch-v${ver}" -B scotch-build \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_C_COMPILER="${CC}" \
        -DMPI_C_COMPILER="${MPICC}" \
        -DBUILD_PTSCOTCH=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DUSE_ZLIB=ON \
        -DTHREADS=ON \
        -DINSTALL_METIS_HEADERS=OFF

  cmake --build  scotch-build -j"$(nproc)"
  cmake --install scotch-build
fi

if $BUILD_PARMETIS && [ ! -f "${INSTALL_DIR}/lib/libparmetis.so" ]; then
  echo "building parmetis..."
  export LD_LIBRARY_PATH="${INSTALL_DIR}/lib:${LD_LIBRARY_PATH:-}"
  export CFLAGS="-I${INSTALL_DIR}/include"
  export LDFLAGS="-L${INSTALL_DIR}/lib"
  git clone https://github.com/KarypisLab/ParMETIS.git ParMETIS || true
  cd ParMETIS
  make distclean || true
  make config cc="${MPICC}" prefix="${INSTALL_DIR}" gklib_path="${INSTALL_DIR}" \
               metis_path="${INSTALL_DIR}" shared=1
  make -j"$(nproc)"
  make install
  cd ..
fi
echo "finished"
