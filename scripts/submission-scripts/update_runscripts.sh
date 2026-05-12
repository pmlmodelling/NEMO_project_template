#!/bin/bash

# ==========================================
# Script to update the runscripts
# ==========================================
# Note: NEMO on scylla uses 63 cores per node, archer2 uses 128
# How to use:

# Method 1 (simple)
# Update the number of xios_servers and ocean_cores
# below and execute this script. This sets one xios_server
# per node and fully populates the cores. 
#
# Therefore,
# number_of_nodes = (xios_servers + ocean_cores) / cores_per_node
# with xios_servers = number_of_nodes
#
# Example:- to use 8 nodes with 63 cores per node, you can rearrange to get 496 ocean cores
# 8 = ( 8 + 496) / 63

# Method 2 (complex)
# For finer control, you can also set each xios_server
# to use more cores (cores_per_xios_server), you can
# allow multiple xios servers per node (xios_servers_per_node),
# and you can have gaps between ocean cores (ocean_cores_before_gap),
# where e.g. 
# 0=no gap, 1=gap between every core, 2=2 ocean cores then a gap etc
# This makes the calculation more fiddly:
#
# number_of_nodes * cores_per_node = (xios_servers * cores_per_xios_server
#			 + ocean_cores * (cores_before_gap + 1)/cores_before_gap) 	
# where number_of_nodes > xios_servers / xios_servers_per_node
# 
# which may take some trial and error to tune
#
# The wallclock time is by default set to 1 hour, which comfortable covers
# 1 month of simulation at most core counts. It can be changed using the variable
# below, please use the format hh:mm:ss
#
# --------------------------------------------

# Set parameters
xios_servers=8
ocean_cores=496
system=scylla     
cores_per_node=63 # Scylla uses 63

# Fine control parameters
cores_per_xios_server=1
xios_servers_per_node=1
ocean_cores_before_gap=0

wallclock_time=01:00:00 
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
EOF2
)

./mkslurm.py -S $xios_servers -s $cores_per_xios_server -m $xios_servers_per_node \
               -C $ocean_cores -g $ocean_cores_before_gap -N $cores_per_node -t $wallclock_time -j AMM7-cycle \
	       -z "$text" -T -M --sys "$system"    \
		> runscript_cycle_$system.slurm
chmod 755 runscript_cycle_$system.slurm

# Update mapping script
./mkslurm.py -S $xios_servers -s $cores_per_xios_server -m $xios_servers_per_node \
               -C $ocean_cores -g $ocean_cores_before_gap -N $cores_per_node -t $wallclock_time -j AMM7 \
	       -H --sys "$system" \
	       > runscript_mapping_$system.sh
chmod 755 runscript_mapping_$system.sh

# Update testing script
./mkslurm.py -S $xios_servers -s $cores_per_xios_server -m $xios_servers_per_node \
               -C $ocean_cores -g $ocean_cores_before_gap -N $cores_per_node -t $wallclock_time -j AMM7-test --sys "$system" \
	       > runscript_testing_$system.slurm
chmod 755 runscript_testing_$system.slurm
