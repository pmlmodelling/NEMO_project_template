#!/bin/bash

#################################################
# Script to compile XIOS2.5
#################################################
source ../config.sh
XIOS_DIR=$CODE_DIR/xios
export XIOS_BUILD=$CODE_DIR/xios-build
cd $XIOS_DIR

# set compile architecture and export compilers
ARCH=X86_ARCHER2-Cray
export CC=cc export CXX=CC export FC=ftn export F77=ftn export F90=ftn
yes | cp $CODE_DIR/archer2-files/xios/arch-X86_ARCHER2-Cray* $XIOS_DIR/arch/
yes | cp $CODE_DIR/archer2-files/xios/Config_cray.pm $XIOS_DIR/tools/FCM/lib/Fcm/Config.pm

# Build xios

cd $XIOS_DIR && ./make_xios --prod --arch $ARCH --netcdf_lib netcdf4_par --job 16 --full
rsync -a $XIOS_DIR/bin $XIOS_DIR/inc $XIOS_DIR/lib $XIOS_BUILD

cd $WORK
