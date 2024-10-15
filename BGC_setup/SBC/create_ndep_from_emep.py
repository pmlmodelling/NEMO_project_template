import numpy as np
from datetime import datetime, timedelta
import xarray as xr
import xesmf
import tqdm
from pathlib import Path

# read NOAA atmospheric pCO2 data and use it to make AMM7 input files
# data for past years is used directly, future years are extrapolated using  a linear trend + annual cycle
# monthly data is provided at all grid cell, but no spatial variation
# NOAA data comes from the Global Monitoring Laboratory, previously ESRL
# https://gml.noaa.gov/ccgg/trends/gl_data.html 

#Load Grid
gridfile = '/work/n01/n01/shared/AMM7-INPUTS/DOM/domain_cfg.nc'
grd = xr.open_dataset(gridfile).rename(
                        {'nav_lon':'lon','nav_lat':'lat','nav_lev':'depth'}).isel(t=0)
grd = grd.assign_coords(lon=grd.lon,lat=grd.lat,depth=grd.depth)
grd['mask'] = xr.where(grd.bottom_level!=0,1,0)

#Set output dir
outdir = '/work/n01/n01/shared/AMM7-INPUTS/SBC/BGC/NDep/'
file_prefix = 'AMM7-EMEP-NDeposition_y'
Path(outdir).mkdir(parents=True, exist_ok=True)

# Load data
emepgrid='EMEP01'
model='rv5.3'
timeres='month'
reporting_year='rep2024'
url = 'https://thredds.met.no/thredds/dodsC/data/EMEP/2024_Reporting/'

mg2mmol=1/14.007 # Convert from mgN to mmol
yr2s=(1/365.0)*(1/1/86400.0) # Convert rate from x/m2/yr to x/m2/s

for y in tqdm.tqdm(range(1993,2022)):
    fname=f'%s_%s_%s.%dmet_%demis_%s.nc' %(emepgrid,model,timeres,y,y,reporting_year)
    ds = xr.open_dataset(url+fname)

    ds['N3_flux'] = mg2mmol*yr2s*(ds.WDEP_OXN + ds.DDEP_OXN_m2Grid)
    ds['N4_flux'] = mg2mmol*yr2s*(ds.WDEP_RDN + ds.DDEP_RDN_m2Grid)

    ds = ds[['N3_flux','N4_flux']]


    # Create empty dataset to hold interpolated values
    ds_int = xr.Dataset(coords={'t':ds.time.rename({'time':'t'}),'lon':grd.lon,'lat':grd.lat})

    ds = ds.assign_coords(lon=ds.lon,lat=ds.lat)

    ds['mask'] = xr.where(~np.isnan(ds.N3_flux.isel(time=0)),1,0)
    regridder = xesmf.Regridder(ds,grd,method='bilinear',extrap_method='nearest_s2d')
    for v in ['N3_flux','N4_flux']:
        ds_int[v] = (('t','y','x'),regridder(ds[v]).values)
        ds_int[v] = ds_int[v].assign_attrs({'units':'mmol*m-2*s-1'})

    ds_int = ds_int.assign_attrs({'title':"Atmospheric nitrogen deposition from EMEP over AMM7 domain.",
                'author': "Dale Partridge, PML, Aug 2024"})

    ds_int.to_netcdf(outdir+file_prefix+str(y)+'.nc',unlimited_dims='t')
