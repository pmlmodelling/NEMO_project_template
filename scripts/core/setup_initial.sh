#!/bin/bash

mkdir -p $OUTPUT_DIR
mkdir -p $RUN_DIR
cp $DEFAULT_RUN_DIR/* $RUN_DIR

cp $EXECUTABLE_DIR/nemo $RUN_DIR
cp $EXECUTABLE_DIR/xios_server.exe $RUN_DIR

echo $(( starting_iter - 1)) > $RUN_DIR/current_iter

mkdir -p $RUN_DIR/restarts
mkdir -p $RUN_DIR/bdy
mkdir -p $RUN_DIR/fluxes
mkdir -p $RUN_DIR/tides

# Restarts
ln -s $INPUT_DIR/DOM/AMM7_restart_trc_20050101.nc $RUN_DIR/restarts/${NAME}_20050101_restart_trc.nc
ln -s $INPUT_DIR/DOM/AMM7_restart_20050101.nc $RUN_DIR/restarts/${NAME}_20050101_restart.nc

# Domain
ln -s $INPUT_DIR/DOM/domain_cfg.nc $RUN_DIR/domain_cfg.nc
ln -s $INPUT_DIR/DOM/coordinates.bdy.nc $RUN_DIR/coordinates.bdy.nc
ln -s $INPUT_DIR/DOM/coordinates.skagbdy.nc $RUN_DIR/coordinates.skagbdy.nc

# Tides
ln -s $INPUT_DIR/TIDES/* $RUN_DIR/tides/


