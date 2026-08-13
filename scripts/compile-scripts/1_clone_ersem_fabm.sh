#!/bin/bash
  
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

# Clone code bases for ERSEM, FABM
ERSEM_REV=8ee235834f81fc24835dea240ab3b22e3f0f76a3
git clone https://github.com/pmlmodelling/ersem.git $ERSEM_DIR
cd $ERSEM_DIR && git checkout $ERSEM_REV

FABM_REV=b5704dbc0d7bd40be745cbd588233e8c0ba48d2a
git clone https://github.com/fabm-model/fabm.git $FABM_DIR
cd $FABM_DIR && git checkout $FABM_REV

if [ $use_spectral = true ]; then
    #Clone spectral light
    git clone -b rrs https://github.com/pmlmodelling/fabm-spectral.git $SPECTRAL_DIR
fi

if [ $use_mizer = true ]; then
    #Clone mizer
    MIZER_REV=NECCTON
    git clone git@github.com:pmlmodelling/fabm-mizer.git $MIZER_DIR
    cd $MIZER_DIR && git checkout $MIZER_REV
fi

