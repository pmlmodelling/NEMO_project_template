#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --time=00:30:00
#SBATCH --account=n01-PML
#SBATCH --partition=standard
#SBATCH --qos=standard

#SBATCH --nodes=12
#SBATCH --ntasks-per-core=1

# SUBMIT WITH: sbatch --export=year=YYYY,month=M cycle.slurm

export OMP_NUM_THREADS=1
source config.sh

# Check if year and month provided
if [ -z $year ]; then
   year=$START_YEAR
fi
if [ -z $month ]; then
   month=1
fi

#Setup run
if [ ! -d $RUN_DIR ]; then
    $SCRIPTS_DIR/core/setup_initial.sh
fi

$SCRIPTS_DIR/core/setup_year.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step



if [ $YEARLY = true ]; then
    for month in {1..12}; do
        $SCRIPTS_DIR/core/submit_job.sh
    done
    if [ $CLEAN_RESTART = true ] ; then
        echo 'Cleaning all restarts except January for '$year
        rm -f $RUN_DIR/restarts/${NAME}_${year}0[2-9]*.nc
        rm -f $RUN_DIR/restarts/${NAME}_${year}1*.nc
    fi
    month=1
    year=$(($year + 1))
else
    $SCRIPTS_DIR/core/submit_job.sh 
    if [ $month != 12 ]; then
        month=$(($month + 1))
    else
        if [ $CLEAN_RESTART = true ] ; then
            echo 'Cleaning all restarts except January for '$year
            cd $SCRIPTS_DIR
            sbatch --export=year=$year -A $account $CYCLE_DIR/clean_restarts.slurm
        fi
        month=1
        year=$(($year + 1))
    fi
fi

if [ $year -le $END_YEAR ]; then
    echo "Submitting $year $month at $(date +'%F %T')"
    cd $SCRIPTS_DIR
    sbatch --export=year=$year,month=$month $SCRIPTS_DIR/runscript.slurm
    echo "Done."
else
    echo "All done."
fi
