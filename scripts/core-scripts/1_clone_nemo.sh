#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

NEMO_REV=sinking_rate
git clone -b $NEMO_REV https://github.com/pmlmodelling/NEMO4.0-FABM.git $NEMO_DIR


