#!/bin/bash

# GENERATE runscript.slurm
# Put #SBATCH commands into cycle.slurm
source set_environment.sh

outer_cycle_start=`$CYCLE_DIR/date.sh ${START_DATE[@]}`
end_date=`$CYCLE_DIR/date.sh ${END_DATE[@]}`

if [[ $initialise == true ]]; then
  $CYCLE_DIR/setup_initial.sh
fi

while [ `date -d $outer_cycle_start +'%s'` -lt `date -d $end_date +'%s'` ]; do

    outer_cycle_end=`date -d "$outer_cycle_start + $(($SUB_CYCLES*${CYCLE_LEN[0]})) year + \
                                                   $(($SUB_CYCLES*${CYCLE_LEN[1]})) month + \
                                                   $(($SUB_CYCLES*${CYCLE_LEN[2]})) day" \
                                                   +'%Y-%m-%d'`

    if [ `date -d $outer_cycle_end +'%s'` -gt `date -d $end_date +'%s'` ]; then
      outer_cycle_end=$end_date
    fi

    cd $RUN_DIR
    sbatch -W -t $time -J $jobname -A $account -p $partition -q $qos -N $nodes --ntasks-per-core=$ntaskspc \
                    $CYCLE_DIR/cycle_inner.slurm $CYCLE_DIR/set_environment.sh \
                                $outer_cycle_start $outer_cycle_end
    wait

    outer_cycle_start=$outer_cycle_end
done

