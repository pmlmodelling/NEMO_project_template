#!/bin/bash

# ==========================================
# Script to update the core count on scylla
# ==========================================
# Note: NEMO on scylla uses 63 cores per node

# How to use:

# Method 1 (simple)
# Update the number of xios_servers and ocean_cores
# below and execute this script. This sets one xios_server
# per node. 
# Therefore, to make full use of nodes set:
# number_of_nodes = (xios_servers + ocean_cores) / 63
# with xios_servers = number_of_nodes
# e.g. for 8 nodes, you can rearrange to get 496 cores
# 8 = ( 8 + 496) / 63

# Method 2 (complex)
# For finer control, you can also set each xios_server
# to use more cores (cores_per_xios_server), you can
# allow multiple xios servers per node (xios_servers_per_node),
# and you can have gaps between ocean cores (ocean_cores_before_gap),
# where e.g. 
# 0=no gap, 1=gap between every core, 2=2 ocean cores then a gap etc
# This makes the calculation more fiddly,
# 63 * number_of_nodes = (xios_servers * cores_per_xios_server
#			 + ocean_cores * (cores_before_gap + 1)/cores_before_gap) 	
# where number_of_nodes > xios_servers / xios_servers_per_node	 

# --------------------------------------------

# Set parameters
xios_servers=8 
ocean_cores=496

# Fine control parameters
cores_per_xios_server=1
xios_servers_per_node=1
ocean_cores_before_gap=0

# --------------------------------------------

# Update cycle script
text=$(cat <<'EOF2'
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
    $SCRIPTS_DIR/core-scripts/setup_initial.sh
fi

$SCRIPTS_DIR/core-scripts/setup_year.sh $year

cd $RUN_DIR
export dt=`grep 'rn_rdt\s*=' namelist_cfg | tr -d '[:space:]' | cut -d'=' -f2 | cut -d'!' -f1` #get time-step

for (( i=1; i<=$N_sub_months; i++ ));
do
    $SCRIPTS_DIR/core-scripts/submit_job.sh
    outdir=$OUTPUT_DIR/$EXP_NAME/$year/$(printf '%02d' $month)
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
        $SCRIPTS_DIR/core-scripts/setup_year.sh $year
    fi
done

# Submit next cycle if run completed successfully
if [ $year -le $END_YEAR ] && [ $RUN_STATUS == "true" ]; then
    echo "Submitting $year $month at $(date +'%F %T')"
    cd $RUN_DIR
cat > $RUN_DIR/current_date <<EOF
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
EOF2
)

./mkslurm_scylla -S $xios_servers -s $cores_per_xios_server -m $xios_servers_per_node \
               -C $ocean_cores -g $ocean_cores_before_gap -N 63 -t 01:00:00 -j AMM7-cycle \
	       -z "$text" -T -M     \
	       > runscript_cycle_scylla.slurm

# Update mapping script
./mkslurm_scylla -S $xios_servers -s $cores_per_xios_server -m $xios_servers_per_node \
               -C $ocean_cores -g $ocean_cores_before_gap -N 63 -t 01:00:00 -j AMM7 \
	       -H \
	       > runscript_mapping_scylla.sh

# Update testing script
./mkslurm_scylla -S $xios_servers -s $cores_per_xios_server -m $xios_servers_per_node \
               -C $ocean_cores -g $ocean_cores_before_gap -N 63 -t 01:00:00 -j AMM7-test \
	       > runscript_testing_scylla.slurm
