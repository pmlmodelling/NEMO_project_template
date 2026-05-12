#!/bin/bash
#SBATCH --job-name=AMM7-cycle
#SBATCH --time=01:00:00
#SBATCH --exclusive
#SBATCH --output=./log/slurm-%j.out

#SBATCH --nodes=8
#SBATCH --ntasks-per-core=1

source ../../scripts/core-scripts/scylla_modules

export OMP_NUM_THREADS=1
source config.sh

# Check if year and month provided
if [ -f $RUN_DIR/current_date ]; then
   source $RUN_DIR/current_date
fi
if [ -z $year ]; then
   export year=$START_YEAR
fi
if [ -z $month ]; then
   export month=1
fi

#Setup run
if [ ! -d $RUN_DIR ]; then
    $SCRIPTS_DIR/input-scripts/setup_initial.sh
fi

$SCRIPTS_DIR/input-scripts/setup_year.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

for (( i=1; i<=$N_sub_months; i++ ));
do
    export outdir=$OUTPUT_DIR/$EXP_NAME/$year/$(printf '%02d' $month)
    $SCRIPTS_DIR/core-scripts/submit_job.sh
    # Check run completed successfully
    if grep -q "TRACER STAT" "$outdir/ocean.output"; then
      RUN_STATUS=true
    else
      RUN_STATUS=false
      break
    fi
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
        $SCRIPTS_DIR/input-scripts/setup_year.sh $year
    fi
done

# Check run completed successfully and increment stored date
if [ $RUN_STATUS == "true" ]; then
    cd $RUN_DIR
cat > $RUN_DIR/current_date <<EOF
export year=$year
export month=$month
EOF
else
    echo "Cycle did not complete."
    exit 1
fi

# Submit next cycle
if [ $year -le $END_YEAR ] && [ $RUN_STATUS == "true" ]; then
    echo "Submitting $year $month at $(date +'%F %T')"
    sbatch $RUN_DIR/runscript_cycle.slurm
else
    echo "All done."
fi
