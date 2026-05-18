#!/bin/bash
  
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

# Clone code bases for ERSEM, FABM
ERSEM_REV=combined
git clone https://github.com/pmlmodelling/ersem-neccton.git $ERSEM_DIR
cd $ERSEM_DIR && git checkout $ERSEM_REV

FABM_REV=2178e4198586578664ca8db21b508c52cf5d3b83
git clone https://github.com/fabm-model/fabm.git $FABM_DIR
cd $FABM_DIR && git checkout $FABM_REV

#MIZER
git clone https://github.com/pmlmodelling/fabm-mizer.git $MIZER_DIR
cd $MIZER_DIR && git checkout NECCTON
