#!/bin/bash
# Link files
year=$1
yb=$(( $year-1 ))
ya=$(( $year+1 ))

# Link lateral boundaries
rm -rf $RUN_DIR/bdy/*
ln -s $INPUT_DIR/BDY/PHY/BDY_OPEN/$yb/*m12d31*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/BDY_OPEN/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/BDY_SKAG/$yb/*m12d31*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/BDY_SKAG/$year/*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/BGC/amm7_bdytrc_y${year}_seasonal.nc $RUN_DIR/bdy/amm7_bdytrc.nc
ln -s $INPUT_DIR/BDY/BGC/amm7_bdytrc_woa18d_glodap_seasonal.nc $RUN_DIR/bdy/seasonal_c.nc
ln -s $INPUT_DIR/BDY/BGC/amm7skagbdy_trc.lowP.O2.totalk.n2oA_TAunits.nc $RUN_DIR/bdy/amm7skagbdy_trc.nc

# Link fluxes
rm -rf $RUN_DIR/fluxes/*
ln -s $INPUT_DIR/SBC/ATM/*y$year.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/ATM/ERA5_LSM.nc $RUN_DIR/fluxes/ERA5_LSM.nc
ln -s $INPUT_DIR/SBC/ATM/weights*.nc $RUN_DIR/fluxes/
ln -s $INPUT_DIR/SBC/BGC/AMM7-ADY-broadband.nc $RUN_DIR/fluxes/ady.nc
ln -s $INPUT_DIR/SBC/BGC/kd490.nc $RUN_DIR/fluxes/kd490.nc
ln -s $INPUT_DIR/SBC/BGC/AMM7-pCO2a_y$year.nc $RUN_DIR/fluxes/pCO2a.nc 
ln -s $INPUT_DIR/SBC/BGC/AMM7-pCO2a_y$year.nc $RUN_DIR/fluxes/pCO2a_y$year.nc 
ln -s $INPUT_DIR/SBC/BGC/AMM7-EMEP-NDeposition.$year.nc $RUN_DIR/fluxes/Ndep.nc
ln -s $INPUT_DIR/SBC/BGC/AMM7-EMEP-NDeposition.$year.nc $RUN_DIR/fluxes/Ndep_y$year.nc

#Rivers (linked twice to avoid editing fabm_input each year)
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers.nc 
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers_y$year.nc 


