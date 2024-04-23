#!/bin/bash

outdir=$OUTPUT_DIR/$year/$mm
mkdir -p $outdir
echo "$SLURM_JOB_ID Submitting year/month" $year/$month >> $outdir/jobs.log

# Set namelists
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

# Launch Run
echo "Launching $year $month at $(date +'%F %T')"
#srun runscript.slurm
$RUN_DIR/runscript.slurm

# Archive results
mv $NAME*nc *.output $outdir
cp namelist* $outdir

echo $iter_end > $RUN_DIR/current_iter
