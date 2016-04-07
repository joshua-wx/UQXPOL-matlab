function [ radar_struct ] = calc_vars( radar_struct )
%% Calculate radar variables

% Rain
rain_field=find_data_idx(radar_struct,'RATE');
rain_data=radar_struct.(rain_field).data;
rain_nodata=radar_struct.(rain_field).nodata;
rain_offset=radar_struct.(rain_field).offset;
rain_gain=radar_struct.(rain_field).gain;
rain_data(rain_data==rain_nodata) = NaN;
rain_data = rain_gain.*rain_data + rain_offset;

% Zhh
zhh_field = find_data_idx(radar_struct,'DBZH');
zhh_data=radar_struct.(zhh_field).data;
zhh_nodata=radar_struct.(zhh_field).nodata;
zhh_offset=radar_struct.(zhh_field).offset;
zhh_gain=radar_struct.(zhh_field).gain;
zhh_data(zhh_data==zhh_nodata) = NaN;
zhh_data = zhh_gain.*zhh_data + zhh_offset;

% Vel
vel_field = find_data_idx(radar_struct,'VRADH');
vel_data=radar_struct.(vel_field).data;
vel_nodata=radar_struct.(vel_field).nodata;
vel_offset=radar_struct.(vel_field).offset;
vel_gain=radar_struct.(vel_field).gain;
vel_data(vel_data==vel_nodata) = NaN;
vel_data = vel_gain.*vel_data + vel_offset;

% Zdr
zdr_field = find_data_idx(radar_struct,'ZDR');
zdr_data=radar_struct.(zdr_field).data;
zdr_nodata=radar_struct.(zdr_field).nodata;
zdr_offset=radar_struct.(zdr_field).offset;
zdr_gain=radar_struct.(zdr_field).gain;
zdr_data(zdr_data==zdr_nodata) = NaN;
zdr_data = zdr_gain.*zdr_data + zdr_offset;

% Kdp
kdp_field = find_data_idx(radar_struct,'KDP');
kdp_data=radar_struct.(kdp_field).data;
kdp_nodata=radar_struct.(kdp_field).nodata;
kdp_offset=radar_struct.(kdp_field).offset;
kdp_gain=radar_struct.(kdp_field).gain;
kdp_data(kdp_data==kdp_nodata) = NaN;
kdp_data = kdp_gain.*kdp_data + kdp_offset;

% Phi
phi_field = find_data_idx(radar_struct,'PHIDP');
phidp_data=radar_struct.(phi_field).data;
phidp_nodata=radar_struct.(phi_field).nodata;
phidp_offset=radar_struct.(phi_field).offset;
phidp_gain=radar_struct.(phi_field).gain;
phidp_data(phidp_data==phidp_nodata) = NaN;
phidp_data = phidp_gain.*phidp_data + phidp_offset;

% Rho
rho_field = find_data_idx(radar_struct,'RHOHV');
rhohv_data=radar_struct.(rho_field).data;
rhohv_nodata=radar_struct.(rho_field).nodata;
rhohv_offset=radar_struct.(rho_field).offset;
rhohv_gain=radar_struct.(rho_field).gain;
rhohv_data(rhohv_data==rhohv_nodata) = NaN;
rhohv_data = rhohv_gain.*rhohv_data + rhohv_offset;

% Spec Width
specwidth_field = find_data_idx(radar_struct,'WRADH');
specwidth_data=radar_struct.(specwidth_field).data;
specwidth_nodata=radar_struct.(specwidth_field).nodata;
specwidth_offset=radar_struct.(specwidth_field).offset;
specwidth_gain=radar_struct.(specwidth_field).gain;
specwidth_data(specwidth_data==specwidth_nodata) = NaN;
specwidth_data = specwidth_gain.*specwidth_data + specwidth_offset;

% save changes
radar_struct.(rain_field).data=rain_data;
radar_struct.(zhh_field).data=zhh_data;
radar_struct.(vel_field).data=vel_data;
radar_struct.(zdr_field).data=zdr_data;
radar_struct.(kdp_field).data=kdp_data;
radar_struct.(phi_field).data=phidp_data;
radar_struct.(rho_field).data=rhohv_data;
radar_struct.(specwidth_field).data=specwidth_data;
end

