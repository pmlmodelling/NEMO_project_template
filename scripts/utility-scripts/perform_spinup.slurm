#!/bin/bash 
#SBATCH --job-name=amm7_spinup
#SBATCH --time=01:00:00
#SBATCH --nodes=8
#SBATCH --ntasks-per-core=1
#SBATCH --exclusive
#SBATCH --output=./spinup-log/slurm-%j.out

##########################################################################
# Slurm script to perform a BGC spinup by repeating a short run and
# reseting the initial BGC file with the file from the end of the run
# 
# Parameters to set:
# cycle_years - how many years to run before resetting
# cycle_repeat - how many times to repeat 
# spinup_start - starting year for the run, default 1993. 
# startfile - path to starting tracer restart file
# OUTPUT_FILES - list of output files, default just monthly tracer files
#
#########################################################################

if [ ! -f ./config.sh ]; then
  source ../config.sh
else
  source config.sh
fi

# Set parameters
cycle_years=5 
cycle_repeat=5
spinup_start=1993
startfile=$INPUT_DIR/DOM/19930101_restart_trc_from_obs.nc
OUTPUT_FILES="1m_ptrc_T" 

# Update end year
spinup_end=$(($spinup_start + $cycle_years -1))

if [ -f $SCRIPTS_DIR/utility-scripts/spinup-cycle ]; then
   source $SCRIPTS_DIR/utility-scripts/spinup-cycle
   source $RUN_DIR/current_date
   source $RUN_DIR/config.sh
   sed -i 's/cycle'"$(($cycle_iter-1))"'/cycle'"$cycle_iter"'/' $RUN_DIR/runscript_cycle.slurm
else 
   export cycle_iter=1
   export year=$spinup_start
   export month=1 

   # Update config file
   sed -i "/export EXP_NAME/c\\export EXP_NAME=EXP_spinup" $SCRIPTS_DIR/config.sh
   sed -i "/START_YEAR/c\\export START_YEAR=$spinup_start" $SCRIPTS_DIR/config.sh
   sed -i "/END_YEAR/c\\export END_YEAR=$spinup_end" $SCRIPTS_DIR/config.sh
   sed -i "/OUTPUT_FILES/c\\export OUTPUT_FILES=$OUTPUT_FILES" $SCRIPTS_DIR/config.sh
   source $SCRIPTS_DIR/config.sh
   cp $SCRIPTS_DIR/config.sh $SCRIPTS_DIR/utility-scripts/config.sh

   # Initial setup
   cd $SCRIPTS_DIR
   $SCRIPTS_DIR/dry_run.sh -c
   sed -i '/SBATCH/d' $RUN_DIR/runscript_cycle.slurm
   sed -i '/sbatch/d' $RUN_DIR/runscript_cycle.slurm
   sed -i 's/outdir=$OUTPUT_DIR\/$EXP_NAME/outdir=$OUTPUT_DIR\/$EXP_NAME\/cycle'"$cycle_iter"'/' $RUN_DIR/runscript_cycle.slurm
cat > $SCRIPTS_DIR/utility-scripts/spinup-cycle <<EOF
export cycle_iter=$cycle_iter
EOF
fi


# Use correct restart from previous cycle
if [ $year -eq $spinup_start ] && [ $month -eq 1 ]; then
    if [ $cycle_iter -eq 1 ]; then
       rm -f $RUN_DIR/restarts/AMM7_${spinup_start}0101_restart_trc.nc
       ln -s $startfile $RUN_DIR/restarts/AMM7_${spinup_start}0101_restart_trc.nc
    elif [ $cycle_iter -gt 1 ]; then
       rm -f $RUN_DIR/restarts/AMM7_${spinup_start}0101_restart_trc.nc
       ln -s $OUTPUT_DIR/EXP_spinup/AMM7_${spinup_start}0101_restart_trc_cycle$(($cycle_iter-1)).nc $RUN_DIR/restarts/AMM7_${spinup_start}0101_restart_trc.nc
    fi
fi

# Run cycle #cycle_iter
cd $RUN_DIR
$RUN_DIR/runscript_cycle.slurm
cd $SCRIPTS_DIR/utility-scripts

if [ $year -le $spinup_end ]; then
    sbatch $SCRIPTS_DIR/utility-scripts/perform_spinup.slurm
else 
    # Complete cycle
    cycle_iter=$(($cycle_iter + 1))
cat > $SCRIPTS_DIR/utility-scripts/spinup-cycle <<EOF
export cycle_iter=$cycle_iter
EOF
cat > $RUN_DIR/current_date <<EOF
export year=$spinup_start
export month=1
EOF
        # Rebuild restarts
        filebase=$RUN_DIR/restarts/AMM7_$(($spinup_end+1))0101_restart_trc
        $SCRIPTS_DIR/utility-scripts/rebuild_nemo $filebase

        # Reset date in restart file
	restart_file=${OUTPUT_DIR}EXP_spinup/AMM7_${spinup_start}0101_restart_trc_cycle$(($cycle_iter-1)).nc 
        rsync -a $filebase.nc $restart_file
        ncap2 -s "time_counter(:)=1; kt=0" -O $restart_file $restart_file
        
    if [ $cycle_iter -le $cycle_repeat ]; then
	# Submit next cycle
        echo "Starting cycle "$cycle_iter
	sbatch $SCRIPTS_DIR/utility-scripts/perform_spinup.slurm
    else
        echo "Spinup Complete"
    fi
fi
