#!/bin/bash

#################################################
# Script to compile XIOS2.5
#################################################
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

cd $XIOS_DIR

# set compile architecture and export compilers
if [[ $system == archer2 ]]; then
 export CC=cc export CXX=CC export FC=ftn export F77=ftn export F90=ftn
 rsync -a $CODE_DIR/archer2-files/xios/* $XIOS_DIR/arch/
else
 export CC=mpiicx export CXX=mpiicpx export FC=mpiifx export F77=mpiifx export F90=mpiifx
fi

# Build xios

cd $XIOS_DIR && ./make_xios --prod --arch $XIOS_ARCH --netcdf_lib netcdf4_par --job 16 --full
rsync -a $XIOS_DIR/bin $XIOS_DIR/inc $XIOS_DIR/lib $XIOS_BUILD

cd $WORK
