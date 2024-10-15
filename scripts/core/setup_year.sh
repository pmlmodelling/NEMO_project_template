#!/bin/bash
# Link files
year=$1
yb=$(( $year-1 ))
ya=$(( $year+1 ))

# Link lateral boundaries
rm -rf $RUN_DIR/bdy/*
ln -s $INPUT_DIR/BDY/BDY-OPEN/$yb/*m12.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/BDY-OPEN/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/BDY-SKG/$yb/*m12.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/BDY-SKG/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/BDY-BGC/amm7_bdytrc.nc $RUN_DIR/bdy/amm7bdy_trc.nc
ln -s $INPUT_DIR/BDY/BDY-BGC/amm7_skagbdytrc.nc $RUN_DIR/bdy/amm7skagbdy_trc.nc
ln -s $INPUT_DIR/BDY/BDY-BGC/amm7_bdytrc_y${year}_DIC_seasonal.nc $RUN_DIR/bdy/amm7bdy_trcseasonal.nc

# Link fluxes
rm -rf $RUN_DIR/fluxes/*
ln -s $INPUT_DIR/SBC/ATM/ERA5_*_y$year.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/ATM/ERA5_LSM.nc $RUN_DIR/fluxes/ERA5_LSM.nc
ln -s $INPUT_DIR/SBC/ATM/weights_era5_bicubic.nc $RUN_DIR/fluxes/weights_era5_amm7_bicubic.nc
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
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers.nc 
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers_y$year.nc 



