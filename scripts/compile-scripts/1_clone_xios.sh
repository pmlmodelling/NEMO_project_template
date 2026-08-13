#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../config.sh

XIOS_REV=6bf6985e14279bf66a7c71b5d6076324723803cb
git clone -b XIOS2 https://gitlab.in2p3.fr/ipsl/projets/xios-projects/xios.git $XIOS_DIR
cd $XIOS_DIR && git checkout $XIOS_REV

