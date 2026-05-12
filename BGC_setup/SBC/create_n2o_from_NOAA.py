import numpy as np
from datetime import datetime, timedelta
import xarray as xr
import pandas as pd
import tqdm
from pathlib import Path

# read NOAA atmospheric N2O data and use it to make AMM7 input files
# monthly data is provided at all grid cell, but no spatial variation.
# NOAA data comes from the Halocarbons program
# https://gml.noaa.gov/aftp/data/hats/n2o/combined/GML_global_N2O.txt 

#Load Grid
gridfile = '/work/shared/AMM7-INPUTS/DOM/domain_cfg.nc'
grd = xr.open_dataset(gridfile)

#Set output dir
outdir = '/work/shared/AMM7-INPUTS/SBC/BGC/n2o/'
file_prefix = 'AMM7-n2o_y'
Path(outdir).mkdir(parents=True, exist_ok=True)

# Load data
fname = 'https://gml.noaa.gov/aftp/data/hats/n2o/combined/GML_global_N2O.txt'
df = pd.read_csv(fname,sep=r"\s+",comment='#')

# Create dataset
ds = grd[['nav_lon','nav_lat']]
ds = xr.Dataset()
ds = ds.assign_coords({'nav_lon':grd.nav_lon,'nav_lat':grd.nav_lat})
ds['t'] = xr.DataArray(data=[datetime(y,m,15) for y,m in zip(df.GML_N2O_YYYY,df.GML_N2O_MM)],dims='t')

ds['n2o'] = xr.DataArray(data=df.GML_NH_N2O.values,dims='t')
ds['n2o'] = ds.n2o.expand_dims({'y':ds.y,'x':ds.x},axis=[1,2]).drop_vars(['y','x'])

# Add attributes
ds['t'].encoding['units'] = 'days since 1970-01-01 00:00:00'
ds['t'] = ds['t'].assign_attrs({'long_name':'time'})

ds['n2o'] = ds['n2o'].assign_attrs({'units':'ppb','long_name':'atmospheric partial pressure of N2O'})

ds = ds.assign_attrs({'title':"Atmospheric partial pressure of N2O over AMM7 domain.",
         		'comment': "Based on global averages of N2O, provided by the NOAA halocarbons program (https://gml.noaa.gov/aftp/data/hats/n2o/combined/GML_global_N2O.txt). Data copied directly from file.",
                'author': "Dale Partridge, PML, Aug 2024"})

#Save files
for y in tqdm.tqdm(range(1990,2024)):
    ds.sel(t=str(y)).to_netcdf(outdir+file_prefix+str(y)+'.nc',unlimited_dims='t')
