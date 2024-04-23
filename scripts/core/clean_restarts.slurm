#!/bin/bash
#SBATCH --job-name=CLEAN-RESTARTS
#SBATCH --time=01:00:00
#SBATCH --partition=standard
#SBATCH --qos=standard

#SBATCH --nodes=1
#SBATCH --ntasks-per-core=1

# SUBMIT WITH: sbatch --export=year=YYYY clean_restarts.slurm

export OMP_NUM_THREADS=1
source set_environment.sh

echo "$SLURM_JOB_ID Cleaning restarts for " $year >> $RUN_DIR/jobs.log
echo "Cleaning restarts for " $year

if [ $year != $START_YEAR ]; then
    echo "Tarring January Restarts for " $year
    tar -czvf $OUTPUT_DIR/$year/01/restarts.tar.gz $RUN_DIR/restarts/${NAME}_${year}01*.nc
fi
rm -f $RUN_DIR/restarts/${NAME}_${year}0[2-9]*.nc
rm -f $RUN_DIR/restarts/${NAME}_${year}1*.nc

echo "Done."
