#!/bin/bash

mm=$(printf '%02d' $month)

outdir=$OUTPUT_DIR/$EXP_NAME/$year/$mm
mkdir -p $outdir
echo "$SLURM_JOB_ID Submitting year/month" $year/$month >> $outdir/jobs.log

# Set namelists
iter_start=$((($(date -u -d "$year""$mm"01 +%s) - $(date -u -d "$START_YEAR"0101 +%s))/$dt))
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

if [ "$year" != "$START_YEAR" ] || [ "$month" != "1" ]; then 
    COLD_START=false
fi

$SCRIPTS_DIR/core-scripts/update_nemo_nl --phy_file $RUN_DIR/namelist_cfg  \
    --runid $NAME                 \
    --restart true            \
    --next_step $iter_start           \
    --final_step $iter_end          \
    --restart_file ${NAME}_${year}${mm}01_restart \
    --trc_file $RUN_DIR/namelist_top_cfg  \
    --trc_restart_file ${NAME}_${year}${mm}01_restart_trc
if [ $ICE = true ] ; then
    $SCRIPTS_DIR/core-scripts/update_nemo_nl \
    --ice_file $RUN_DIR/namelist_ice_cfg  \
    --ice_restart_file ${NAME}_${year}${mm}01_restart_ice
fi
if [ $COLD_START = true ]; then
    $SCRIPTS_DIR/core-scripts/update_nemo_nl --phy_file $RUN_DIR/namelist_cfg  \
    --restart false
fi

# Launch Run
echo "Launching $year $month at $(date +'%F %T')"
$RUN_DIR/runscript.slurm

# Archiving
mkdir -p $outdir
rsync -a fabm.yaml fabm_input.nml namelist* $outdir
mv *.output $outdir
mv $NAME*nc $outdir
#for f in $NAME*nc; do
#  ncks -4 -L6 $f $outdir/$f
#  rm -f $f
#done

