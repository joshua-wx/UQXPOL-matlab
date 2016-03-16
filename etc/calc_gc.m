function radar_struct = calc_gc(radar_struct)
%% Development code for GC and AP removal
% Andrew Lowry, Feb-2016
% Climate Research Group, University of Queensland

%WHAT
% Adds a precip and clutter field to radar_struct which contains a single scan

%HOW
% Load a radar struct using read_wr2100binary or read_odimh5 into matlab
% and pass radar_struct into this function. Save updated radar struct using
% write_odimh5

%REFS
% Based on Rico-Ramirez et al. 2008 and Gourley et al. 2007
% requires matlab simulink!

nds_gc_ffn     = '../etc/nds_GC.mat';
nds_precip_ffn = '../etc/nds_precip.mat';
noise_mean_ffn = '../etc/noise_mean.mat';
snr_level      = 10;

%% Load nds function data
load(nds_gc_ffn);
fszdr_nds_gc = out_data.fszdr;
fszhh_nds_gc = out_data.fszhh;
fsphi_nds_gc = out_data.fsphi;
fsrho_nds_gc = out_data.fsrho;
frho_nds_gc  = out_data.frho;
fvel_nds_gc  = out_data.fvel;

load(nds_precip_ffn);
fszdr_nds_pre = out_data.fszdr;
fszhh_nds_pre = out_data.fszhh;
fsphi_nds_pre = out_data.fsphi;
fsrho_nds_pre = out_data.fsrho;
frho_nds_pre  = out_data.frho;
fvel_nds_pre  = out_data.fvel;

%% Define density function vectors

xszdr = 0:0.01:10; %range of values for std(zdr) density function
xszhh = 0:0.01:30; %range of values for std(zhh) density function
xsphi = 0:0.01:150;%range of values for std(phi) density function
xsrho = 0:0.01:1;  %range of values for std(rho) density function
xrho  = 0:0.01:1.2; %range of values for rho density function
xvel  = -5:0.01:5;  %range of values for vel density function

%% Calculate area under non-precip and precip curve
% the grey area in Fig 3 from Gourley et al. 2007
% take the min of the two vectors, then calculate the area under this curve

A1 = trapz(xszdr,min([fszdr_nds_gc;fszdr_nds_pre])); %szdr
A2 = trapz(xszhh,min([fszhh_nds_gc;fszhh_nds_pre])); %szhh
A3 = trapz(xsphi,min([fsphi_nds_gc;fsphi_nds_pre])); %sphi
A4 = trapz(xsrho,min([fsrho_nds_gc;fsrho_nds_pre])); %srho
A5 = trapz(xrho,min([frho_nds_gc;frho_nds_pre]));    %rho
A6 = trapz(xvel,min([fvel_nds_gc;fvel_nds_pre]));    %vel

%% Calculate Weights for each variable
%eq. 4 in Gourley et al. 2007

w1 = (1/A1).*sum([1/A1,1/A2,1/A3,1/A4,1/A5,1/A6]); %std(zdr)
w2 = (1/A2).*sum([1/A1,1/A2,1/A3,1/A4,1/A5,1/A6]); %std(zhh)
w3 = (1/A3).*sum([1/A1,1/A2,1/A3,1/A4,1/A5,1/A6]); %std(phi)
w4 = (1/A4).*sum([1/A1,1/A2,1/A3,1/A4,1/A5,1/A6]); %std(rho)
w5 = (1/A5).*sum([1/A1,1/A2,1/A3,1/A4,1/A5,1/A6]); %rho
w6 = (1/A6).*sum([1/A1,1/A2,1/A3,1/A4,1/A5,1/A6]); %vel

display('check timing for possible preallocation')

%% Load data from struct

azi = radar_struct.data2.data;
elv = radar_struct.data3.data;
zhh = radar_struct.data5.data;
vel = radar_struct.data6.data;
zdr = radar_struct.data7.data;
phi = radar_struct.data9.data;
rho = radar_struct.data10.data;

data_size = size(zhh);

%load custom noise calibration file
noise_mean=load(noise_mean_ffn); noise_mean=noise_mean.data;
SNR=zhh-repmat(noise_mean,size(zhh,1),1);
snr_thres=SNR>=snr_level; %set logical of pixels to keep

%check gate resultion to adjust no_gates below (need to be 3deg x 1.1km)

%% Determine neighbourhood 3deg x 1.1km
d_azi=abs(nanmedian(diff(azi)));
no_gates=11; %must be odd, relies on gate_res=100m
no_azi= floor(3/d_azi);
N=no_gates*no_azi;
if mod(no_azi,2)== 0 %test if even
    no_azi=no_azi+1; %set to odd
end
nhood=ones(no_azi,no_gates); %neighbourhood of 3deg x 1.1km
%% Calculate additional fields
% std(zdr), std(zhh), std(phi), std(rho)

% Do convolution by ignoring nan's in calculation, see nanconv.m
% Calculate standard deviation in nhood using sigma=sqrt[(1/n-1)*(sum(x^2) - (sum(x)^2/n))]

% variables for all data types
N_div=conv2(double(snr_thres),nhood,'same'); %calculate number of non-nan values for each nhood
on=ones(data_size); %create matrix of ones
on(~snr_thres)=0; %set nans to 0
flat=conv2(on,nhood,'same');
% zhh
zhh_use=zhh; %zhh_use(~snr_thres)=nan;
zhh_use(~snr_thres)=0;
zhh_use2=zhh_use.*zhh_use; %zhh^2
zhc=conv2(zhh_use,nhood,'same')./flat;
zhc(~snr_thres)=nan; %figure; imagesc(c); colorbar; title('c'); %zhh_use2(~snr_thres)=0;
zhc2=conv2(zhh_use2,nhood,'same')./flat;
zhc2(~snr_thres)=nan; %figure; imagesc(c2); colorbar; title('c2');
zhh_std=sqrt((zhc2-(zhc.^2)./N_div)./(N_div-1)); 
% zdr
zdr_use=zdr;
zdr_use(~snr_thres)=0;
zdr_use2=zdr_use.*zdr_use; %zdr^2
zdc=conv2(zdr_use,nhood,'same')./flat;
zdc(~snr_thres)=nan; 
zdc2=conv2(zdr_use2,nhood,'same')./flat;
zdc2(~snr_thres)=nan; 
zdr_std=sqrt((zdc2-(zdc.^2)./N_div)./(N_div-1));
% phidp
phi_use=phi;
phi_use(~snr_thres)=0;
phi_use2=phi_use.*phi_use; %phi^2
pc=conv2(phi_use,nhood,'same')./flat;
pc(~snr_thres)=nan; 
pc2=conv2(phi_use2,nhood,'same')./flat;
pc2(~snr_thres)=nan; 
phi_std=sqrt((pc2-(pc.^2)./N_div)./(N_div-1));
% rhohv
rho_use=rho;
rho_use(~snr_thres)=0;
rho_use2=rho_use.*rho_use; %rho^2
rc=conv2(rho_use,nhood,'same')./flat;
rc(~snr_thres)=nan; 
rc2=conv2(rho_use2,nhood,'same')./flat;
rc2(~snr_thres)=nan; 
rho_std=sqrt((rc2-(rc.^2)./N_div)./(N_div-1));

%% Calculate the membership value for each pixel. That is for each pixel 
% calculate the f(x) for this pixel (actually just look it up) ,where f(x) 
% is the pdf/nds for std(zdr), std(zhh), std(phi), std(rho), rho, vel.

% szdr
zdr_std_use=zdr_std;
zdr_std_use(isnan(zdr_std))=0; %set nan = 0
fszdr_gc=fixpt_interp1(xszdr,fszdr_nds_gc,zdr_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fszdr_gc(isnan(zdr_std))=nan; %set 0 = nan
fszdr_pre=fixpt_interp1(xszdr,fszdr_nds_pre,zdr_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fszdr_pre(isnan(zdr_std))=nan; %set 0 = nan
% szhh
zhh_std_use=zhh_std;
zhh_std_use(isnan(zhh_std))=0; %set nan = 0
fszhh_gc=fixpt_interp1(xszhh,fszhh_nds_gc,zhh_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fszhh_gc(isnan(zhh_std))=nan; %set 0 = nan
fszhh_pre=fixpt_interp1(xszhh,fszhh_nds_pre,zhh_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fszhh_pre(isnan(zhh_std))=nan; %set 0 = nan
% sphi
phi_std_use=phi_std;
phi_std_use(isnan(phi_std))=0; %set nan = 0
fsphi_gc=fixpt_interp1(xsphi,fsphi_nds_gc,phi_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fsphi_gc(isnan(phi_std))=nan; %set 0 = nan
fsphi_pre=fixpt_interp1(xsphi,fsphi_nds_pre,phi_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fsphi_pre(isnan(phi_std))=nan; %set 0 = nan
% srho
rho_std_use=rho_std;
rho_std_use(isnan(rho_std))=0; %set nan = 0
fsrho_gc=fixpt_interp1(xsrho,fsrho_nds_gc,rho_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fsrho_gc(isnan(rho_std))=nan; %set 0 = nan
fsrho_pre=fixpt_interp1(xsrho,fsrho_nds_pre,rho_std_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fsrho_pre(isnan(rho_std))=nan; %set 0 = nan
% rho
rho_use1=rho; rho_use1(~snr_thres)=nan;
rho_use1(isnan(rho))=0; %set nan = 0
frho_gc=fixpt_interp1(xrho,frho_nds_gc,rho_use1,sfix(8),2^-3,sfix(16),2^-14,'Floor');
frho_gc(isnan(zdr_std))=nan; %set 0 = nan
frho_pre=fixpt_interp1(xrho,frho_nds_pre,rho_use1,sfix(8),2^-3,sfix(16),2^-14,'Floor');
frho_pre(isnan(zdr_std))=nan; %set 0 = nan
% vel
vel_use=vel; vel_use(~snr_thres)=nan;
vel_use(isnan(vel))=0; %set nan = 0
fvel_gc=fixpt_interp1(xvel,fvel_nds_gc,vel_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fvel_gc(isnan(vel))=nan; %set 0 = nan
fvel_pre=fixpt_interp1(xvel,fvel_nds_pre,vel_use,sfix(8),2^-3,sfix(16),2^-14,'Floor');
fvel_pre(isnan(vel))=nan; %set 0 = nan

% This should produce 2x6 values for the 2 classes GC, Precip.

%% Calculate the aggregation value Q for each pixel for each class: 
% Ground Clutter, Clear Air and Precipitation
% eq. 3 in Gourley et al. 2007

% Use the membership value from the previous step and apply the weights
% to calculate the aggregation value Q for each class, GC and precip.
clear Q1_mat; clear Q2_mat;
sum_w=sum([w1,w2,w3,w4,w5,w6]);
Q1_mat(:,:,1)=fszdr_pre.*w1; Q1_mat(:,:,2)=fszhh_pre.*w2;
Q1_mat(:,:,3)=fsphi_pre.*w3; Q1_mat(:,:,4)=fsrho_pre.*w4;
Q1_mat(:,:,5)=frho_pre.*w5;  Q1_mat(:,:,6)=fvel_pre.*w6;
Q1=sum(Q1_mat,3)./sum_w; % Q value for Precip
Q2_mat(:,:,1)=fszdr_gc.*w1; Q2_mat(:,:,2)=fszhh_gc.*w2;
Q2_mat(:,:,3)=fsphi_gc.*w3; Q2_mat(:,:,4)=fsrho_gc.*w4;
Q2_mat(:,:,5)=frho_gc.*w5;  Q2_mat(:,:,6)=fvel_gc.*w6;
Q2=sum(Q2_mat,3)./sum_w; % Q value for Ground Clutter

%% Determine the max Q of the three classes and assign the pixel as either
% GC or precip.
% logical
pre=Q1>Q2; % precip
gc=Q2>Q1;  % ground clutter

%% Reject class assignments using Table 1 from Gourley et al. 2007
% This step is not done in Rico-Ramirez et al 2008

rho_rej=rho<0.7; %reject any pixel with rho < 0.7 as ~ precip
pre(rho_rej)=0;
phi_rej=phi<179; %reject any pixel with phi < 179 as ~ precip
pre(phi_rej)=0;
zhh_rej=zhh<5; %reject any pixel with zhh < 5 as ~ precip
pre(zhh_rej)=0;
sphi_rej=phi_std>100; % reject any pixel with std(phi) > 100 as ~ precip
pre(sphi_rej)=0;
% need to insert pulse-to-pulse variability of zhh, but can't do it with
% data that has threshold which rejects some zhh data e.g. 1 May 2015 data.
% Also as noted in rico-ramirez s(zhh) can negate the need to apply this
% threshold.
% zhh_diff=diff(zhh,1,2); zhh_diff=[nan(size(zhh,1),1),zhh_diff];
% zhh_rej3=zhh_diff>5;
% gc(zhh_rej3)=0;
vel_rej=vel>5; % reject any pixel with vel > 5 as ~ GC
gc(vel_rej)=0;
% zhh_rej2=zhh>30; % reject any pixel with zhh > 30 as not clear air
% gc(zhh_rej2)=0;

%% Despeckle class fields
% Take a 3x3 grid around each pixel, excluding the central pixel.

% 1. If the centre pixel is classified as precip, but less than 3 of the 8
% neighbours are also precip, then reassign the pixel as clear air i.e. nan.
kernel=ones(3,3); kernel(2,2)=0;
pre_use=pre; pre_use(isnan(pre))=0; %set nan to zero for convolution
pre_conv=conv2(double(pre_use),kernel,'same');
pre_reclassify=and(pre_conv<3,pre==1); %are there < 3 pixels?
pre(pre_reclassify)=0; %reassign precipitation to nil

% 2. If the centre pixel is clear air, and more than 6 of the 8 
% neighbours are precip, then reassign the pixel as precip.
ca_use=~snr_thres; % get matrix of clear air pixels
ca_use(isnan(ca_use))=0; %set nan to zero for convolution
ca_conv=conv2(double(pre_use),kernel,'same');
ca_reclassify=and(ca_conv>6,ca_use==1); %are there > 6 pixels?
pre(ca_reclassify)=1; %reassign precip to 1


%% Add precip (pre) and GC (gc) filter to radar_struct
radar_struct=add_dataset_to_radar_struct(radar_struct,gc,'gc_mask',0,1);
radar_struct=add_dataset_to_radar_struct(radar_struct,pre,'precip_mask',0,1);
