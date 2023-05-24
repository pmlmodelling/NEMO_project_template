#!/bin/bash
#SBATCH --job-name=$jobname
#SBATCH --time=$time
#SBATCH --account=$account
#SBATCH --partition=$partition
#SBATCH --qos=$qos

#SBATCH --nodes=$nodes
#SBATCH --ntasks-per-core=$ntaskspc

# SUBMIT WITH: sbatch --export=year=XXXX --export=month=YYYYY cycle.slurm

export OMP_NUM_THREADS=1
source ../code/archer2-files/ucx_env
source set_environment.sh

if [ ! -d $RUN_DIR ]; then
    $CYCLE_DIR/setup_initial.sh
fi

$CYCLE_DIR/setup_year.sh $year

cd $RUN_DIR
dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

if $YEARLY; then
    for month in 0{1..9} {10..12}; do#
        ./submit_job.sh
    done
    if $CLEAN_RESTART; then
        rm -f $RUN_DIR/restarts/$NAME_${year}0[2-9]*.nc
        rm -f $RUN_DIR/restarts/$NAME_${year}1*.nc
    fi
    month=01
    year=$(($year + 1))
else
    ./submit_job.sh 
    if [month != 12]; then
        month=$(($month + 1))
    else
        if $CLEAN_RESTART; then
            rm -f $RUN_DIR/restarts/$NAME_${year}0[2-9]*.nc
            rm -f $RUN_DIR/restarts/$NAME_${year}1*.nc
        fi
        month=01
        year=$(($year + 1))
    fi
fi

if [ $year -le $END_YEAR ]; then
    echo 'Submitting' $year $month '...'
    cd $CYCLE_DIR
    sbatch --export=year=$year --export=month=$month cycle.slurm
    echo "Done."
else
    echo "All done."
fi
