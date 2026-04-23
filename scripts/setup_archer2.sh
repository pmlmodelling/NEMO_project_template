#!/bin/bash

WORK="$(dirname "$PWD")"
echo "Setting up AMM7 on ARCHER2"

yes | rsync -a $WORK/scripts/core-scripts/config.sh $WORK/scripts/config.sh
$WORK/scripts/core-scripts/update_config --cfg_file $WORK/scripts/config.sh  \
    --xios_arch X86_ARCHER2-Cray                 \
    --nemo_arch X86_ARCHER2-Cray_FABM                 \
    --fabm_compiler ftn                \
    --modules $WORK/scripts/core-scripts/archer2_modules \
    --system archer2 \
    --work_dir $WORK

source $WORK/scripts/config.sh

echo "Linking inputs from /work/n01/n01/shared/AMM7-INPUTS"
ln -s -T /work/n01/n01/shared/AMM7-INPUTS $INPUT_DIR
