#!/bin/bash

WORK="$(dirname "$PWD")"
echo "Setting up AMM7 on ARCHER2"

yes | rsync -a $WORK/scripts/core-scripts/config.sh $WORK/scripts/config.sh
$WORK/scripts/core-scripts/update_config --cfg_file $WORK/scripts/config.sh  \
    --xios_arch X86_ARCHER2-Cray                 \
    --nemo_arch X86_ARCHER2-Cray_FABM                 \
    --fabm_compiler ftn                \
    --modules $WORK/scripts/core-scripts/archer2_modules \
    --archer2 true \
    --work_dir $WORK

source $WORK/scripts/config.sh

echo "Linking runscripts"
yes | rsync -a $SCRIPTS_DIR/core-scripts/runscript_archer2_14nodes.slurm $SCRIPTS_DIR/runscript.slurm

yes | rsync -a $WORK/RUN/EXP00/runscripts/runscript_archer2_14node.slurm $WORK/RUN/EXP00/runscript.slurm
yes | rsync -a $WORK/RUN/EXP00/runscripts/runscript_testing_archer2_14nodes.slurm $WORK/RUN/EXP00/runscript_testing.slurm

echo "Linking inputs from /work/n01/n01/shared/AMM7-INPUTS"
ln -s -T /work/n01/n01/shared/AMM7-INPUTS $INPUT_DIR
