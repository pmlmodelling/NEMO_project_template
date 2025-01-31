#!/bin/bash

WORK="$(dirname "$PWD")"
echo "Setting up AMM7 on Scylla"

$WORK/scripts/core-scripts/update_config --cfg_file $WORK/scripts/config.sh  \
    --xios_arch GCC_SCYLLA                 \
    --nemo_arch GCC_SCYLLA                 \
    --fabm_compiler mpif90                \
    --modules $WORK/scripts/core-scripts/scylla_modules \
    --work_dir $WORK

source $WORK/scripts/config.sh

echo "Linking runscripts"
yes | rsync -a $SCRIPTS_DIR/core-scripts/runscript_scylla.slurm $SCRIPTS_DIR/runscript.slurm

yes | rsync -a $WORK/RUN/EXP00/runscripts/runscript_scylla.slurm $WORK/RUN/EXP00/runscript.slurm
yes | rsync -a $WORK/RUN/EXP00/runscripts/runscript_testing_scylla.slurm $WORK/RUN/EXP00/runscript_testing.slurm

echo "Linking inputs from /work/shared/AMM7-INPUTS"
ln -s -T /work/shared/AMM7-INPUTS $INPUT_DIR

echo "Copying XIOS code from /work/shared/xios"
rsync -a -r /work/shared/xios/* $XIOS_DIR
