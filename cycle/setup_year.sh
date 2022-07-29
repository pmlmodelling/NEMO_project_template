#!/bin/bash
# Link files
year=$1
yb=$(( $year-1 ))
ya=$(( $year+1 ))

# Boundaries
rm -rf $RUN_DIR/bdy/*
ln -s $INPUT_DIR/LBC/PHY/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/LBC/BGC/*y${yb}m12.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/LBC/BGC/*y${ya}m01.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/LBC/BGC/*y$year*.nc $RUN_DIR/bdy/

# Atmospheric fluxes
rm -rf $RUN_DIR/fluxes/*
ln -s $INPUT_DIR/SBC/ATM/*y$year.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/ATM/weights*.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/BGC/pCO2_y$year.nc $RUN_DIR/fluxes/pCO2.nc 
ln -s $INPUT_DIR/SBC/BGC/Ndep_y$year.nc $RUN_DIR/fluxes/Ndep.nc
if [[ $year -lt 1998 ]]; then
    ln -s $INPUT_DIR/SBC/BGC/SANH-CCI-ady-8day-broadband_climatology.nc $RUN_DIR/fluxes/ady.nc
else
    ln -s $INPUT_DIR/SBC/BGC/SANH-CCI-ady-8day-broadband_y$year.nc $RUN_DIR/fluxes/ady.nc
fi

#Rivers (linked twice to avoid editing fabm_input each year)
ln -s $INPUT_DIR/RIV/rivers_y$year.nc $RUN_DIR/river.nc 
ln -s $INPUT_DIR/RIV/rivers_y$year.nc $RUN_DIR/river_y$year.nc 


