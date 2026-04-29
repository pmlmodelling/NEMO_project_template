#!/bin/bash
source ./config.sh

# Check if year and month provided
if [ -f $SCRIPTS_DIR/current_date ]; then
   source $SCRIPTS_DIR/current_date
fi
if [ -z $year ]; then
   export year=$START_YEAR
fi
if [ -z $month ]; then
   export month=1
fi

while getopts :c clean; do
  case ${clean} in
    c) 
      echo "Cleaning "$RUN_DIR
      rm -rf $RUN_DIR
      ;;
  esac
done

echo "Creating Run Directory"
echo "Linking executables"
echo "Linking domain and tidal files"
if [ ! -d $RUN_DIR ]; then
    $SCRIPTS_DIR/input-scripts/setup_initial.sh
    rsync -a config.sh $RUN_DIR/config.sh
    if [ -f $SCRIPTS_DIR/current_date ]; then
       rsync -a $SCRIPTS_DIR/current_date $RUN_DUR/current_date
    fi
fi

echo "Linking forcing files for "$year
$SCRIPTS_DIR/input-scripts/setup_year.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

iter_start=$((($(date -d "$year"0101 +%s) - $(date -d "$START_YEAR"0101 +%s))/$dt))
# Calculate number of days in run
if [ "$YEARLY" = true ] ; then
    nday=`cal $year | grep -v '[A-Za-z]' | wc -w`
    iter_end=$(($iter_start + 86400*$(($nday-1))/$dt))
else
    nday=`cal $month $year | grep -v '[A-Za-z]' | wc -w`
    iter_end=$(($iter_start + 86400*$nday/$dt))
fi
iter_start=$(($iter_start + 1))

mm=$(printf '%02d' $month)

echo "Creating namelists"
$SCRIPTS_DIR/core-scripts/update_nemo_nl --phy_file $RUN_DIR/namelist_cfg  \
    --runid $NAME                 \
    --restart true                   \
    --euler false            \
    --tide_ramp false        \
    --next_step $iter_start           \
    --final_step $iter_end          \
    --restart_file ${NAME}_${year}${mm}01_restart \
    --trc_file $RUN_DIR/namelist_top_cfg  \
    --trc_restart_file ${NAME}_${year}${mm}01_restart_trc
if [ $COLD_START = true ]; then
    $SCRIPTS_DIR/core-scripts/update_nemo_nl --phy_file $RUN_DIR/namelist_cfg  \
    --restart false           \
    --euler true            \
    --tide_ramp true
fi

echo "Linking runscripts"
yes | rsync -a $SCRIPTS_DIR/submission-scripts/runscript_cycle_$system.slurm $RUN_DIR/runscript_cycle.slurm
yes | rsync -a $SCRIPTS_DIR/submission-scripts/runscript_mapping_$system.sh $RUN_DIR/runscript_mapping.sh
yes | rsync -a $SCRIPTS_DIR/submission-scripts/runscript_testing_$system.slurm $RUN_DIR/runscript_testing.slurm

cd $RUN_DIR
