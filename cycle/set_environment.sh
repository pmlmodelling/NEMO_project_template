#!/bin/bash

#Config options
export WORK=/work/n01/n01/<uname>/<project>
export NEMO_CFG=<NAME> # Name given to the compiled nemo code
export NAME=<NAME> #Experiment name (used as cn_exp in namelist_cfg)
export EXP_NAME=EXPXX # Name for running directory
export RUN_DIR=$WORK/RUN/$EXP_NAME

export START_DATE=(1993 1 1) # Start date (year month day)
export END_DATE=(1993 12 31) # End date (year month day)
export CYCLE_LEN=(0 1 0) # (years months days), recommended to only use 1 unit
export SUB_CYCLES=1 #Integer, number of cycles per job submission
export starting_iter=1 # starting iteration number
export initialise=true # Determine whether to initialis

#Run options - SBATCH configuration
export time=01:00:00
export jobname=$NAME
export account=n01-PML
export partition=standard
export qos=standard
export nodes=12
export ntaskspc=1

# Default directories
export DEFAULT_RUN_DIR=$WORK/RUN/EXP00
export INPUT_DIR=$WORK/INPUTS
export OUTPUT_DIR=$WORK/OUTPUTS
export CYCLE_DIR=$WORK/cycle

