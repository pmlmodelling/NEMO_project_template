'''
Script to create BGC OBCs
'''

import yaml
import xarray as xr
import numpy as np
import gsw
from pathlib import Path


# Open yaml file with configuration
with open('3_make_OBC_files.yaml','r') as yamlfile:
    yconf = yaml.safe_load(yamlfile)

#Load grid
grd = xr.open_dataset(yconf['domainfile'])

for b,bconf in yconf['boundaries'].items():
    Path(bconf['output_folder']).mkdir(parents=True, exist_ok=True)
    coord = xr.open_dataset(bconf['coords_file'])
    ivals = xr.DataArray(coord.nbit.values.squeeze(),dims='xb')-1 #indices are numbered from 1 instead of a pythonic 0
    jvals = xr.DataArray(coord.nbjt.values.squeeze(),dims='xb')-1
    bdy_depth = grd[['nav_lat','nav_lon','gdept_0','e3t_0']].isel(x=ivals,y=jvals,t=0).rename({'z':'zb'})
    for y in np.arange(yconf['ystart'],yconf['yend']):
        print('Creating boundary for year '+str(y))
        # Create dataset and add index and depth variables
        ds = xr.Dataset(coords={'time_counter': xr.DataArray(dims=["time_counter"],data=np.arange(1,13))},data_vars={'nbit':coord.nbit,'nbjt':coord.nbjt,'nbrt':coord.nbrt,'gphit':coord.gphit,'glamt':coord.glamt}).rename({'xbT':'xb'})
        ds['gdept'] = bdy_depth.gdept_0.expand_dims({'yb':1})
        ds['e3t'] = bdy_depth.e3t_0.expand_dims({'yb':1})
       
        # Make density
        ds_phys = xr.open_mfdataset('%s/%s/*bdyT_y%s*.nc' %(bconf['phys_folder'],str(y),str(y)))
        ds_phys['time_counter'] = [np.datetime64('%s-01-01T12:00:00.000000000' %str(y))+ np.timedelta64(i,'D') for i in np.arange(len(ds_phys.time_counter))] # Need to set time to correct year otherwise leap years mess up resampling
        ds_phys = ds_phys.resample(time_counter='1M').mean('time_counter').rename({'z':'zb'})
        ds_phys['time_counter'] = ds.time_counter
        ds_phys['abs_pres'] = (('time_counter','zb','yb','xb'),gsw.p_from_z(-ds_phys.deptht.fillna(0),bdy_depth.nav_lat ).data)
        ds_phys['abs_sal'] = (('time_counter','zb','yb','xb'),gsw.SA_from_SP(ds_phys.vosaline, ds_phys.abs_pres, bdy_depth.nav_lon, bdy_depth.nav_lat).data)
        ds_phys['con_temp'] = (('time_counter','zb','yb','xb'),gsw.CT_from_pt(ds_phys.abs_sal, ds_phys.votemper).data)
        ds_phys['density'] = (('time_counter','zb','yb','xb'),gsw.rho(ds_phys.abs_sal, ds_phys.con_temp, ds_phys.abs_pres).data)
        ds_phys['density'] = ds_phys.density.fillna(0).assign_attrs({"units": "kg / m^3", "standard name": "In-situ density "})

        for v,vconf in yconf['variables'].items():
            if vconf['method'] == 'fixed':
                # Fill boundary with a fixed value everywhere
                print('Creating '+v+' boundary using fixed value of '+str(vconf['fixed_value']))
                ds[v] = xr.DataArray(vconf['fixed_value']*np.ones((ds.time_counter.size,ds.yb.size,ds.xb.size,ds.zb.size)),dims=('time_counter','yb','xb','zb'))

            elif vconf['method'] == 'input':
                # Fill boundary directly from an input file that has been interpolated onto the right grid
                print('Creating '+v+' boundary using inputs from '+vconf['input_file'])
                ds_i = xr.open_dataset(vconf['input_file']).rename({'t':'time_counter','z':'zb'})
                ds[v] = ds_i[v].isel(x=ivals,y=jvals).fillna(0).expand_dims(dim='yb',axis=1)

            elif vconf['method'] == 'exp_decay':
                # Fill boundary with exponential decay, with max_value and the surface, down to a min value at max_depth
                print('Creating '+v+' boundary using exponential decay')
                ds[v] = vconf['max_value']*np.exp(ds.gdept*np.log(vconf['min_value']/vconf['max_value'])/vconf['max_depth']).expand_dims({'time_counter':12})
                ds[v] = xr.where(ds.gdept>vconf['max_depth'],vconf['min_value'],ds[v])
            else:
                print('No valid method specified for: '+v)
            
            # Convert units of inputs from WOA/Glodap
            if v in ['N1_p','N3_n','O2_o','N5_s','O3_c', 'O3_TA']:
                ds[v] = ds[v]*ds_phys.density/1000.0 #umol/kg to mmol/m3

            # Add attributes
            ds[v] = ds[v].assign_attrs({'units':vconf['units'],'long_name':vconf['long_name']})
            
            # Add trends to open boundary DIC and TA
            if b == 'open' and v in ['O3_c', 'O3_TA']:
                # Normalise to salinity of 35 PSU
                dat = 35.0*ds[v]/ds_phys.vosaline

                if v == 'O3_c':
                    # DIC trend, different for arctic boundary
                    trend = xr.where(bdy_depth.nav_lat>64, 0.77692*np.exp(-3.42965e-4*ds.gdept),
                                             0.96805*np.exp(-5.19414e-4*ds.gdept))
                else:
                    # TA trend, different for arctic boundary
                    trend = xr.where(bdy_depth.nav_lat>64, -0.63186*np.exp(-1.27709e-2*ds.gdept),
                                             0.18086*np.exp(-1.81059e-4*ds.gdept))

                # Apply trend, centered in 2002
                dat = dat + (trend * ((y+(ds.time_counter-0.5)/12) - (2002.5)))
                
                # Convert back to variable salinity
                ds[v] = dat*ds_phys.vosaline/35.0
            
            # Replace baltic DIC and TA with salinity based relationship
            if b == 'skag' and v in ['O3_c', 'O3_TA']:
                if v == 'O3_c':
                    ds[v] = (23.767*ds_phys.vosaline + 1388.0) * ds_phys.density/1000.0 #umol/kg to mmol/m3
                else:
                    ds[v] = (25.406*ds_phys.vosaline + 1410.15) * ds_phys.density/1000.0 #umol/kg to mmol/m3

        print('Saving year '+str(y))
        ds = ds.transpose('time_counter','zb','yb','xb')
        ds.to_netcdf(bconf['output_folder']+bconf['filename_prefix']+'_y'+str(y)+'.nc',unlimited_dims='time_counter')
