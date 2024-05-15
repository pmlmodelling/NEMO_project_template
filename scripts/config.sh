#!/bin/bash

#Config options
export WORK=/work/n01/n01/<uname>/<project>
export NAME=AMM7 #Experiment name (used as cn_exp in namelist_cfg)
export EXP_NAME=EXPXX # Name for running directory, different to DEFAULT_RUN_DIR
export account=n01-PML

export START_YEAR=2005 # Start year
export END_YEAR=2010 # End year 
export YEARLY=true # If true, submit full year on a single job 
# START/END_MONTH ignored when running yearly
export START_MONTH=1 # Start month
export END_MONTH=12 # End month

export COLD_START=false # If true, do not use a physics restart file
export starting_iter=1 # starting iteration number
export ICE=false # If ice is in the model, will update namelist_ice files with restart filename
export CLEAN_RESTART=true # If true, remove all restart files after use except those for January of each year

# Default directories
export DEFAULT_RUN_DIR=$WORK/RUN/EXP00
export CODE_DIR=$WORK/code
export INPUT_DIR=$WORK/INPUTS
export OUTPUT_DIR=$WORK/OUTPUTS
export SCRIPTS_DIR=$WORK/scripts
export RUN_DIR=$WORK/RUN/$EXP_NAME
export EXECUTABLE_DIR=$CODE_DIR/executables

export ERSEM_DIR=$CODE_DIR/ersem
export FABM_DIR=$CODE_DIR/fabm
export FABM_BUILD=$CODE_DIR/fabm-build
export NEMO_DIR=$CODE_DIR/nemo
export NEMO_CFG=AMM7_FABM_BENCHMARK
export XIOS_DIR=$CODE_DIR/xios
export XIOS_BUILD=$CODE_DIR/xios-build
