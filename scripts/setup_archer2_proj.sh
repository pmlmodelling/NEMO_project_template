#!/bin/bash

WORK="$(dirname "$PWD")"
echo "Setting up AMM7 on ARCHER2"
echo $WORK
MODEL=$1
SCENARIO=$2
if [[ $MODEL == '' ]]
then
	echo 'WARNING no model has been specified, setting to CNRM-ESM2'
	MODEL='CNRM-ESM2'
fi
if [[ $SCENARIO == '' ]]
then
	echo 'WARNING no scenario has been specified, setting to historical'
	SCENARIO='historical'
fi

yes | rsync -a $WORK/scripts/core-scripts/config.proj.sh $WORK/scripts/config.sh
$WORK/scripts/core-scripts/update_config --cfg_file $WORK/scripts/config.sh  \
    --xios_arch X86_ARCHER2-Cray                 \
    --nemo_arch X86_ARCHER2-Cray_FABM                 \
    --fabm_compiler ftn                \
    --modules $WORK/scripts/core-scripts/archer2_modules \
    --archer2 true \
    --model $MODEL \
    --scenario $SCENARIO \
    --work_dir $WORK

source $WORK/scripts/config.sh $MODEL

echo "Linking runscripts"
yes | rsync -a $SCRIPTS_DIR/core-scripts/runscript_archer2.proj.slurm $SCRIPTS_DIR/runscript.slurm

yes | rsync -a $WORK/RUN/EXP00/runscripts/mapping_archer2.slurm $WORK/RUN/EXP00/mapping.slurm
yes | rsync -a $WORK/RUN/EXP00/runscripts/mapping_testing_archer2.slurm.standard $WORK/RUN/EXP00/mapping_testing.slurm

echo "Linking inputs from /work/n01/n01/shared/AMM7-INPUTS"
ln -s -T /work/n01/n01/shared/AMM7-INPUTS-$MODEL $INPUT_DIR
