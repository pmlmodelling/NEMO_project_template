!#/bin/slurm

echo "$SLURM_JOB_ID Submitting year/month" $year/$month >> $RUN_DIR/jobs.log

# Set namelists
iter_start=`cat $RUN_DIR/current_iter` #get iteration number
nday=`cal $month $year | grep -v '[A-Za-z]' | wc -w`
iter_end=$(($iter_start + 86400*$nday/$dt))
iter_start=$(($iter_start + 1))

$CYCLE_DIR/update_nemo_nl --file $RUN_DIR/namelist_cfg  \
    --runid $NAME                 \
    --restart true            \
    --next_step $iter_start           \
    --final_step $iter_end          \
    --restart_file ${NAME}_${year}${month}01_restart \
    --trc_file $RUN_DIR/namelist_top_cfg  \
    --trc_restart_file ${NAME}_${year}${month}01_restart_trc
if [$ICE]
    $CYCLE_DIR/update_nemo_nl \
    --ice_file $RUN_DIR/namelist_ice_cfg  \
    --ice_restart_file ${NAME}_${year}${month}01_restart_ice
fi
# Launch Run
echo "Launching $year $month at $(date +%s) seconds since 1970-01-01 00:00:00"
srun run_script.slurm

# Archive results
outdir=$OUTPUT_DIR/$year/$month
mkdir -p $outdir
mv $NAME*nc *.output $outdir
cp namelist* $outdir

echo $iter_end > $RUN_DIR/current_iter
