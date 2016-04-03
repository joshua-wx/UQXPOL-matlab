function data_struct = calc_vars(data_struct)
%Andrew Lowry, April 2016
%Climate Research Group, University of Queensland

%%WHAT: Calculate radar variables using offset and gain values, then saves them to the field data_var

% Rain
rain_data   = data_struct.data4.data;
rain_nodata = data_struct.data4.nodata;
rain_offset = data_struct.data4.offset;
rain_gain   = data_struct.data4.gain;
rain_data(rain_data==rain_nodata) = NaN;
rain_var    = rain_gain.*rain_data + rain_offset;

% Zhh
zhh_data   = data_struct.data5.data;
zhh_nodata = data_struct.data5.nodata;
zhh_offset = data_struct.data5.offset;
zhh_gain   = data_struct.data5.gain;
zhh_data(zhh_data==zhh_nodata) = NaN;
zhh_var    = zhh_gain.*zhh_data + zhh_offset;

% Vel
vel_data   = data_struct.data6.data;
vel_nodata = data_struct.data6.nodata;
vel_offset = data_struct.data6.offset;
vel_gain   = data_struct.data6.gain;
vel_data(vel_data==vel_nodata) = NaN;
vel_var    = vel_gain.*vel_data + vel_offset;

% Zdr
zdr_data   = data_struct.data7.data;
zdr_nodata = data_struct.data7.nodata;
zdr_offset = data_struct.data7.offset;
zdr_gain   = data_struct.data7.gain;
zdr_data(zdr_data==zdr_nodata) = NaN;
zdr_var    = zdr_gain.*zdr_data + zdr_offset;

% Kdp
kdp_data   = data_struct.data8.data;
kdp_nodata = data_struct.data8.nodata;
kdp_offset = data_struct.data8.offset;
kdp_gain   = data_struct.data8.gain;
kdp_data(kdp_data==kdp_nodata) = NaN;
kdp_var    = kdp_gain.*kdp_data + kdp_offset;

% Phi
phidp_data   = data_struct.data9.data;
phidp_nodata = data_struct.data9.nodata;
phidp_offset = data_struct.data9.offset;
phidp_gain   = data_struct.data9.gain;
phidp_data(phidp_data==phidp_nodata) = NaN;
phidp_var   = phidp_gain.*phidp_data + phidp_offset;

% Rho
rhohv_data   = data_struct.data10.data;
rhohv_nodata = data_struct.data10.nodata;
rhohv_offset = data_struct.data10.offset;
rhohv_gain   = data_struct.data10.gain;
rhohv_data(rhohv_data==rhohv_nodata) = NaN;
rhohv_var   = rhohv_gain.*rhohv_data + rhohv_offset;

% Spec Width
specwidth_data   = data_struct.data11.data;
specwidth_nodata = data_struct.data11.nodata;
specwidth_offset = data_struct.data11.offset;
specwidth_gain   = data_struct.data11.gain;
specwidth_data(specwidth_data==specwidth_nodata) = NaN;
specwidth_var    = specwidth_gain.*specwidth_data + specwidth_offset;

% save changes to data_var field
data_struct.data4.data_var   = rain_var;
data_struct.data5.data_var   = zhh_var;
data_struct.data6.data_var   = vel_var;
data_struct.data7.data_var   = zdr_var;
data_struct.data8.data_var   = kdp_var;
data_struct.data9.data_var   = phidp_var;
data_struct.data10.data_var  = rhohv_var;
data_struct.data11.data_var  = specwidth_var;
end

