#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

git clone https://github.com/pmlmodelling/NEMO4.2-FABM.git $NEMO_DIR
cd $NEMO_DIR && git checkout $NEMO_REV


