#!/bin/bash
source config.sh

year=$START_YEAR
month=1

while getopts :c clean; do
  case ${clean} in
    c) 
      echo "Cleaning "$RUN_DIR
      rm -rf $RUN_DIR
      ;;
  esac
done

echo "Creating Run Directory and linking domain files"
if [ ! -d $RUN_DIR ]; then
    $SCRIPTS_DIR/core/setup_initial.sh
fi

echo "Linking forcing files for "$year
$SCRIPTS_DIR/core/setup_year.sh $year


cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

iter_start=`cat $RUN_DIR/current_iter` #get iteration number
nday=`cal $month $year | grep -v '[A-Za-z]' | wc -w`
iter_end=$(($iter_start + 86400*$nday/$dt))
iter_start=$(($iter_start + 1))

mm=$(printf '%02d' $month)

$SCRIPTS_DIR/core/update_nemo_nl --phy_file $RUN_DIR/namelist_cfg  \
    --runid $NAME                 \
    --restart true            \
    --next_step $iter_start           \
    --final_step $iter_end          \
    --restart_file ${NAME}_${year}${mm}01_restart \
    --trc_file $RUN_DIR/namelist_top_cfg  \
    --trc_restart_file ${NAME}_${year}${mm}01_restart_trc
if [ $ICE = true ] ; then
    $SCRIPTS_DIR/core/update_nemo_nl \
    --ice_file $RUN_DIR/namelist_ice_cfg  \
    --ice_restart_file ${NAME}_${year}${mm}01_restart_ice
fi
if [ $COLD_START = true ]; then
    $SCRIPTS_DIR/core/update_nemo_nl --phy_file $RUN_DIR/namelist_cfg  \
    --restart false
fi

cd $SCRIPTS_DIR
