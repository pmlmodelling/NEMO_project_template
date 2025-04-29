#!/bin/bash 
#SBATCH --job-name=nemo_amm7cycle
#SBATCH --time=02:00:00
#SBATCH --nodes=8
#SBATCH --ntasks-per-core=1
#SBATCH --exclusive
#SBATCH --output=./log/slurm-%j.out

# SUBMIT WITH: sbatch runscript.slurm
# If starting from anything other than START_YEAR, month 1
# then run export year=XXXX and export month=X before submission

export OMP_NUM_THREADS=1
source config.sh

# Check if year and month provided
if [ -z $year ]; then
   export year=$START_YEAR
fi
if [ -z $month ]; then
   export month=1
fi

#Setup run
if [ ! -d $RUN_DIR ]; then
    $SCRIPTS_DIR/core-scripts/setup_initial.sh
fi

$SCRIPTS_DIR/core-scripts/setup_year.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step



if [ $YEARLY = true ]; then
    for month in {1..12}; do
        $SCRIPTS_DIR/core-scripts/submit_job.sh
    done
    if [ $CLEAN_RESTART = true ] ; then
        echo 'Cleaning all restarts except January for '$year
        rm -f $RUN_DIR/restarts/${NAME}_${year}0[2-9]*.nc
        rm -f $RUN_DIR/restarts/${NAME}_${year}1*.nc
    fi
    month=1
    year=$(($year + 1))
else
    $SCRIPTS_DIR/core-scripts/submit_job.sh 
    outdir=$OUTPUT_DIR/$EXP_NAME/$year/$(printf '%02d' $month)
    if [ $month != 12 ]; then
        month=$(($month + 1))
    else
        if [ $CLEAN_RESTART = true ] ; then
            echo 'Cleaning all restarts except January for '$year
            cd $SCRIPTS_DIR
#            sbatch --export=year=$year -A $account $CYCLE_DIR/clean_restarts.slurm
        fi
        month=1
        year=$(($year + 1))
    fi
fi

# Check run completed successfully
if grep -q "TRACER STAT" "$outdir/ocean.output"; then
  RUN_STATUS=true
else
  RUN_STATUS=false
fi

# Submit next cycle if run completed successfully
if [ $year -le $END_YEAR ] && [ $RUN_STATUS == "true" ]; then
    echo "Submitting $year $month at $(date +'%F %T')"
    cd $SCRIPTS_DIR
    export year=$year
    export month=$month
    sbatch $SCRIPTS_DIR/runscript.slurm
    echo "Done."
elif [ $year -le $END_YEAR ] && [ $RUN_STATUS = false ]; then
    echo "Cycle did not complete."
else
    echo "All done."
fi
