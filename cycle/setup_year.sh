#!/bin/bash
# Link files
year=$1
yb=$(( $year-1 ))
ya=$(( $year+1 ))

# Link lateral boundaries
rm -rf $RUN_DIR/bdy/*
ln -s $INPUT_DIR/LBC/PHY/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/LBC/BGC/*y${yb}m12.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/LBC/BGC/*y${ya}m01.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/LBC/BGC/*y$year*.nc $RUN_DIR/bdy/

# Link fluxes
rm -rf $RUN_DIR/fluxes/*
ln -s $INPUT_DIR/SBC/ATM/*y$year.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/ATM/weights*.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/BGC/pCO2_y$year.nc $RUN_DIR/fluxes/pCO2.nc 
ln -s $INPUT_DIR/SBC/BGC/Ndep_y$year.nc $RUN_DIR/fluxes/Ndep.nc

#Rivers (linked twice to avoid editing fabm_input each year)
ln -s $INPUT_DIR/RIV/rivers_y$year.nc $RUN_DIR/river.nc 
ln -s $INPUT_DIR/RIV/rivers_y$year.nc $RUN_DIR/river_y$year.nc 


