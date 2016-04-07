function radar_struct=calc_smth_data(radar_struct)
%% Development code for Smoothing Data Along Radial
% Andrew Lowry, Apr-2016
% Climate Research Group, University of Queensland

%WHAT
% Smoothes Zhh (11gates), Zdr & Rho (21 gates) along the radial
% Outputs radar_struct with smoothed Zhh, Zdr & Rho fields

%HOW
% Load a radar struct using read_wr2100binary or read_odimh5 into matlab
% and pass radar_struct into this function. Save updated radar struct using
% write_odimh5

%REFS
% Based on Park et al. 2009 The Hydrometeor Classification Algorithm for 
% the Polarimetric WSR-88D: Description and Application to an MCS

%% Get Data

zhh_field  = find_data_idx(radar_struct,'DBZH');
zhh        = radar_struct.(zhh_field).data;
zdr_field  = find_data_idx(radar_struct,'ZDR');
zdr        = radar_struct.(zdr_field).data;
rho_field  = find_data_idx(radar_struct,'RHOHV');
rho        = radar_struct.(rho_field).data;
N = size(zhh);

% Remove nans from start of data
nan_idx=find(~isnan(zhh(1,:)),1,'first'); %usually 3
zhh_nan = zhh(:,nan_idx:end);
zdr_nan = zdr(:,nan_idx:end);
rho_nan = rho(:,nan_idx:end);

% Kernel for convolution
kernel_11 = ones(1,11)/11; %for Zhh
kernel_21 = ones(1,21)/21; %for Zdr & Rho

% Filter Zhh
zhh_mean_s=mean(zhh_nan(:,5:10),2); zhh_mean_e=mean(zhh_nan(:,end-4:end),2); 
zhh_pad=[repmat(zhh_mean_s,1,5),zhh_nan,repmat(zhh_mean_e,1,5)];
zhh_filt=conv2(zhh_pad,kernel_11,'same');
zhh_out=[nan(N(1,1),2),zhh_filt(:,6:end-5)];

% Filter Zdr
zdr_mean_s=mean(zdr_nan(:,5:10),2); zdr_mean_e=mean(zdr_nan(:,end-4:end),2);
zdr_pad=[repmat(zdr_mean_s,1,10),zdr_nan,repmat(zdr_mean_e,1,10)];
zdr_filt=conv2(zdr_pad,kernel_21,'same');
zdr_out=[nan(N(1,1),2),zdr_filt(:,11:end-10)];

% Filter Rho
rho_mean_s=mean(rho_nan(:,5:10),2); rho_mean_e=mean(rho_nan(:,end-4:end),2);
rho_pad=[repmat(rho_mean_s,1,10),rho_nan,repmat(rho_mean_e,1,10)];
rho_filt=conv2(rho_pad,kernel_21,'same'); 
rho_out=[nan(N(1,1),2),rho_filt(:,11:end-10)];

% Output Data
radar_struct.(zhh_field).data=zhh_out;
radar_struct.(zdr_field).data=zdr_out;
radar_struct.(rho_field).data=rho_out;

end