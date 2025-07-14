#!/bin/bash
  
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

# Clone code bases for ERSEM, FABM
ERSEM_REV=combined
git clone git@github.com:pmlmodelling/ersem-neccton.git $ERSEM_DIR
cd $ERSEM_DIR && git checkout $ERSEM_REV

FABM_REV=2178e4198586578664ca8db21b508c52cf5d3b83
git clone https://github.com/fabm-model/fabm.git $FABM_DIR
cd $FABM_DIR && git checkout $FABM_REV

#Clone spectral light
git clone -b rrs https://github.com/pmlmodelling/fabm-spectral.git $SPECTRAL_DIR
#cd $SPECTRAL_DIR && git checkout 


