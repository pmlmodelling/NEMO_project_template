#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

NEMO_REV= a6991353da8fcf4ac0a043ba0d0eddd87bc2386f
git clone https://github.com/pmlmodelling/NEMO4.0-FABM.git $NEMO_DIR
cd $NEMO_DIR && git checkout $NEMO_REV

