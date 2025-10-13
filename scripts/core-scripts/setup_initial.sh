#!/bin/bash

mkdir -p $OUTPUT_DIR
mkdir -p $RUN_DIR
rsync -a --exclude runscripts $DEFAULT_RUN_DIR/* $RUN_DIR

rsync -a $EXECUTABLE_DIR/nemo $RUN_DIR
rsync -a $EXECUTABLE_DIR/xios_server.exe $RUN_DIR

mkdir -p $RUN_DIR/restarts
mkdir -p $RUN_DIR/bdy
mkdir -p $RUN_DIR/fluxes
mkdir -p $RUN_DIR/tides

# Restarts
ln -s $INPUT_DIR/DOM/19930101_restart_trc_30yr_spinup_w_benthic_predators.nc $RUN_DIR/restarts/${NAME}_19930101_restart_trc.nc
ln -s $INPUT_DIR/DOM/glosea_ini_19930101_vosaline_domain_cfg_co9amm7_MEsL51r10-07.nc $RUN_DIR/restarts/AMM7_19930101_vosaline.nc
ln -s $INPUT_DIR/DOM/glosea_ini_19930101_votemper_domain_cfg_co9amm7_MEsL51r10-07.nc $RUN_DIR/restarts/AMM7_19930101_votemper.nc

# Domain
ln -s $INPUT_DIR/DOM/domain_cfg.nc $RUN_DIR/domain_cfg.nc
ln -s $INPUT_DIR/DOM/coordinates.open.bdy.nc $RUN_DIR/coordinates.bdy.nc
ln -s $INPUT_DIR/DOM/coordinates.skag.bdy.nc $RUN_DIR/coordinates.skagbdy.nc

# Tides
ln -s $INPUT_DIR/TIDE/* $RUN_DIR/tides/


