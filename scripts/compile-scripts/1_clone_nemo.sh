#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

NEMO_REV=8819de21b78f59d44bfbfa95c0be97c72b88b3e7
git clone https://github.com/pmlmodelling/NEMO4.0-FABM.git $NEMO_DIR
cd $NEMO_DIR && git checkout $NEMO_REV


