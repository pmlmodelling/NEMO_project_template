import numpy as np
from datetime import datetime, timedelta
import xarray as xr
import pandas as pd
import tqdm
from pathlib import Path

# read NOAA atmospheric pCO2 data and use it to make AMM7 input files
# data for past years is used directly, future years are extrapolated using  a linear trend + annual cycle
# monthly data is provided at all grid cell, but no spatial variation
# NOAA data comes from the Global Monitoring Laboratory, previously ESRL
# https://gml.noaa.gov/ccgg/trends/gl_data.html 

#Load Grid
gridfile = '/work/n01/n01/shared/AMM7-INPUTS/DOM/domain_cfg.nc'
grd = xr.open_dataset(gridfile)

#Set output dir
outdir = '/work/n01/n01/shared/AMM7-INPUTS/SBC/BGC/pCO2/'
file_prefix = 'AMM7-pCO2a_y'
Path(outdir).mkdir(parents=True, exist_ok=True)

# Load data
fname = '/work/n01/n01/shared/BGC_datasets/NOAA/co2_mm_gl.txt'
df = pd.read_csv(fname,delimiter=r"\s+",comment='#',header=None,names=['year','month','decimal','average','average_unc','trend','trend_unc'])

# Create dataset
ds = grd[['nav_lon','nav_lat']]
ds = xr.Dataset()
ds = ds.assign_coords({'nav_lon':grd.nav_lon,'nav_lat':grd.nav_lat})
ds['t'] = xr.DataArray(data=[datetime(y,m,15) for y,m in zip(df.year,df.month)],dims='t')

ds['pCO2a'] = xr.DataArray(data=df.average.values,dims='t')
ds['pCO2a'] = ds.pCO2a.expand_dims({'y':ds.y,'x':ds.x},axis=[1,2]).drop_vars(['y','x'])

# Add attributes
ds['t'].encoding['units'] = 'days since 1970-01-01 00:00:00'
ds['t'] = ds['t'].assign_attrs({'long_name':'time'})

ds['pCO2a'] = ds['pCO2a'].assign_attrs({'units':'ppm','long_name':'atmospheric partial pressure of CO2'})

ds = ds.assign_attrs({'title':"Atmospheric partial pressure of CO2 over AMM7 domain.",
         		'comment': "Based on global averages of CO2 partial pressure over marine surface sites, provided by the Global Monitoring Laboratory of NOAA (https://gml.noaa.gov/ccgg/trends/gl_data.html). Data copied directly from file.",
                'author': "Dale Partridge, PML, Aug 2024"})

#Save files
for y in tqdm.tqdm(range(1990,2024)):
    ds.sel(t=str(y)).to_netcdf(outdir+file_prefix+str(y)+'.nc',unlimited_dims='t')
