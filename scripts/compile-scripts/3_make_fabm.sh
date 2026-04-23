#!/bin/bash

################################################
# Build FABM
###############################################
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

modules="ersem"
options=""
if [ $use_spectral = true ]; then
    modules="${modules};spectral"
    options="${options} -DFABM_SPECTRAL_BASE=$SPECTRAL_DIR"
fi

if [ $use_mizer = true ]; then
    modules="${modules};mizer"
    options="${options} -DFABM_MIZER_BASE=$MIZER_DIR"
fi

mkdir -p $FABM_BUILD
cd $FABM_BUILD
cmake $FABM_DIR -DFABM_HOST=nemo -DFABM_INSTITUTES="$modules" -DFABM_ERSEM_BASE=$ERSEM_DIR -DFABM_EMBED_VERSION=ON -DCMAKE_INSTALL_PREFIX=$FABM_BUILD -DCMAKE_Fortran_COMPILER=$FABM_COMPILER $options
make
make install -j4

cd $WORK


