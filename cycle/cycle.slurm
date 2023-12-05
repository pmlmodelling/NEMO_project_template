#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --time=01:30:00
#SBATCH --account=n01-PML
#SBATCH --partition=standard
#SBATCH --qos=standard

#SBATCH --nodes=12
#SBATCH --ntasks-per-core=1

# SUBMIT WITH: sbatch --export=year=YYYY,month=M cycle.slurm

export OMP_NUM_THREADS=1
source set_environment.sh


if [ ! -d $RUN_DIR ]; then
    $CYCLE_DIR/setup_initial.sh
fi

$CYCLE_DIR/setup_year.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

if [ $YEARLY = true ]; then
    for month in {1..12}; do
        $CYCLE_DIR/submit_job.sh
    done
    if [ $CLEAN_RESTART = true ] ; then
        echo 'Cleaning all restarts except January for '$year
        rm -f $RUN_DIR/restarts/${NAME}_${year}0[2-9]*.nc
        rm -f $RUN_DIR/restarts/${NAME}_${year}1*.nc
    fi
    month=1
    year=$(($year + 1))
else
    $CYCLE_DIR/submit_job.sh 
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
    fi
fi

if [ $year -le $END_YEAR ]; then
    echo 'Submitting' $year $month '...'
    cd $CYCLE_DIR
    sbatch --export=year=$year,month=$month $CYCLE_DIR/cycle.slurm
    echo "Done."
else
    echo "All done."
fi
