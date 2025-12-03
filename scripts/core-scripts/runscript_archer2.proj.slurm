#!/bin/bash
#SBATCH --job-name=nemo_amm7cycle
#SBATCH --time=24:00:00
#SBATCH --account=n01-PML
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --output=./log/slurm-%j.out

#SBATCH --nodes=13
#SBATCH --ntasks-per-core=1

# SUBMIT WITH: sbatch runscript.slurm
# If starting from anything other than START_YEAR, month 1
# then run export year=XXXX and export month=X before submission

export OMP_NUM_THREADS=1
source config.sh

RUN_STATUS=true

# Check if year, month and nmonths are provided
if [ -f $SCRIPTS_DIR/current_date ]; then
   source $SCRIPTS_DIR/current_date
fi
if [ -z $year ]; then
   export year=$START_YEAR
fi
if [ -z $month ]; then
   export month=1
fi
if [ -z $N_sub_months ]; then
   export N_sub_months=1
fi

#Setup run
if [ ! -d $RUN_DIR ]; then
    $SCRIPTS_DIR/core-scripts/setup_initial.proj.sh
fi

$SCRIPTS_DIR/core-scripts/setup_year.proj.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step


for (( i=1; i<=$N_sub_months; i++ ));
do
    echo "Submitted month #$i"
    $SCRIPTS_DIR/core-scripts/submit_job.sh
    outdir=$OUTPUT_DIR/$EXP_NAME/$year/$(printf '%02d' $month)
    # Check run completed successfully
    if grep -q "TRACER STAT" "$outdir/ocean.output"; then
      RUN_STATUS=true
    else
      RUN_STATUS=false
      break
    fi
    # submit archiving outputs
     echo "archiving $outdir"
    sbatch $SCRIPTS_DIR/archive_dailyinorg.slurm $outdir
    sbatch $SCRIPTS_DIR/archive_dailyorg.slurm $outdir
    sbatch $SCRIPTS_DIR/archive_otheroutputs.slurm $outdir
    # Increment month 
    if [ $month != 12 ]; then
        month=$(($month + 1))
    else
        if [ $CLEAN_RESTART = true ] ; then
            echo 'Cleaning all restarts except January for '$year
            rm -f $RUN_DIR/restarts/${NAME}_${year}0[2-9]*.nc
            rm -f $RUN_DIR/restarts/${NAME}_${year}1*.nc
        fi
        month=1
        year=$(($year + 1))
        if [ $year -gt $END_YEAR ]; then break; fi
        $SCRIPTS_DIR/core-scripts/setup_year.proj.sh $year
    fi
done

# Submit next cycle if run completed successfully
if [ $year -le $END_YEAR ] && [ $RUN_STATUS == "true" ]; then
     echo "Submitting $year $month at $(date +'%F %T')"
     cd $SCRIPTS_DIR
cat > $SCRIPTS_DIR/current_date <<EOF
export year=$year
export month=$month
EOF
     sbatch $SCRIPTS_DIR/runscript.slurm
     echo "Done."
elif [ $year -le $END_YEAR ] && [ $RUN_STATUS = false ]; then
     echo "Cycle did not complete."
else
     echo "All done."
fi
