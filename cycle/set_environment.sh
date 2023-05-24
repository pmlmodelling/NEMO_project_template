#!/bin/bash

#Config options
export WORK=/work/n01/n01/<uname>/<project>
export EXECUTABLE_DIR=$WORK/code/executable
export NAME=<NAME> #Experiment name (used as cn_exp in namelist_cfg)
export EXP_NAME=EXPXX # Name for running directory
export RUN_DIR=$WORK/RUN/$EXP_NAME

export START_YEAR=1993 # Start year
export END_YEAR=1993 # End year 
# START_MONTH and END_MONTH are ignored when using `cycle_year.sh`
export START_MONTH=01 # Start month
export END_MONTH=12 # End month
export starting_iter=1 # starting iteration number
export initialise=true # Determine whether to run setup_initial (true) or not (false) 

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

