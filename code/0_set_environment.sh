#!/bin/bash

# Load modules
module load cray-hdf5-parallel/1.12.0.7
module load cray-netcdf-hdf5parallel/4.7.4.7
module load cmake
export ARCHER2=true

#Config options
export WORK=/path/to/project/dir
export CODE_DIR=$WORK/code

#XIOS options
export XIOS_CLONE=$CODE_DIR/xios
export XIOS_HOME=$CODE_DIR/xios-build
export CC=cc export CXX=CC export FC=ftn export F77=ftn export F90=ftn
export XIOS_ARCH=X86_ARCHER2-Cray

#ERSEM options
export ERSEM_CLONE=$CODE_DIR/ersem

#FABM options
export FABM_CLONE=$CODE_DIR/fabm
export FABM_BUILD=$CODE_DIR/fabm-build
export FABM_DEBUG=$CODE_DIR/fabm-debug

#NEMO options
export FABM_HOME=$FABM_BUILD 
export NEMO_DIR=$CODE_DIR/nemo
export NEMO_ARCH=X86_ARCHER2-Cray_FABM
export NEMO_REF=AMM7_FABM
export NEMO_CFG=PROJECT_NAME
