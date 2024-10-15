'''
Script to interpolate variables from multiple sources onto a nemo domain

Reads configuration file interp.yaml from the same directory containing the fields:

domainfile : path to domain netcdf file
outfile : name (+path) of file to save interpolated output
variables : set of variables named by desired output varname with following fields:
        input_file : path to source file
        varname : name of variable to interpolate in input_file
        has_depth (optional) : booleon, field is 3D (True) or 2D (False), (default: True) 
        timeidx (optional) : index of time record to interpolate (default: 0)  
        dim_map (optional) :
            x : lon dimension
            y : lat dimension
            t : time dimenion
            z : depth dimension
        var_map (optional) :
            lon : lon variable
            lat : lat variable
            depth : depth variable
        
'''
import yaml
import xesmf
import xarray as xr
import numpy as np
from tqdm import tqdm

def vert_int(data, src_depth, tgt_depth):
    data = xr.DataArray(data=data,coords={'depth':src_depth},dims={'depth':len(src_depth)})
    tgt_data = data.interp(depth=tgt_depth,
                method='linear',kwargs={"fill_value": "extrapolate"})
    return tgt_data.values

def dim_remap(ds,vconf):
    remap = {v:k for k,v in vconf['dim_map'].items()}
    return ds.rename_dims(remap) 

def var_remap(ds,vconf):
    remap = {v:k for k,v in vconf['var_map'].items()}
    return ds.rename(remap) 

# Open yaml file with configuration
with open('0_interp_TS.yaml','r') as yamlfile:
    yconf = yaml.safe_load(yamlfile)

# Load nemo domain file, rename variables and create a mask
grd = xr.open_dataset(yconf['domainfile']).rename(
                        {'nav_lon':'lon','nav_lat':'lat','nav_lev':'depth'}).isel(t=0)
grd = grd.assign_coords(lon=grd.lon,lat=grd.lat,depth=grd.depth)                        
grd['mask'] = xr.where(grd.bottom_level!=0,1,0)

# Create empty dataset to hold interpolated values
ds_int = xr.Dataset(coords={'depth':grd.depth,'lon':grd.lon,'lat':grd.lat})

for v,vconf in yconf['variables'].items():
    print('Interpolating: ' + v)
    # Load dataset and remap name
    ds = xr.open_dataset(vconf['input_file'],decode_times=False)
    ds = dim_remap(ds,vconf) if 'dim_map' in vconf else ds
    ds = var_remap(ds,vconf) if 'var_map' in vconf else ds
    ds = ds.assign_coords(lon=ds.lon,lat=ds.lat)
    ds = ds.assign_coords(depth=ds.depth) if 'depth' in ds else ds

    # If time is present, select correct time record
    timerec = int(vconf['timeidx']) if 'timeidx' in vconf else 0 
    ds = ds.isel(t=timerec) if 't' in list(ds.dims.keys()) else ds

    # 2D interpolation for each depth level, followed by interpolation in depth
    ds_3Dint = xr.Dataset(coords={'depth':ds.depth,'lon':grd.lon,'lat':grd.lat})
    ds_3Dint[v] = (('z','y','x'),np.zeros((ds_3Dint.z.size,ds_3Dint.y.size,ds_3Dint.x.size)))
    for z in tqdm(range(ds.z.size)):
        ds['mask'] = xr.where(~np.isnan(ds[vconf['varname']].isel(z=z)),1,0)
        regridder = xesmf.Regridder(ds.isel(z=z),grd,method='bilinear',extrap_method='nearest_s2d')
        ds_3Dint[v][z,:,:] = regridder(ds[vconf['varname']].isel(z=z)).values
    
    #Vertical interpolation
    src_data = ds_3Dint[v].swap_dims({'z':'depth'})
    ds_int[v] = xr.apply_ufunc(vert_int,src_data,src_data.depth,grd.gdept_0,
                                input_core_dims=[['depth'],['depth'],['z']],dask='parallelized',
                                output_core_dims=[['z']],output_dtypes=['float64'],
                                vectorize=True).expand_dims({'t':1})

ds_int['time_counter'] = 0

ds_int.to_netcdf(yconf['outfile'],unlimited_dims='t')

