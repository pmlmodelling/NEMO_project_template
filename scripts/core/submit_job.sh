#!/bin/bash

mm=$(printf '%02d' $month)

outdir=$OUTPUT_DIR/$year/$mm
mkdir -p $outdir
echo "$SLURM_JOB_ID Submitting year/month" $year/$month >> $outdir/jobs.log

# Set namelists
iter_start=$((($(date -d "$year"0101 +%s) - $(date -d "$START_YEAR"0101 +%s))/$dt))
# Calculate number of days in run
if [ "$YEARLY" = true ] ; then
    nday=`cal $year | grep -v '[A-Za-z]' | wc -w`
    iter_end=$(($iter_start + 86400*$(($nday-1))/$dt))
else
    nday=`cal $month $year | grep -v '[A-Za-z]' | wc -w`
    iter_end=$(($iter_start + 86400*$nday/$dt))
fi

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

# Archiving
outdir=$OUTPUT_DIR/$year/$mm
mkdir -p $outdir
mv $NAME*nc *.output $outdir
cp namelist* $outdir

