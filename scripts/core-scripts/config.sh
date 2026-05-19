#!/bin/bash

#############################################################
#Config options

export WORK=/work/dapa/AMM7-Benchmark
export NAME=AMM7 #Experiment name (used as cn_exp in namelist_cfg)
export EXP_NAME=EXP_cycletest # Name for running directory, different to DEFAULT_RUN_DIR

export START_YEAR=1993 # Start year
export END_YEAR=2000 # End year 

export COLD_START=true # If true, do not use a physics restart file
export starting_iter=1 # starting iteration number
export CLEAN_RESTART=true # If true, remove all restart files after use except those for January of each year
export N_sub_months=1 # Number of months to submit on a single job submission 
export system=scylla # Name of the HPC system

##########################################################
# Model output options
#
# Default options: 
# Daily Physics: 1d_grid_T, 1d_grid_U, 1d_grid_V, 
# Daily BGC: 1d_ptrc_T
# Daily Mizer: 1d_mizer_fish
# Monthly Physics: 1m_grid_T, 1m_grid_U, 1m_grid_V
# Monthly BGC: 1m_ptrc_T, 1m_ptrc_diag_T, 1m_ptrc_budget_T
# Monthly Mizer: 1m_mizer_fish, 1m_mizer_f_pel, 1m_mizer_f_ben, 
#                1m_mizer_g_pel, 1m_mizer_g_ben, 1m_mizer_c_fish
export OUTPUT_FILES="1m_grid_T 1m_grid_U 1m_grid_V 1m_ptrc_T" 

##########################################################
# Add additional model components

export use_spectral=false
export use_mizer=false
export tracer_budget=false

# Create suffix for use with executables and default run directories
suffix=""
if [ $use_spectral = true ]; then
    suffix=${suffix}"_spectral"
fi
if [ $use_mizer = true ]; then
    suffix=${suffix}"_mizer"
fi
export suffix=$suffix

###########################################################
# Default directories

export DEFAULT_RUN_DIR=$WORK/RUN/EXP00${suffix}
export CODE_DIR=$WORK/code
export INPUT_DIR=$WORK/INPUTS
export OUTPUT_DIR=$WORK/OUTPUTS/
export SCRIPTS_DIR=$WORK/scripts
export RUN_DIR=$WORK/RUN/$EXP_NAME
export EXECUTABLE_DIR=$CODE_DIR/executables

# Code directories and compile options

export ERSEM_DIR=$CODE_DIR/ersem
export FABM_DIR=$CODE_DIR/fabm
export FABM_BUILD=$CODE_DIR/fabm-build
export FABM_COMPILER=mpif90
export NEMO_DIR=$CODE_DIR/nemo
export NEMO_CFG=AMM7_FABM_BENCHMARK$suffix
export NEMO_ARCH=GCC_SCYLLA
export XIOS_DIR=$CODE_DIR/xios
export XIOS_BUILD=$CODE_DIR/xios-build
export XIOS_ARCH=GCC_SCYLLA
export MIZER_DIR=$CODE_DIR/mizer
export SPECTRAL_DIR=$CODE_DIR/fabm-spectral

##########################################################
# HPC modules

export MODULES=$SCRIPTS_DIR/core-scripts/scylla_modules
source $MODULES
