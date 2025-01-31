#!/bin/bash
# Link files
year=$1

# Link lateral boundaries
rm -rf $RUN_DIR/bdy/*
ln -s $INPUT_DIR/BDY/PHY/open/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/skag/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/BGC/amm7_bdytrc_y$year.nc $RUN_DIR/bdy/amm7_bdytrc.nc
ln -s $INPUT_DIR/BDY/BGC/amm7_skagbdytrc_y$year.nc $RUN_DIR/bdy/amm7_skagbdytrc.nc

# Link fluxes
rm -rf $RUN_DIR/fluxes/*
ln -s $INPUT_DIR/SBC/ATM/ERA5_*_y$year.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/ATM/ERA5_LSM.nc $RUN_DIR/fluxes/ERA5_LSM.nc
ln -s $INPUT_DIR/SBC/ATM/weights_era5_bicubic.nc $RUN_DIR/fluxes/weights_era5_bicubic.nc
if [[ $year -lt 1998 ]]; then
    ln -s $INPUT_DIR/SBC/BGC/ady/AMM7-CCI-ady-8day-broadband_climatology_1998_2023.nc $RUN_DIR/fluxes/ady.nc
else
    ln -s $INPUT_DIR/SBC/BGC/ady/AMM7-CCI-ady-8day-broadband_y$year.nc $RUN_DIR/fluxes/ady.nc
fi
ln -s $INPUT_DIR/SBC/BGC/pCO2/AMM7-pCO2a_y$year.nc $RUN_DIR/fluxes/pCO2a.nc 
ln -s $INPUT_DIR/SBC/BGC/pCO2/AMM7-pCO2a_y$year.nc $RUN_DIR/fluxes/pCO2a_y$year.nc 
ln -s $INPUT_DIR/SBC/BGC/NDep/AMM7-EMEP-NDeposition_y$year.nc $RUN_DIR/fluxes/Ndep.nc
ln -s $INPUT_DIR/SBC/BGC/NDep/AMM7-EMEP-NDeposition_y$year.nc $RUN_DIR/fluxes/Ndep_y$year.nc

#Rivers (linked twice to avoid editing fabm_input each year)
rm -rf $RUN_DIR/rivers*
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers.nc 
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers_y$year.nc 



