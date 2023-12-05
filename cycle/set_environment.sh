#!/bin/bash

#Config options
export WORK=/work/n01/n01/<uname>/<project>
export NAME=<NAME> #Experiment name (used as cn_exp in namelist_cfg)
export EXP_NAME=EXPXX # Name for running directory

export START_YEAR=1993 # Start year
export END_YEAR=1993 # End year 
# START_MONTH and END_MONTH are ignored when using `cycle_year.sh`
export START_MONTH=1 # Start month
export END_MONTH=12 # End month
export starting_iter=1 # starting iteration number
export ICE=false # If ice is in the model, will update namelist_ice files with restart filename
export YEARLY=true # If true, submit full year on a single job (adjust run time below accordingly)
export CLEAN_RESTART=true # If true, remove all restart files after use except those for January of each year

#Run options - SBATCH configuration - PUT AT THE TOP OF cycle.slurm
#export time=01:00:00
#export jobname=$NAME
#export account=n01-PML # Update with correct account code
#export partition=standard
#export qos=standard
#export nodes=12
#export ntaskspc=1

# Default directories
export DEFAULT_RUN_DIR=$WORK/RUN/EXP00
export EXECUTABLE_DIR=$WORK/code/executable
export INPUT_DIR=$WORK/INPUTS
export OUTPUT_DIR=$WORK/OUTPUTS
export CYCLE_DIR=$WORK/cycle
export RUN_DIR=$WORK/RUN/$EXP_NAME
source $EXECUTABLE_DIR/build_env

