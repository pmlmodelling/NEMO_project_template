#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

NEMO_REV=a83ab4cec06bf4302c6873d4f094228955819ca4
git clone https://github.com/pmlmodelling/NEMO4.0-FABM.git $NEMO_DIR
cd $NEMO_DIR && git checkout $NEMO_REV

