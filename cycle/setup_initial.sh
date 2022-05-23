#!/bin/bash

cp $WORK/code/xios-build/bin/xios_server.exe $RUN_DIR
cp $WORK/code/nemo/cfgs/$NEMO_CFG/EXP00/nemo $RUN_DIR

INPUT_DIR=$/INPUTS
mkdir -p $RUN_DIR/restarts
mkdir -p $RUN_DIR/bdy
mkdir -p $RUN_DIR/fluxes

# Restarts
ln -s $INPUT_DIR/DOM/restart.nc $RUN_DIR/restart.nc
ln -s $INPUT_DIR/DOM/restart_trc.nc $RUN_DIR/restart_trc.nc

# Domain
ln -s $INPUT_DIR/DOM/domain_cfg.nc $RUN_DIR/domain_cfg.nc
ln -s $INPUT_DIR/DOM/coordinates.bdy.nc $RUN_DIR/coordinates.bdy.nc

# Tides
mkdir -p $RUN_DIR/tides
ln -s $INPUT_DIR/TIDES/* $RUN_DIR/tides/


