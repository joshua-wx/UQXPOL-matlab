
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
sys.path.append('/home/meso/anaconda2/bin/python')
import matplotlib as mpl
mpl.use('Agg')
from matplotlib import pyplot as plt
from mpl_toolkits.basemap import Basemap
import pyart
import numpy as np


#field ranges
dbz_min = 25
dbz_max = 65
vel_min = -20
vel_max = 20
spw_min = 0
spw_max = 5
zdr_min = -1
zdr_max = 6
kdp_min = -1
kdp_max = 6
cc_min  = 0
cc_max  = 1

#assign args
h5_ffn      = sys.argv[1]
plt_folder  = sys.argv[2]

#vars
axis_sz     = [11.5, 9]
basemap_res = 'h' #h

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
display = pyart.graph.RadarMapDisplay(radar)

#lat/lon lines
lat_lines = np.arange(-29, -26, 0.2)
lon_lines = np.arange(150, 155, 0.2)


def plot_ppi(display,field,vmin,vmax,cmap,gatefilter):
    #generate figure
    fig = plt.figure(figsize=axis_sz)
    #generate plot
    display.plot_ppi_map(field, sweep=0,
             vmin=vmin, vmax=vmax, cmap=cmap, resolution = basemap_res, gatefilter=gatefilter,
             lat_lines = lat_lines, lon_lines=lon_lines)
    #output
    out_fn = plt_folder + field + '.png'
    plt.tight_layout()
    plt.savefig(out_fn, dpi=75)
    
plot_ppi(display,'DBZH',dbz_min,dbz_max,'pyart_NWSRef',gatefilter)
plot_ppi(display,'VRADH',vel_min,vel_max,'pyart_BuDRd12',gatefilter)
plot_ppi(display,'WRADH',spw_min,spw_max,'Reds',gatefilter)
plot_ppi(display,'ZDR',zdr_min,zdr_max,'jet',gatefilter)
plot_ppi(display,'KDP',kdp_min,kdp_max,'jet',gatefilter)
plot_ppi(display,'RHOHV',cc_min,cc_max,'jet',gatefilter)

