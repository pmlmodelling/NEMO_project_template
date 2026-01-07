#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

git clone -b ebm https://github.com/pmlmodelling/NEMO4.0-FABM.git $NEMO_DIR

