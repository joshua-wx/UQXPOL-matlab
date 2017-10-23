
##############################################################################
#
# Joshua Soderholm, 2017
#
# WHAT: generates a series of ppi images on maps using pyart from a odimh5 ppi scan
#
# INPUTS
# h5_ffn:      full file path to odimh5 input file
# plt_folder:  folder for plot file
#
# 
##############################################################################

#import libraries
import sys
import matplotlib as mpl
mpl.use('Agg')
from matplotlib import pyplot as plt
import pyart
import numpy as np
import cartopy.io.img_tiles as cimgt
import cartopy.crs as ccrs


#field ranges
dbz_min  = 25
dbz_max  = 65
dbz_cmap = 'pyart_NWSRef'
vel_min  = -20
vel_max  = 20
vel_cmap = 'pyart_BuDRd18'
spw_min  = 0
spw_max  = 5
spw_cmap = 'Reds'
zdr_min  = -1
zdr_max  = 6
zdr_cmap = 'jet'
kdp_min  = -1
kdp_max  = 6
kdp_cmap = 'jet'
cc_min   = 0
cc_max   = 1
cc_cmap  = 'jet'

#assign args
h5_ffn      = sys.argv[1]
plt_folder  = sys.argv[2]

#vars
axis_sz     = [12, 9]

#read file
radar = pyart.aux_io.read_odim_h5(h5_ffn, file_field_names=True)

#rename fields
radar.fields['DBZH']['standard_name'] = 'Reflectivity'
radar.fields['DBZH']['units'] = 'dBZ'
radar.fields['DBZH']['long_name'] = 'Reflectivity'
radar.fields['VRADH']['standard_name'] = 'Doppler Velocity'
radar.fields['VRADH']['units'] = 'm/s'
radar.fields['VRADH']['long_name'] = 'Doppler Velocity'
radar.fields['WRADH']['standard_name'] = 'Spectral Width'
radar.fields['WRADH']['units'] = 'm/s'
radar.fields['WRADH']['long_name'] = 'Spectral Width'
radar.fields['ZDR']['standard_name'] = 'Differential Reflectivity'
radar.fields['ZDR']['units'] = 'dB'
radar.fields['ZDR']['long_name'] = 'Differential Reflectivity'
radar.fields['KDP']['standard_name'] = 'Specific Differential Phase'
radar.fields['KDP']['units'] = 'degree/km'
radar.fields['KDP']['long_name'] = 'Specific Differential Phase'
radar.fields['RHOHV']['standard_name'] = 'Correlation Coefficient'
radar.fields['RHOHV']['units'] = ''
radar.fields['RHOHV']['long_name'] = 'Correlation Coefficient'

#exclude mask
gatefilter = pyart.correct.GateFilter(radar)
gatefilter.exclude_below('DBZH',dbz_min)

#call display
display = pyart.graph.RadarMapDisplayCartopy(radar)

def plot_ppi(display,field,vmin,vmax,cmap,gatefilter):
    #generate figure
    fig = plt.figure(figsize=axis_sz)
    ax  = plt.subplot(projection = ccrs.PlateCarree())
    #generate plot
    display.plot_ppi_map(field, sweep=0, ax=ax,
             vmin=vmin, vmax=vmax, cmap=cmap,
	     gatefilter=gatefilter, resolution = '10m',embelish=False)

    #Range Rings
    display.plot_range_rings([10,20,30,40,50], ax=ax, col='0.5', ls='--', lw=1)
    #OSM layers
    request = cimgt.OSM()
    ax.add_image(request, 9, zorder = 0)
    #output
    out_fn = plt_folder + field + '.png'
    plt.tight_layout()
    plt.savefig(out_fn, dpi=75)


plot_ppi(display,'DBZH',dbz_min,dbz_max,dbz_cmap,gatefilter)
plot_ppi(display,'VRADH',vel_min,vel_max,vel_cmap,gatefilter)
#plot_ppi(display,'WRADH',spw_min,spw_max,spw_cmap,gatefilter)
plot_ppi(display,'ZDR',zdr_min,zdr_max,zdr_cmap,gatefilter)
plot_ppi(display,'KDP',kdp_min,kdp_max,kdp_cmap,gatefilter)
#plot_ppi(display,'RHOHV',cc_min,cc_max,cc_cmap,gatefilter)

