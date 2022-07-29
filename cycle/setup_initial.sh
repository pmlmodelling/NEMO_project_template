#!/bin/bash

mkdir -p $OUTPUT_DIR
mkdir -p $RUN_DIR
cp $DEFAULT_RUN_DIR/* $RUN_DIR

cp $WORK/code/xios-build/bin/xios_server.exe $RUN_DIR
cp $WORK/code/nemo/cfgs/$NEMO_CFG/EXP00/nemo $RUN_DIR

echo $(( starting_iter - 1)) > $RUN_DIR/current_iter

mkdir -p $RUN_DIR/restarts
mkdir -p $RUN_DIR/bdy
mkdir -p $RUN_DIR/fluxes
mkdir -p $RUN_DIR/tides

# Restarts
ln -s $INPUT_DIR/DOM/restart_trc.nc $RUN_DIR/restarts/${NAME}_00000000_restart_trc.nc
ln -s $INPUT_DIR/ICS/vo*.nc $RUN_DIR
ln -s $INPUT_DIR/ICS/initcd*.nc $RUN_DIR

# Domain
ln -s $INPUT_DIR/DOM/domain_cfg.nc $RUN_DIR/domain_cfg.nc
ln -s $INPUT_DIR/DOM/coordinates.bdy.nc $RUN_DIR/coordinates.bdy.nc

# Tides
ln -s $INPUT_DIR/TIDES/* $RUN_DIR/tides/


