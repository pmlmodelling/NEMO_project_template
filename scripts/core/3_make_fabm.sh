#!/bin/bash

################################################
# Build FABM
###############################################
source ../config.sh

FABM_FORTRAN_COMPILER=ftn

ERSEM_DIR=$CODE_DIR/ersem
FABM_DIR=$CODE_DIR/fabm
FABM_BUILD=$CODE_DIR/fabm-build

mkdir $FABM_BUILD
cd $FABM_BUILD
cmake $FABM_DIR/src -DFABM_HOST=nemo -DFABM_ERSEM_BASE=$ERSEM_DIR -DFABM_EMBED_VERSION=ON -DCMAKE_INSTALL_PREFIX=$FABM_BUILD -DCMAKE_Fortran_COMPILER=$FABM_FORTRAN_COMPILER
make
make install -j4

cd $WORK


