#!/bin/bash

WORK="$(dirname "$PWD")"
echo "Setting up AMM7 on Scylla"

yes | rsync -a $WORK/scripts/core-scripts/config.sh $WORK/scripts/config.sh
$WORK/scripts/core-scripts/update_config --cfg_file $WORK/scripts/config.sh  \
    --xios_arch GCC_SCYLLA                 \
    --nemo_arch GCC_SCYLLA                 \
    --fabm_compiler mpif90                \
    --modules $WORK/scripts/core-scripts/scylla_modules \
    --system scylla \
    --work_dir $WORK

source $WORK/scripts/config.sh

echo "Linking inputs from /work/shared/AMM7-INPUTS"
ln -s -T /work/shared/AMM7-INPUTS $INPUT_DIR

echo "Copying XIOS code from /work/shared/xios"
rsync -a -r /work/shared/xios/* $XIOS_DIR

echo "Copying XIOS code from /work/shared/xios"
mkdir -p $EXECUTABLE_DIR
rsync -a /work/shared/rebuild_nemo.exe $EXECUTABLE_DIR
