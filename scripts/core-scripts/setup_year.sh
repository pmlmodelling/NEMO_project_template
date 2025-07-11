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
ln -s $INPUT_DIR/SBC/ATM/ERA5_MSL_y$year.nc $RUN_DIR/fluxes/ERA5_MSL.nc
ln -s $INPUT_DIR/SBC/ATM/ERA5_SPH_y$year.nc $RUN_DIR/fluxes/ERA5_SPH.nc
ln -s $INPUT_DIR/SBC/ATM/ERA5_T2M_y$year.nc $RUN_DIR/fluxes/ERA5_T2M.nc

ln -s $INPUT_DIR/SBC/ATM/ERA5_LSM.nc $RUN_DIR/fluxes/ERA5_LSM.nc
ln -s $INPUT_DIR/SBC/ATM/weights_era5_bicubic.nc $RUN_DIR/fluxes/weights_era5_bicubic.nc
if [[ $year -lt 1998 ]]; then
    ln -s $INPUT_DIR/SBC/LIGHT/ady-8day/AMM7-CCI-ady-bbp-443-8day_climatology_y1998_2023.nc $RUN_DIR/fluxes/ady443.nc
    ln -s $INPUT_DIR/SBC/LIGHT/ady-8day/AMM7-CCI-ady-bbp-560-8day_climatology_y1998_2023.nc $RUN_DIR/fluxes/bbp560.nc
else
    ln -s $INPUT_DIR/SBC/LIGHT/ady-8day/AMM7-CCI-ady-bbp-443-8day-y$year.nc $RUN_DIR/fluxes/ady443.nc
    ln -s $INPUT_DIR/SBC/LIGHT/ady-8day/AMM7-CCI-ady-bbp-560-8day-y$year.nc $RUN_DIR/fluxes/bbp560.nc
fi
#Link spectral light fluxesERA5_total_cloud_cover_y1993_regridAMM7.nc
ln -s $INPUT_DIR/SBC/LIGHT/cloud_cover/ERA5_total_cloud_cover_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/total_cloud_cover.nc
ln -s $INPUT_DIR/SBC/LIGHT/cloud_cover/ERA5_total_cloud_cover_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/total_cloud_cover_y$year.nc

ln -s $INPUT_DIR/SBC/LIGHT/cloud_liquid_water/ERA5_total_column_cloud_liquid_water_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/cloud_liquid_water.nc
ln -s $INPUT_DIR/SBC/LIGHT/cloud_liquid_water/ERA5_total_column_cloud_liquid_water_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/cloud_liquid_water_y$year.nc
ln -s $INPUT_DIR/SBC/LIGHT/ozone/ERA5_total_column_ozone_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/total_ozone_y$year.nc
ln -s $INPUT_DIR/SBC/LIGHT/ozone/ERA5_total_column_ozone_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/total_ozone.nc
ln -s $INPUT_DIR/SBC/LIGHT/water_vapour/ERA5_total_column_water_vapour_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/total_water_vapour_y$year.nc
ln -s $INPUT_DIR/SBC/LIGHT/water_vapour/ERA5_total_column_water_vapour_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/total_water_vapour.nc

ln -s $INPUT_DIR/SBC/LIGHT/wind/ERA5_mean_wind_y$year.nc $RUN_DIR/fluxes/wind_speed_y$year.nc
ln -s $INPUT_DIR/SBC/LIGHT/wind/ERA5_mean_wind_y$year.nc $RUN_DIR/fluxes/wind_speed.nc


if [[ $year -lt 2003 ]]; then

    ln -s $INPUT_DIR/SBC/LIGHT/AEROSOL/AERO_m??.nc $RUN_DIR/fluxes/
else
    ln -s $INPUT_DIR/SBC/LIGHT/AEROSOL/AERO_y"$year"m??.nc $RUN_DIR/fluxes/
fi


#ln -s $INPUT_DIR/SBC/LIGHT/water_vapour/ERA5_total_column_water_vapour_y"$year"_regridAMM7.nc $RUN_DIR/fluxes/water_vapour.nc
#ln -s $INPUT_DIR/SBC/LIGHT/sediment_corr_ady.nc $RUN_DIR/fluxes/
#ln -s $INPUT_DIR/SBC/LIGHT/sediment_corr_bb.nc $RUN_DIR/fluxes/


ln -s $INPUT_DIR/SBC/BGC/pCO2/AMM7-pCO2a_y$year.nc $RUN_DIR/fluxes/pCO2a.nc 
ln -s $INPUT_DIR/SBC/BGC/pCO2/AMM7-pCO2a_y$year.nc $RUN_DIR/fluxes/pCO2a_y$year.nc 
ln -s $INPUT_DIR/SBC/BGC/NDep/AMM7-EMEP-NDeposition_y$year.nc $RUN_DIR/fluxes/Ndep.nc
ln -s $INPUT_DIR/SBC/BGC/NDep/AMM7-EMEP-NDeposition_y$year.nc $RUN_DIR/fluxes/Ndep_y$year.nc

#Rivers (linked twice to avoid editing fabm_input each year)
rm -rf $RUN_DIR/rivers*
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers.nc 
ln -s $INPUT_DIR/RIV/NOWMAPS_rivers.$year.ersem_ncc_dd_zeros_TA.nc $RUN_DIR/rivers_y$year.nc 



