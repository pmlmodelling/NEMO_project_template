#!/bin/bash
# Link files
year=$1

if [ $year -le 2014 ]
then
	export SCENARIO=historical
fi

# Link lateral boundaries
rm -rf $RUN_DIR/bdy/*
ln -s $INPUT_DIR/BDY/PHY/open/$year/AMM7_${MODEL}_${SCENARIO}_bdyT_y${year}*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/open/$year/AMM7_${MODEL}_${SCENARIO}_bdyU_y${year}*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/open/$year/AMM7_${MODEL}_${SCENARIO}_bdyV_y${year}*.nc $RUN_DIR/bdy/
ln -s $INPUT_DIR/BDY/PHY/skag/$year/AMM7skag_${MODEL}_${SCENARIO}_bdyT_y${year}.nc $RUN_DIR/bdy/AMM7skag_${MODEL}_${SCENARIO}_bdyT_y${year}.nc
ln -s $INPUT_DIR/BDY/PHY/skag/$year/AMM7skag_${MODEL}_${SCENARIO}_bdyU_y${year}.nc $RUN_DIR/bdy/AMM7skag_${MODEL}_${SCENARIO}_bdyU_y${year}.nc
ln -s $INPUT_DIR/BDY/PHY/skag/$year/AMM7skag_${MODEL}_${SCENARIO}_bdyV_y${year}.nc $RUN_DIR/bdy/AMM7skag_${MODEL}_${SCENARIO}_bdyV_y${year}.nc
ln -s $INPUT_DIR/BDY/BGC/amm7_bdytrc_${MODEL}_${SCENARIO}_y${year}.nc $RUN_DIR/bdy/amm7_bdytrc_${MODEL}_${SCENARIO}_y${year}.nc
ln -s $INPUT_DIR/BDY/BGC/amm7_skagbdytrc_${MODEL}_${SCENARIO}_y${year}.nc $RUN_DIR/bdy/amm7_skagbdytrc_${MODEL}_${SCENARIO}_y${year}.nc

# Link fluxes
rm -rf $RUN_DIR/fluxes/*
ln -s $INPUT_DIR/SBC/ATM/AMM7_${MODEL}_${SCENARIO}_*_y$year.nc $RUN_DIR/fluxes/
#ln -s $INPUT_DIR/SBC/ATM/ERA5_LSM.nc $RUN_DIR/fluxes/ERA5_LSM.nc
ln -s $INPUT_DIR/SBC/ATM/AMM7_${MODEL}_weights_bicubic_atmos.nc $RUN_DIR/fluxes/AMM7_${MODEL}_weights_bicubic.nc
ln -s $INPUT_DIR/SBC/ATM/AMM7_${MODEL}_weights_bilin_atmos.nc $RUN_DIR/fluxes/AMM7_${MODEL}_weights_bilin.nc
#if [[ $year -lt 1998 ]]; then
# forced climatology for ady throughout the whole period
ln -s $INPUT_DIR/SBC/BGC/ady/AMM7-CCI-ady-8day-broadband_climatology_1998_2023.nc $RUN_DIR/fluxes/ady.nc
#else
#    ln -s $INPUT_DIR/SBC/BGC/ady/AMM7-CCI-ady-8day-broadband_y$year.nc $RUN_DIR/fluxes/ady.nc
#fi
#
#
# why twice?
ln -s $INPUT_DIR/SBC/BGC/pCO2/AMM7-pCO2a_${SCENARIO}_y$year.nc $RUN_DIR/fluxes/pCO2a.nc 
ln -s $INPUT_DIR/SBC/BGC/pCO2/AMM7-pCO2a_${SCENARIO}_y$year.nc $RUN_DIR/fluxes/pCO2a_y$year.nc 
ln -s $INPUT_DIR/SBC/BGC/NDep/AMM7_Ndep_BC-EMEP_${SCENARIO}_y$year.nc $RUN_DIR/fluxes/Ndep.nc
ln -s $INPUT_DIR/SBC/BGC/NDep/AMM7_Ndep_BC-EMEP_${SCENARIO}_y$year.nc $RUN_DIR/fluxes/Ndep_y$year.nc

#Rivers (linked twice to avoid editing fabm_input each year)
rm -rf $RUN_DIR/rivers/*
ln -s $INPUT_DIR/RIV/amm7_rivers_${MODEL}_${SCENARIO}_y${year}.nc $RUN_DIR/rivers/rivers.nc 
ln -s $INPUT_DIR/RIV/amm7_rivers_${MODEL}_${SCENARIO}_y${year}.nc $RUN_DIR/rivers/rivers_y$year.nc 



