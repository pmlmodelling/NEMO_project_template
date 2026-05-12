import xarray as xr
import pandas as pd
import numpy as np

df=pd.read_csv('https://gml.noaa.gov/aftp/data/hats/n2o/combined/GML_global_N2O.txt',sep=r"\s+",comment='#')

df['time_counter'] = pd.to_datetime(dict(year=df.GML_N2O_YYYY, month=df.GML_N2O_MM, day=15))
df = df.set_index('time_counter')
df = df.rename(columns={'GML_NH_N2O':'O5_n'})
ds = df[['O5_n']].to_xarray()

ds.to_netcdf('noaa_OBCs.nc')

