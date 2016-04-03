function radar_struct = calc_attenuation(radar_struct)
%% Development code for Attenuation Correction
% Andrew Lowry, Mar-2016
% Climate Research Group, University of Queensland

%WHAT
% Corrects Zhh & Zdr for attenuation based on self-consistency principles.
% Outputs radar_struct with corrected Zhh & Zdr fields

%HOW
% Load a radar struct using read_wr2100binary or read_odimh5 into matlab
% and pass radar_struct into this function. Save updated radar struct using
% write_odimh5

%REFS
% Based on Park et al. 2005 Pt I & Pt II, and Bringi & Chandrasekar 2001

%% Read config file
read_config('../etc/att_calc.config','att_calc.config.mat');%'../etc/gc_calc.config','gc_calc.config.mat'
load('att_calc.config.mat');

%% Get data from struct

%add data_var field to datasets in struct (apply offset and scaling)
radar_struct     = calc_vars(radar_struct);

% we'll need to check the data# position of new_phi
data_field = find_data_idx(radar_struct,'DBZH');
zhh        = radar_struct.(data_field).data_var;
data_field = find_data_idx(radar_struct,'ZDR');
zdr        = radar_struct.(data_field).data_var;
data_field = find_data_idx(radar_struct,'RHOHV');
rho        = radar_struct.(data_field).data_var;
data_field = find_data_idx(radar_struct,'PHIDP');
phi        = radar_struct.(data_field).data_var; %use old phi for now
% set range vector
rng=0.3:0.1:size(zhh,2)/10; %starts from 300m as there are 2xnan in each radar variable which are removed later

%load custom noise calibration file
noise_mean=load(noise_mean_ffn); noise=noise_mean.data;

%% correct zhh where zhh < noise - a problem for 1 May 2015 data
% we'll be able to remove this in later versions
[yr,mo,dd,~,~,~]=datevec(radar_struct.header.rec_utc_datetime);
if (yr==2015 && mo==5 && dd==1)||(yr==2015 && mo==4 && dd==30)
noise_grid=repmat(noise,size(zhh,1),1);
zhh_s=zhh(:,1:33); 
zhh_l=zhh(:,34:end);
noise_s=noise_grid(:,1:33); 
noise_l=noise_grid(:,34:end);
noise_s_val=radar_struct.header.puls_noise;
noise_l_val=radar_struct.header.freq_noise;

noise_s_end=noise_s-5; %there issues in the short pulse range so for safety use noise -5 %noise_s_end(:,25:33)=noise_s_end(:,25:33)-5; 
noise_l_start=noise_l;
noise_l_start(:,1:3)=noise_l_start(:,1:3)-5; %there are a couple of issues in the first few terms in the long pulse.
zhh_idx_s=zhh_s<noise_s_end; 
zhh_idx_l=zhh_l<noise_l_start;

zhh_cor_s=zhh_s; 
zhh_cor_l=zhh_l;
zhh_cor_s(zhh_idx_s)=noise_s(zhh_idx_s)+(zhh_cor_s(zhh_idx_s)-noise_s_val);
zhh_cor_l(zhh_idx_l)=noise_l(zhh_idx_l)+(zhh_cor_l(zhh_idx_l)-noise_l_val);
zhh=[zhh_cor_s,zhh_cor_l];
end

%% smooth data - zhh, zdr & rho
% leave this here for now, but in the future we should call smooth_data.m
% before we call calc_attenuation.m
% 1km (11 gates) for zhh
% 2km (21 gates) for zdr & rho
% see Park et al. 2008 sec 2a pg 732
kernel_11=ones(1,11)/11; kernel_21=ones(1,21)/21;
zhh_nan=zhh(:,3:end); %remove nan in first two cols
% we need to pad variables due to issues with zero padding by conv2, we also
% take the mean from 500m - 1km as the radar takes a few gates to get going
zhh_mean_s=mean(zhh_nan(:,5:10),2); zhh_mean_e=mean(zhh_nan(:,end-4:end),2); 
zhh_nan=[repmat(zhh_mean_s,1,5),zhh_nan,repmat(zhh_mean_e,1,5)];
zhh_filt=conv2(zhh_nan,kernel_11,'same');
zhh_filt=[nan(size(zhh,1),2),zhh_filt(:,6:end-5)];
zdr_nan=zdr(:,3:end);
zdr_mean_s=mean(zdr_nan(:,5:10),2); zdr_mean_e=mean(zdr_nan(:,end-4:end),2);
zdr_nan=[repmat(zdr_mean_s,1,10),zdr_nan,repmat(zdr_mean_e,1,10)];
zdr_filt=conv2(zdr_nan,kernel_21,'same');
zdr_filt=[nan(size(zdr,1),2),zdr_filt(:,11:end-10)];
rho_nan=rho(:,3:end);
rho_mean_s=mean(rho_nan(:,5:10),2); rho_mean_e=mean(rho_nan(:,end-4:end),2);
rho_nan=[repmat(rho_mean_s,1,10),rho_nan,repmat(rho_mean_e,1,10)];
rho_filt=conv2(rho_nan,kernel_21,'same'); 
rho_filt=[nan(size(rho,1),2),rho_filt(:,11:end-10)];
% reset variables
zhh=zhh_filt;
zdr=zdr_filt;
rho=rho_filt;

%% Attenuation procedure
% coefficients from Table 1. Park et al. 2005 Pt I
alpha_rng=0.025:0.025:0.575; % range of alpha values from Park et al. 2005 Pt II. Range from Park et al. 2005 Pt I is alpha_rng=0.139:0.01:0.335;
b=0.780;  %c=1.143; % a=1.3673e-4; %(not used)
p=0.051; %eq 1 Park et al. 2005 Pt II. Could also use p=5.28e-2; % Andsager fit to Fig 5 in Park et al. 2005 Pt I
q=0.486; %eq 1 Park et al. 2005 Pt II. Could also use q=0.511;

% Determine SNR
SNR=zhh-repmat(noise,size(zhh,1),1);
snr_thres=SNR>=snr_level; %set logical of values to keep

nhood=ones(1,9); % 9 gates (900m) for start of rain cells
nhood5=ones(1,5);% 5 gates (500m) for end of rain cells

%% loop over each radar ray (i) & over rain cells (k) within each ray
zhh_out=nan(size(zhh)); zdr_out=zhh_out;
for i=1:size(zhh,1)
%i=1273;

% build convolution for rho
rho_thres=rho(i,3:end)>0.7; 
% convolution for 9 (900m) gates -  must be odd
rho_pad_s=mean(rho_thres(1:9)); %find the initial trend
if rho_pad_s<0.5; rho_pad_s=zeros(1,4); else rho_pad_s=ones(1,4); end % vector to pad
rho_pad_e=mean(rho_thres(end-8:end)); %find the final trend
if rho_pad_e<0.5; rho_pad_e=zeros(1,4); else rho_pad_e=ones(1,4); end % vector to pad
rho_conv=conv2([rho_pad_s,double(rho_thres),rho_pad_e],nhood,'same'); %do convolution with padding
rho_conv=rho_conv(5:end-4); % remove padding  % rho_conv=rho_conv(length(nhood):end);
% convolution for 5 (500m) gates
rho_pad_s_5=mean(rho_thres(1:5)); %find the initial trend
if rho_pad_s_5<0.5; rho_pad_s_5=zeros(1,2); else rho_pad_s_5=ones(1,2); end % vector to pad
rho_pad_e_5=mean(rho_thres(end-4:end)); %find the final trend
if rho_pad_e_5<0.5; rho_pad_e_5=zeros(1,2); else rho_pad_e_5=ones(1,2); end % vector to pad
rho_conv_5=conv2([rho_pad_s_5,double(rho_thres),rho_pad_e_5],nhood5,'same'); %do convolution with padding
rho_conv_5=rho_conv_5(3:end-2); % remove padding

% we'd like to use phi to replicate Park et al. 2005 Part II but it doesn't
% work as we don't have raw phidp. See pg 1637 at the end of sec. 3
% phi_thres=stdfilt(phi(i,3:end),nhood); %can't use std(phi) as I think we need raw phidp

% build convolution for snr (instead of phi)
% convolution for 9 (900m) gates -  must be odd
snr_pad_s=mean(snr_thres(i,3:11)); %find the initial trend
if snr_pad_s<0.5; snr_pad_s=zeros(1,4); else snr_pad_s=ones(1,4); end % vector to pad
snr_pad_e=mean(snr_thres(i,end-8:end)); %find the final trend
if snr_pad_e<0.5; snr_pad_e=zeros(1,4); else snr_pad_e=ones(1,4); end % vector to pad
snr_conv=conv2([snr_pad_s,double(snr_thres(i,3:end)),snr_pad_e],nhood,'same'); %do convolution with padding
snr_conv=snr_conv(5:end-4); % remove padding
% convolution for 5 (500m) gates
snr_pad_s_5=mean(snr_thres(i,3:7)); %find the initial trend
if snr_pad_s_5<0.5; snr_pad_s_5=zeros(1,2); else snr_pad_s_5=ones(1,2); end % vector to pad
snr_pad_e_5=mean(snr_thres(i,end-4:end)); %find the final trend
if snr_pad_e_5<0.5; snr_pad_e_5=zeros(1,2); else snr_pad_e_5=ones(1,2); end % vector to pad
snr_conv_5=conv2([snr_pad_s_5,double(snr_thres(i,3:end)),snr_pad_e_5],nhood5,'same'); %do convolution with padding
snr_conv_5=snr_conv_5(3:end-2); % remove padding

%% Create vector(s) that are the start and end of the rain cells for each ray
% initialise variables
inside_rain=0; rain_start=[];rain_end=[];
for j=1:size(zhh,2)-2
    if snr_conv(j)>=5 && rho_conv(j)>=5 && inside_rain==0 % take the start of a rain cell to be >5 consequtive gates with snr>5 & rho>0.7
        inside_rain=1; %we're now in a rain cell
        rain_start=[rain_start,j]; %add start point of rain cell
    elseif (snr_conv_5(j)<=1 || rho_conv_5(j)<=1) && inside_rain==1 %take the end of a rain cell to be >5 consecutive gates with snr<5 and rho<0.7 
        inside_rain=0; %we're now out of a rain cell
        rain_end=[rain_end,j-1]; %add end point of rain cell
    end
end
% if the rain cell extends to the range limit of the radar, the above loop
% won't detect the end of the rain cell, so we insert it here.
if length(rain_start) ~= length(rain_end)
    rain_end=[rain_end,j];
end
% there can be cases when a rain cell starts and stops at the same pixel,
% because of the way the conv works. To eliminate these instances (as they
% cause problems in the k loop) we eliminate them here. This has the
% effect of eliminating either 1 pixel rain cells (probably not a rain 
% cell), or starting a rain cell 2 gates later than it might have.
idx=1;
while idx <= length(rain_start)
    if rain_start(idx)==rain_end(idx)
        rain_start(idx)=[]; %remove 1 pixel rain cells
        rain_end(idx)=[];
        idx=idx-1; %need to decrement idx to check all the cells
    end
    idx=idx+1;
end

%% iterate over each rain cell and do attenuation algorithm
no_cells=size(rain_start,2); %number of rain cells
zhh_lin=10.^(0.1.*zhh(i,3:end)); %zhh in linear units
phi_zero=phi(i,3:end)-phi(i,3); %reset phi to start from zero
for k=1:no_cells
    r1=rain_start(k); % use variable names from 
    r0=rain_end(k);   % Park et al. 2005 Part I
    % calculate eq 4a for the rain cell
    I4a=0.46.*b.*trapz(rng(r1:r0),zhh_lin(r1:r0).^b);
    % calculate delta(phidp) for the rain cell
    del_phi=phi_zero(r0)-phi_zero(r1);
    if del_phi==0; del_phi=1e-4; end %reset del_phi to avoid inf in gamma_opt
    % see Sec 3 Park et al. 2005 Pt II, for small rain cells where 
    % del_phi<=10 use alpha=0.275 and beta=0.029
    if del_phi<=10
    % initialise loop variables
    Ah=zeros(1,length(r1:r0));
    phi_cal=Ah; int_Ah=Ah; %phi_err=zeros(1,1);
    l=11; %alpha_rng = 0.275 see Sec 3 Park et al. 2005 Pt II
    for j=r1:r0 %loop over r in the rain cell
        if j==r0
            I4b=0; %can't integrate last cell in vector i.e. zero width
        else
            I4b=0.46.*b.*trapz(rng(j:r0),zhh_lin(j:r0).^b); %eq 4b
        end
        Ah(1,j-r1+1)=((zhh_lin(j).^b).*(10.^(0.1.*b.*alpha_rng(l).*del_phi) - 1))./...
            (I4a + (10.^(0.1.*b.*alpha_rng(l).*del_phi) - 1).*I4b);%eq 3        
        if j==r1 % we can't store a value in the first instance as trapz needs two data points
            continue
        else
            int_Ah(1,j-r1+1)=trapz(rng(r1:j),Ah(1,r1-r1+1:j-r1+1));
            phi_cal(1,j-r1+1)=2.*trapz(rng(r1:j),Ah(1,r1-r1+1:j-r1+1)./alpha_rng(l)); %eq 7
        end
    end % end j loop
    phi_err=sum(abs(bsxfun(@minus,phi_cal(1,:),phi_zero(r1:r0)))); %eq 8
    
    alpha_min=11; %alpha = 0.275
    % correct atteunation using appropriate alpha
    zhh_cor=bsxfun(@plus,zhh(i,r1+2:r0+2),2.*int_Ah(1,r1-r1+1:r0-r1+1)); %eq 1
    % Set zdr(r0) from eq 14
    if zhh_cor(r0-r1+1)<=10
        zdr_r0=0;
    elseif zhh_cor(r0-r1+1)>55
        zdr_r0=2.3;
    else
        zdr_r0=p*zhh_cor(r0-r1+1)-q;
    end
    % use relation Adp=0.029*Kdp from Park et al. 2005 Pt II where 
    % beta=0.029 and eq 7.157 of Bringi & Chandrasekar 2001
    gamma_opt=0.029/alpha_rng(alpha_min); % gamma=beta/alpha
    zdr_cor=bsxfun(@plus,zdr(i,r1+2:r0+2),2*gamma_opt.*int_Ah(1,r1-r1+1:r0-r1+1)); %eq 12
    
    else %del_phi>10
    % initialise loop variables
    Ah=zeros(length(alpha_rng),length(r1:r0));
    phi_cal=Ah; int_Ah=Ah; phi_err=zeros(1,length(alpha_rng));
    for l=1:length(alpha_rng) %loop over alpha
    for j=r1:r0 %loop over r in the rain cell
        if j==r0
            I4b=0; %can't integrate last cell in vector i.e. zero width
        else
            I4b=0.46.*b.*trapz(rng(j:r0),zhh_lin(j:r0).^b); %eq 4b
        end
        Ah(l,j-r1+1)=((zhh_lin(j).^b).*(10.^(0.1.*b.*alpha_rng(l).*del_phi) - 1))./...
            (I4a + (10.^(0.1.*b.*alpha_rng(l).*del_phi) - 1).*I4b);%eq 3        
        if j==r1 % we can't store a value in the first instance as trapz needs two data points
            continue
        else
            int_Ah(l,j-r1+1)=trapz(rng(r1:j),Ah(l,r1-r1+1:j-r1+1));
            phi_cal(l,j-r1+1)=2.*trapz(rng(r1:j),Ah(l,r1-r1+1:j-r1+1)./alpha_rng(l)); %eq 7
        end
    end % end j loop
    phi_err(l)=sum(abs(bsxfun(@minus,phi_cal(l,:),phi_zero(r1:r0)))); %eq 8
    end % end l loop
    [~,alpha_min]=min(phi_err); %index of minimum error
    % correct atteunation using appropriate alpha
    zhh_cor=bsxfun(@plus,zhh(i,r1+2:r0+2),2.*int_Ah(alpha_min,r1-r1+1:r0-r1+1)); %eq 1
    % Set zdr(r0) from eq 14
    if zhh_cor(r0-r1+1)<=10
        zdr_r0=0;
    elseif zhh_cor(r0-r1+1)>55
        zdr_r0=2.3;
    else
        zdr_r0=p*zhh_cor(r0-r1+1)-q;
    end
    gamma_opt=abs(zdr(i,r0+2)-zdr_r0)/(alpha_rng(alpha_min)*del_phi); %eq 11
    zdr_cor=bsxfun(@plus,zdr(i,r1+2:r0+2),2*gamma_opt.*int_Ah(alpha_min,r1-r1+1:r0-r1+1)); %eq 12
    
    end %end if del_phi<=10
    zhh_out(i,r1+2:r0+2)=zhh_cor;
    zdr_out(i,r1+2:r0+2)=zdr_cor;
end %end of rain cell

end %end of scan file
%% Output data
% don't add new fields, instead replace zhh & zdr
radar_struct.data5.data=zhh_out;
radar_struct.data7.data=zdr_out;
end