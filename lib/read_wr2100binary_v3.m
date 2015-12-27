function radar_struct=read_wr2100binary_v3(binary_ffn)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: v3 updated Nov 2015 to read new header information regarding utc time and
%pulse specifications and QC data field. All files collected from 9/11/2015 onwards will
%require this reader. All files before this date use version 2

% Open file
fid = fopen(binary_ffn);

%Read Header (apply scaling)
header_size = fread(fid, 1, 'ushort'); %NOT SAVED
file_vrsion = fread(fid, 1, 'ushort');

file_year   = fread(fid, 1, 'ushort'); %NOT SAVED
file_month  = fread(fid, 1, 'ushort'); %NOT SAVED
file_day    = fread(fid, 1, 'ushort'); %NOT SAVED
file_hour   = fread(fid, 1, 'ushort'); %NOT SAVED
file_min    = fread(fid, 1, 'ushort'); %NOT SAVED
file_sec    = fread(fid, 1, 'ushort'); %NOT SAVED
file_datetime = datenum(file_year,file_month,file_day,file_hour,file_min,file_sec); %NOT SAVED

lat_deg     = fread(fid, 1, 'short');
lat_min     = fread(fid, 1, 'ushort');
lat_sec     = fread(fid, 1, 'ushort')/1000;
lat_dec     = dms2degrees([lat_deg,lat_min,lat_sec]);

lon_deg     = fread(fid, 1, 'short');
lon_min     = fread(fid, 1, 'ushort');
lon_sec     = fread(fid, 1, 'ushort')/1000;
lon_dec     = dms2degrees([lon_deg,lon_min,lon_sec]);

ant_alt_up  = fread(fid, 1, 'ushort');       %cm %NOT SAVED
ant_alt_low = fread(fid, 1, 'ushort');       %cm %NOT SAVED
ant_alt     = ant_alt_up*10000+ant_alt_low;  %m


ant_rot_spd = fread(fid, 1, 'ushort')/10;    %rpm
prf1        = fread(fid, 1, 'ushort')/10;    %Hz
prf2        = fread(fid, 1, 'ushort')/10;    %Hz
puls_noise  = fread(fid, 1, 'short')/100;    %dBm
freq_noise  = fread(fid, 1, 'short')/100;    %dBm
num_smpls   = fread(fid, 1, 'ushort');       %qty
num_gates   = fread(fid, 1, 'ushort');       %qty
gate_res    = fread(fid, 1, 'ushort')/100;   %m

const_horz_mantissa       = fread(fid, 1, 'long');  %NOT SAVED
const_horz_characteristic = fread(fid, 1, 'short'); %NOT SAVED
radar_horz_constant       = const_horz_mantissa * 10^const_horz_characteristic;
const_vert_mantissa       = fread(fid, 1, 'long');  %NOT SAVED
const_vert_characteristic = fread(fid, 1, 'short'); %NOT SAVED
radar_vert_constant       = const_vert_mantissa * 10^const_vert_characteristic;


azi_offset = fread(fid, 1, 'ushort')/100; %degTn

rec_utc_year = fread(fid, 1, 'ushort');
rec_utc_mon  = fread(fid, 1, 'ushort');
rec_utc_day  = fread(fid, 1, 'ushort');
rec_utc_hour = fread(fid, 1, 'ushort');
rec_utc_min  = fread(fid, 1, 'ushort');
rec_utc_sec  = fread(fid, 1, 'ushort');
rec_utc_datetime = datenum(rec_utc_year,rec_utc_mon,rec_utc_day,rec_utc_hour,rec_utc_min,rec_utc_sec);
rec_item     = fread(fid, 1, 'ushort');

tx_blind_rng  = fread(fid, 1, 'ushort'); %m
tx_pulse_spec = fread(fid, 1, 'ushort'); %1-10

%extract filename parts
[~,temp_name,scan_type]  = fileparts(binary_ffn);
scan_type = scan_type(2:end);
if strcmp(scan_type,'scn')
    scn_ppi_step  = str2num(temp_name(end-4:end-3)); %current ppi no in scn
    scn_ppi_total = str2num(temp_name(end-1:end));   %total number of ppi in scn
else
    scn_ppi_step  = nan;
    scn_ppi_total = nan;
end

%create empty data matricies
empty_vec = zeros(num_smpls,1);
empty_mat = zeros(num_smpls,num_gates);

%preallocate
radar_struct.data1  = struct('data',empty_vec,'quantity','FURUNO_ID','offset',0,'gain',0,'nodata',0,'undetect',0);
radar_struct.data2  = struct('data',empty_vec,'quantity','FURUNO_AZI','offset',0,'gain',0,'nodata',0,'undetect',0);
radar_struct.data3  = struct('data',empty_vec,'quantity','FURUNO_ELV','offset',0,'gain',0,'nodata',0,'undetect',0);
radar_struct.data4  = struct('data',empty_mat,'quantity','RATE','offset',-327.68,'gain',.01,'nodata',0,'undetect',0);
radar_struct.data5  = struct('data',empty_mat,'quantity','DBZH','offset',-327.68,'gain',.01,'nodata',0,'undetect',0);
radar_struct.data6  = struct('data',empty_mat,'quantity','VRADH','offset',-327.68,'gain',.01,'nodata',0,'undetect',0);
radar_struct.data7  = struct('data',empty_mat,'quantity','ZDR','offset',-327.68,'gain',.01,'nodata',0,'undetect',0);
radar_struct.data8  = struct('data',empty_mat,'quantity','KDP','offset',-327.68,'gain',.01,'nodata',0,'undetect',0);
radar_struct.data9  = struct('data',empty_mat,'quantity','PHIDP','offset',360/65535,'gain',-360/65535,'nodata',0,'undetect',0);
radar_struct.data10 = struct('data',empty_mat,'quantity','RHOHV','offset',-2/65534,'gain',2/65534,'nodata',0,'undetect',0);
radar_struct.data11 = struct('data',empty_mat,'quantity','WRADH','offset',-.01,'gain',-.01,'nodata',0,'undetect',0);
radar_struct.data12 = struct('data',empty_mat,'quantity','FURUNO_QC','offset',0,'gain',0,'nodata',0,'undetect',0);

%begin data read loop
for j=1:num_smpls
    %read ray dims
    info_id    = fread(fid, 1, 'ushort');
    ray_azi   = fread(fid, 1, 'ushort')/100; %deg
    ray_elv   = fread(fid, 1, 'short')/100;  %deg
    
    %Read ray data
    
    %number of bytes in ray
    ray_bytes = fread(fid, 1, 'ushort'); %NOT SAVED
    
    %Rain Rate (mm/h)
    ray_rain = fread(fid, num_gates, 'ushort');
%     ray_rain(ray_rain==0) = NaN;
%     ray_rain = (ray_rain-32768)./100;
    
    %Horz Refl (dBZ)
    ray_zhh = fread(fid, num_gates, 'ushort');
%     ray_zhh(ray_zhh==0) = NaN;
%     ray_zhh = (ray_zhh-32768)./100;
    
    %Doppler Velocity (m/s)
    ray_vel = fread(fid, num_gates, 'ushort');
%     ray_vel(ray_vel==0) = NaN;
%     ray_vel = (ray_vel-32768)./100;
    
    %Refl ratio (dB)
    ray_zdr = fread(fid, num_gates, 'ushort');
%     ray_zdr(ray_zdr==0) = NaN;
%     ray_zdr = (ray_zdr-32768)./100;
    
    %Propagation phase difference rate of change (deg/km) (kpd)
    ray_kdp = fread(fid, num_gates, 'ushort');
%     ray_kdp(ray_kdp==0) = NaN;
%     ray_kdp = (ray_kdp-32768)./100;
    
    %Differential Phase Shift (deg) (phidp)
    ray_phidp = fread(fid, num_gates, 'ushort');
%     ray_phidp(ray_phidp==0) = NaN;
%     ray_phidp = 360.*(ray_phidp-1)./65535;
    
    %Correlation coefficient (rhohv)
    ray_rhohv = fread(fid, num_gates, 'ushort');
%     ray_rhohv(ray_rhohv==0) = NaN;
%     ray_rhohv = 2.*(ray_rhohv-1)./65534;
    
    %Doppler Spectral Width (m/s)
    ray_specwidth = fread(fid, num_gates, 'ushort');
%     ray_specwidth(ray_specwidth==0) = NaN;
%     ray_specwidth = (ray_specwidth-1)./100;
    
    %QC
    ray_qc = fread(fid, num_gates, 'ushort');
    
    %allocate
    radar_struct.data1.data(j)   = info_id;
    radar_struct.data2.data(j)   = ray_azi;
    radar_struct.data3.data(j)   = ray_elv;
    radar_struct.data4.data(j,:) = ray_rain;
    radar_struct.data5.data(j,:) = ray_zhh;
    radar_struct.data6.data(j,:) = ray_vel;
    radar_struct.data7.data(j,:) = ray_zdr;
    radar_struct.data8.data(j,:) = ray_kdp;
    radar_struct.data9.data(j,:) = ray_phidp;
    radar_struct.data10.data(j,:) = ray_rhohv;
    radar_struct.data11.data(j,:) = ray_specwidth;
    radar_struct.data12.data(j,:) = ray_qc;
    
end
fclose(fid);

%export header
radar_struct.header = struct('file_vrsion',file_vrsion,...
    'lat_dec',lat_dec,'lon_dec',lon_dec,...
    'ant_alt',ant_alt,'ant_rot_spd',ant_rot_spd,...
    'prf1',prf1,'prf2',prf2,'puls_noise',puls_noise,'freq_noise',freq_noise,...
    'num_smpls',num_smpls,'num_gates',num_gates,'gate_res',gate_res,...
    'radar_horz_constant',radar_horz_constant,'radar_vert_constant',radar_vert_constant,...
    'azi_offset',azi_offset,'scan_type',scan_type,'scn_ppi_step',scn_ppi_step,'scn_ppi_total',scn_ppi_total,...
    'rec_utc_datetime',rec_utc_datetime,...
    'rec_item',rec_item,'tx_blind_rng',tx_blind_rng,'tx_pulse_spec',tx_pulse_spec);


