#!/bin/bash
source $1
inner_cycle_start=$2
outer_cycle_end=$3

dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

while [ `date -d $inner_cycle_start +'%s'` -lt `date -d $outer_cycle_end +'%s'` ]; do 
    iter_start=`cat $RUN_DIR/current_iter` #get iteration number
    inner_cycle_end=`date -d "$inner_cycle_start + ${CYCLE_LEN[0]} year + \
                                                   ${CYCLE_LEN[1]} month + \
                                                   ${CYCLE_LEN[2]} day" +'%Y-%m-%d'`; 
    if [ `date -d $inner_cycle_end +'%s'` -gt `date -d $outer_cycle_end +'%s'` ]; then
        inner_cycle_end=$outer_cycle_end;
    fi; 

    echo Setting up for cycle $inner_cycle_start to $inner_cycle_end
    #SETUP CYCLE
    year=`date -d "$inner_cycle_start" +'%Y'`
    $CYCLE_DIR/setup_year.sh $year

    # Calculate iteration numbers
    printf -v iter_start_zero "%08d" $iter_start # Padded 8digit number for restart files
    nday=$(( (`date -d $inner_cycle_end +%s` - `date -d $inner_cycle_start +%s`) / 86400 ))
    iter_end=$(python -c "print(int($iter_start + 86400*$nday/$dt))")     # 
    iter_start=$(( iter_start + 1 ))             # Starting iteration of cycle
    
    echo Updating namelist

    #Update namelist
    $CYCLE_DIR/update_nemo_nl --file $RUN_DIR/namelist_cfg  \
        --runid $NAME                 \
        --restart true            \
        --next_step $iter_start           \
        --final_step $iter_end          \
        --restart_file ${NAME}_${iter_start_zero}_restart \
        --trc_file $RUN_DIR/namelist_top_cfg  \
        --trc_restart_file ${NAME}_${iter_start_zero}_restart_trc
    if [ $iter_start -eq 1 ]; then
        $CYCLE_DIR/update_nemo_nl --file $RUN_DIR/namelist_cfg  \
        --restart false
    fi
    
    echo Submitting Run
    ./runscript.slurm
    
    # Archive data 
    echo Archiving
    outdir=${OUTPUT_DIR}/$year/${inner_cycle_start}_${inner_cycle_end}
    mkdir -p $outdir
    mv $NAME*nc *.output slurm* $outdir
    cp namelist* $outdir

    echo $iter_end > $RUN_DIR/current_iter

    inner_cycle_start=$inner_cycle_end; 
done
