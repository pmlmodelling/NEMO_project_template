'''
Script to create initial conditions
'''

import yaml
import xarray as xr
import numpy as np
import gsw

# Open yaml file with configuration
with open('2_make_IC_file.yaml','r') as yamlfile:
    yconf = yaml.safe_load(yamlfile)

#Load grid
grd = xr.open_dataset(yconf['domainfile'])

####################################
# Create output dataset
outfile = yconf['outfile']
ds = xr.Dataset(coords={'time_counter': xr.DataArray(dims=["t"],data=np.asarray([1])),'depth':grd.nav_lev,'nav_lon':grd.nav_lon,'nav_lat':grd.nav_lat})

# Load interpolated input file
ds_i = xr.open_dataset(yconf['inputfile'])

#Make Density
ds_phys = xr.open_dataset(yconf['temfile']).rename({'deptht':'z'})
ds_phys['vosaline'] = xr.open_dataset(yconf['salfile'])['vosaline'].rename({'deptht':'z'})
ds_phys['abs_pres'] = (('z','y','x'),gsw.p_from_z(-grd.gdept_0.isel(t=0), grd.nav_lat).data)
ds_phys['abs_sal'] = (('z','y','x'),gsw.SA_from_SP(ds_phys.vosaline, ds_phys.abs_pres, grd.nav_lon, grd.nav_lat).data)
ds_phys['con_temp'] = (('z','y','x'),gsw.CT_from_pt(ds_phys.abs_sal, ds_phys.votemper).data)
ds_phys['density'] = (('z','y','x'),gsw.rho(ds_phys.abs_sal, ds_phys.con_temp, ds_phys.abs_pres).data)
ds_phys['density'] = ds_phys.density.assign_attrs({"units": "kg / m^3", "standard name": "In-situ density "})

# Load Shelf
shelf = xr.open_dataset(yconf['shelfmask'])['Shelf'].rename({'lat':'y','lon':'x'})

#Redfield ratios
c2n = (1.0/12.0)*(16.0/106.0) # CN redfield ratio (with conversion from mg to molC) 
c2p = (1.0/12.0)*(1.0/106.0) # CP redfield ratio 
c2s = (1.0/12.0)*(15.0/106.0) # CSi redfield ratio 

print('Compiling variables into '+outfile)
print('Pelagic:')

##########################
# Set Nutrients + Oxygen
# Source - WOA23
# Multiplied by density/1000 to convert units from umol/kg to mmol/m3
##########################
# Nitrate
print('   Nitrate')
ds['TRNN3_n'] = ds_i.N3_n.expand_dims(dim={'t':1})*ds_phys.density/1000.0

# Phosphate
print('   Phosphate')
ds['TRNN1_p'] = ds_i.N1_p.expand_dims(dim={'t':1})*ds_phys.density/1000.0

# Silicate
print('   Silicate')
ds['TRNN5_s'] = ds_i.N5_s.expand_dims(dim={'t':1})*ds_phys.density/1000.0

# Oxygen
print('   Dissolved Oxygen')
ds['TRNO2_o'] = ds_i.O2_o.expand_dims(dim={'t':1})*ds_phys.density/1000.0

################################################
# Set Alkalinity and Dissolved inorganic carbon
# Source - GLODAP
# Multiplied by density/1000 to convert units from umol/kg to mmol/m3
################################################

# Total Alkalinity
print('   Total Alkalinity')
ds['TRNO3_TA'] = ds_i.O3_TA.expand_dims(dim={'t':1})*ds_phys.density/1000.0

print('   DIC')
ds['TRNO3_c'] = ds_i.O3_c.expand_dims(dim={'t':1})*ds_phys.density/1000.0

##########################
# Set Light Attenuation
# Source - PML
##########################
print('   ADY') 
ds['TRNlight_ADY'] = ds_i.light_ADY.expand_dims(dim={'t':1,'z':ds.z.size})

##########################################################
# Set Ammonium & DOC
########################################################
unit = ds.TRNN3_n/ds.TRNN3_n

print('   Ammonium')
ds['TRNN4_n'] = 0.25 * ds.TRNN3_n 

print('   Dissolved Organic Carbon')
ds['TRNR1_c'] = 12 * unit
ds['TRNR1_n'] = c2n * ds['TRNR1_c']
ds['TRNR1_p'] = c2p * ds['TRNR1_c']

print('   Semi-labile Organic Carbon')
#Exponential decay from 20uM at the surface (LOCATE project)
ds['TRNR2_c'] = 20*12 * np.exp(grd.gdept_0*np.log(0.0033/(20*12))/1000.0)
ds['TRNR2_c'] = xr.where(grd.gdept_0.isel(t=0)>1000.0,0.0033,ds['TRNR2_c'])

print('   Semi-refractory Organic Carbon')
#Exponential decay from 10uM at the surface (LOCATE project)
ds['TRNR3_c'] = 10*12 * np.exp(grd.gdept_0*np.log(0.0033/(10*12))/1000.0)
ds['TRNR3_c'] = xr.where(grd.gdept_0.isel(t=0)>1000.0,0.0033,ds['TRNR3_c'])

print('   Calcite')
ds['TRNL2_c'] = 0.1 * unit

print('   Bacteria')
ds['TRNB1_c'] =  5 * unit 
ds['TRNB1_n'] =  0.0167 * ds['TRNB1_c'] # B1 qnc in fabm.yaml
ds['TRNB1_p'] =  0.0019 * ds['TRNB1_c'] # B1 qpc in fabm.yaml


########################################################
# Set phytoplankton values
# Source - OC-CCI monthly image for Chloraphyll
#          Chloraphyll conversion from NEMO-ERSEM 
#          Redfield ratio for nitrogen, phosphate, silicate
########################################################

print('   Phytoplankton')
# Set uniform down to pycnocline, exponentially step down below
ds_i['chl'] = ds_i.Chl_Tot.expand_dims(dim={'t':1,'z':ds.z.size}).copy()
decay_rate = 50

for i in ds.x:
    for j in ds.y:
        if not ds_phys.density.isel(z=0,x=i,y=j).isnull():
            k = int(ds_phys.density.isel(x=i,y=j).diff('z').argmax('z')) # Identify pycnocline
            dep = grd.gdept_0.isel(t=0,z=slice(k,None),y=j,x=i)
            py_chl = ds_i.chl.isel(t=0,z=k,x=i,y=j)
            ds_i['chl'][0,k:,j,i] = py_chl*np.exp(-1*(dep-dep[0])/decay_rate) 

# Split Chl using Brewin2010 Eq13-16
Chl_pn = 1.057*(1-np.exp(-0.851*ds_i.chl))
ds['TRNP1_Chl'] = 2.0/3.0 * (ds_i.chl - Chl_pn) #Split micro 21 into diatom and micro
ds['TRNP4_Chl'] = 1.0/3.0 * (ds_i.chl - Chl_pn)
ds['TRNP3_Chl'] = 0.107*(1-np.exp(-6.801*ds_i.chl))
ds['TRNP2_Chl'] = Chl_pn - ds.TRNP3_Chl

print('      Diatom')
ds['TRNP1_c'] = 25*ds.TRNP1_Chl # Chl:C = 0.04
ds['TRNP1_n'] = c2n * ds.TRNP1_c
ds['TRNP1_p'] = c2p * ds.TRNP1_c
ds['TRNP1_s'] = c2s * ds.TRNP1_c

print('      Nano')
ds['TRNP2_c'] = 50*ds.TRNP2_Chl # Chl:C = 0.02
ds['TRNP2_n'] = c2n * ds.TRNP2_c
ds['TRNP2_p'] = c2p * ds.TRNP2_c

print('      Pico')
ds['TRNP3_c'] = 80*ds.TRNP3_Chl # Chl:C = 0.0125
ds['TRNP3_n'] = c2n * ds.TRNP3_c
ds['TRNP3_p'] = c2p * ds.TRNP3_c

print('      Micro')
ds['TRNP4_c'] = 30*ds.TRNP4_Chl # Chl:C = 0.03
ds['TRNP4_n'] = c2n * ds.TRNP4_c
ds['TRNP4_p'] = c2p * ds.TRNP4_c

########################################################
# Set zooplankton and POM values

# Initial values for zooplankton are estimated from
# the ratio to phytoplankton in january output of a
# previous model run. Total zoo biomass was roughly
# 1/3 of total phytoplankton, split into
# 50% Z4, 10% Z5 and 40% Z6

# Initial values for POM are estimated from
# the ratio to DOM in january output of a
# previous model run. POM was roughly
# 1/20 of total DOM, split into
# 70% R4, 15% R6 and 15% R8

########################################################

print('   Zooplankton')
total_zoo_c = (ds['TRNP1_c'] + ds['TRNP2_c'] +
            ds['TRNP3_c'] + ds['TRNP4_c']) / 3.0

ds['TRNZ4_c'] = 0.5*total_zoo_c

ds['TRNZ5_c'] = 0.1*total_zoo_c
ds['TRNZ5_n'] = c2n*ds['TRNZ5_c']
ds['TRNZ5_p'] = c2p*ds['TRNZ5_c']

ds['TRNZ6_c'] = 0.4*total_zoo_c
ds['TRNZ6_n'] = c2n*ds['TRNZ6_c']
ds['TRNZ6_p'] = c2p*ds['TRNZ6_c']

print('   POM')
total_pom_c = (ds['TRNR1_c'] + ds['TRNR2_c']
                + ds['TRNR3_c']) / 20.0

ds['TRNR4_c'] = 0.7*total_pom_c
ds['TRNR4_n'] = c2n*ds['TRNR4_c']
ds['TRNR4_p'] = c2p*ds['TRNR4_c']

ds['TRNR6_c'] = 0.15*total_pom_c
ds['TRNR6_n'] = c2n*ds['TRNR6_c']
ds['TRNR6_p'] = c2p*ds['TRNR6_c']
ds['TRNR6_s'] = c2s*ds['TRNR6_c']

ds['TRNR8_c'] = 0.15*total_pom_c
ds['TRNR8_n'] = c2n*ds['TRNR8_c']
ds['TRNR8_p'] = c2p*ds['TRNR8_c']
ds['TRNR8_s'] = c2s*ds['TRNR8_c']

##########################################################

print('Filling Before Pelagic Fields')
fields = list(filter(lambda x: x.startswith('TRN'), ds.variables.keys()))
for i in fields:
    ds[i.replace('TRN','TRB')] = ds[i]

##########################################################
# Set Benthic Values
#########################################################
print('Benthic:')
pf = 'fabm_st2Dn'

##########################
# Set Inorganic Matter - 
# Nutrients, Oxygen, DIC and NO2
# Source - Approximate equilibrium concentration from lowest pelagic
#          including porosity and benthic thickness
##########################

bl = xr.where(grd.bottom_level==grd.z.size-1,grd.bottom_level-1,grd.bottom_level) #bottom pelagic index

p = 0.4 # From fabm.yaml
z = 0.3 # benthic thickness (m)

print('   Nutrients')
ds[pf+'K3_n'] = (1/p)*z*ds.TRNN3_n.isel(z=bl)
ds[pf+'K4_n'] = (1/p)*z*ds.TRNN4_n.isel(z=bl)
ds[pf+'K1_p'] = (1/p)*z*ds.TRNN1_p.isel(z=bl)
ds[pf+'K5_s'] = (1/p)*z*ds.TRNN5_s.isel(z=bl)
ds[pf+'G2_o'] = (1/p)*z*ds.TRNO2_o.isel(z=bl)
ds[pf+'G2_o_deep'] = 0*ds[pf+'G2_o']

print('   DIC')
ds[pf+'G3_c'] = (1/p)*z*ds.TRNO3_c.isel(z=bl)

print('   NO2')
ds[pf+'ben_nit_G4n'] = 0*ds[pf+'K3_n']

#######################################################
# Set zoobenthos, bacteria and organic matter
# Values set to constants estimated from a long simulation, 
# with separate on/off shelf values
########################################################

print('   Zoobenthos')
ds[pf+'Y2_c'] = xr.where(shelf==1,3000,0.1).expand_dims(dim={'t':1})
ds[pf+'Y3_c'] = xr.where(shelf==1,1500,0.1).expand_dims(dim={'t':1})
ds[pf+'Y4_c'] = xr.where(shelf==1,200,200).expand_dims(dim={'t':1})

print('   Bacteria')
ds[pf+'H1_c'] = xr.where(shelf==1,10,10).expand_dims(dim={'t':1})
ds[pf+'H2_c'] = xr.where(shelf==1,100,1).expand_dims(dim={'t':1})

print('   DOM')
ds[pf+'Q1_c'] = xr.where(shelf==1,30,1).expand_dims(dim={'t':1})
ds[pf+'Q1_n'] = c2n * ds[pf+'Q1_c']
ds[pf+'Q1_p'] = c2p * ds[pf+'Q1_c']

ds[pf+'Q6_c'] = xr.where(shelf==1,2000,500).expand_dims(dim={'t':1})
ds[pf+'Q6_n'] = c2n * ds[pf+'Q6_c']
ds[pf+'Q6_p'] = c2p * ds[pf+'Q6_c']
ds[pf+'Q6_s'] = c2s * ds[pf+'Q6_c']

ds[pf+'Q6_pen_depth_c'] = xr.where(shelf==1,0.03,0.03).expand_dims(dim={'t':1})
ds[pf+'Q6_pen_depth_n'] = ds[pf+'Q6_pen_depth_c']
ds[pf+'Q6_pen_depth_p'] = ds[pf+'Q6_pen_depth_c']
ds[pf+'Q6_pen_depth_s'] = ds[pf+'Q6_pen_depth_c']

ds[pf+'Q7_c'] = 15 * ds[pf+'Q6_c']
ds[pf+'Q7_n'] = 15 * ds[pf+'Q6_n']
ds[pf+'Q7_p'] = 15 * ds[pf+'Q6_p']

ds[pf+'Q7_pen_depth_c'] = xr.where(shelf==1,0.1,0.1).expand_dims(dim={'t':1})
ds[pf+'Q7_pen_depth_n'] = ds[pf+'Q7_pen_depth_c']
ds[pf+'Q7_pen_depth_p'] = ds[pf+'Q7_pen_depth_c']

ds[pf+'Q17_c'] = 0 * ds[pf+'Q6_c']
ds[pf+'Q17_n'] = 0 * ds[pf+'Q6_c']
ds[pf+'Q17_p'] = 0 * ds[pf+'Q6_c']

print('Horizons')
ds[pf+'ben_col_D1m'] = xr.where(shelf==1,0.05,0.01).expand_dims(dim={'t':1})
ds[pf+'ben_col_D2m'] = xr.where(shelf==1,0.25,0.10).expand_dims(dim={'t':1})

print('Calcite')
ds[pf+'bL2_c'] = 0 * ds[pf+'Q6_c'] + 0.1

#####################################################
print('Filling Before Benthic Fields')
fields = list(filter(lambda x: x.startswith('fabm_st2Dn'), ds.variables.keys()))
for i in fields:
    ds[i.replace('st2Dn','st2Db')] = ds[i]

# Add attributes
for v,vconf in yconf['variables'].items():
    ds[v] = ds[v].assign_attrs(vconf)
    ds[v].attrs['coordinates'] = 'time_counter nav_lat nav_lon' if v.startswith('fabm') \
                                else 'time_counter depth nav_lat nav_lon'
    ds[v] = ds[v].fillna(0)

# Clean up
ds = ds.drop_vars(['x','y','time','lat','lon'])
ds['kt'] = 0
ds = ds.transpose('t','z','y','x')

ds.to_netcdf(outfile,unlimited_dims='t')
print('Complete')
