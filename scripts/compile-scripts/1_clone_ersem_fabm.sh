#!/bin/bash
  
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

# Clone code bases for ERSEM, FABM
ERSEM_REV=8510fbf80a4ef8b1f9f827e156531e9e0ce6315b
git clone https://github.com/pmlmodelling/ersem.git $ERSEM_DIR
cd $ERSEM_DIR && git checkout $ERSEM_REV

FABM_REV=2178e4198586578664ca8db21b508c52cf5d3b83
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

