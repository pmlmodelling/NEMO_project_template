#!/bin/bash

# GENERATE runscript.slurm
# Put #SBATCH commands into cycle.slurm

outer_cycle_start=`$CYCLE_DIR/date.sh ${START_DATE[@]}`
end_date=`$CYCLE_DIR/date.sh ${END_DATE[@]}`

$CYCLE_DIR/setup_initial.sh
iter_start=0

while [ `date -d $outer_cycle_start +'%s'` -lt `date -d $end_date +'%s'` ]; do

    outer_cycle_end=`date -d "$outer_cycle_start + $(($SUB_CYCLES*${CYCLE_LEN[0]})) year + \
                                                   $(($SUB_CYCLES*${CYCLE_LEN[1]})) month + \
                                                   $(($SUB_CYCLES*${CYCLE_LEN[2]})) day" \
                                                   +'%Y-%m-%d'`

    if [ `date -d $outer_cycle_end +'%s'` -gt `date -d $end_date +'%s'` ]; then
      outer_cycle_end=$end_date

    fi

    cd $RUN_DIR
    sbatch ./cycle.slurm outer_cycle_start outer_cycle_end iter_start
    wait

    outer_cycle_start=$outer_cycle_end
done

