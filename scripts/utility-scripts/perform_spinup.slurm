#!/bin/bash 
#SBATCH --job-name=amm7_spinup
#SBATCH --time=04:00:00
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
# START_YEAR - starting year for the run, default 1993. If different to 1993
#		please update input-scripts/setup_initial.sh to link correct starting files
#
# N.B. The wallclock time for this script needs to be long enough to perform a simulation of length cycle_years
#
#########################################################################

source ../config.sh

# Set parameters
cycle_years=5 
cycle_repeat=5
START_YEAR=1993

# Update end year
END_YEAR=$(($START_YEAR + $cycle_years -1))

# Update config file
sed -i "/export EXP_NAME/c\\export EXP_NAME=EXP_spinup" $SCRIPTS_DIR/config.sh
sed -i "/START_YEAR/c\\export START_YEAR=$START_YEAR" $SCRIPTS_DIR/config.sh
sed -i "/END_YEAR/c\\export END_YEAR=$END_YEAR" $SCRIPTS_DIR/config.sh
source $SCRIPTS_DIR/config.sh

if [ -f $SCRIPTS_DIR/utility-scripts/current_cycle ]; then
   source $SCRIPTS_DIR/utility-scripts/current_cycle
else 
   cycle_iter=1
fi

# Setup run cycle_iter
$SCRIPTS_DIR/dry_run.sh -c

# Use restart from previous cycle
if [ $cycle_iter -gt 1 ]; then
   rm -f $RUN_DIR/restarts/AMM7_${START_YEAR}0101_restart_trc.nc
   ln -s $OUTPUT_DIR/EXP_spinup/AMM7_${START_YEAR}0101_restart_trc_cycle$(($cycle_iter-1)).nc $RUN_DIR/restarts/AMM7_${START_YEAR}0101_restart_trc.nc
fi

# Run cycle #cycle_iter
sed -i '/SBATCH/d' $RUN_DIR/runscript_cycle.sh
sed -i 's/outdir=$OUTPUT_DIR\/$EXP_NAME/outdir=$OUTPUT_DIR\/$EXP_NAME\/cycle'"$cycle_iter"'/' $RUN_DIR/runscript_cycle.slurm
$RUN_DIR/runscript_cycle.sh

# Rebuild restarts
if [ ! -f $SCRIPTS_DIR/input-scripts/rebuild_nemo.exe ]; then
    rsync -a $EXECUTABLE_DIR/rebuild_nemo.exe $SCRIPTS_DIR/input-scripts/
fi
nfiles=`ls $RUN_DIR/restarts/AMM7_$(($END_YEAR+1))0101_restart_trc*nc | wc -l`
./rebuild_nemo -p 8 $RUN_DIR/restarts/AMM7_$(($END_YEAR+1))0101_restart_trc $nfiles

# Reset date in restart file
restart_file=$OUTPUT_DIR/EXP_spinup/AMM7_${START_YEAR}0101_restart_trc_cycle${cycle_iter}.nc 
rsync -a $RUN_DIR/restarts/AMM7_$(($END_YEAR+1))0101_restart_trc.nc $restart_file
ncap2 -s "time_counter(:)=1; kt=0" -O $restart_file $restart_file

# Submit next cycle
cycle_iter=$(($cycle_iter + 1))
if [ $cycle_iter -le $cycle_repeat ]; then
    echo "Starting cycle "$cycle_iter
cat > $SCRIPTS_DIR/utility-scripts/current_cycle <<EOF
export cycle_iter=$cycle_iter
EOF
    sbatch $SCRIPTS_DIR/utility-scripts/perform_spinup.slurm
else
    echo "Spinup Complete"

