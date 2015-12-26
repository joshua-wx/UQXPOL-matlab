function data_struct=read_wr2100binary_v2(binary_ffn)
%for pre 9/11/2015 dualpol files

% Open file
fid = fopen(binary_ffn);

%read config
temp_config_mat   = 'etc/current_config.mat';
load(temp_config_mat);

%Read Header (apply scaling)
header_size = fread(fid, 1, 'ushort');
file_vrsion = fread(fid, 1, 'ushort');

file_year   = fread(fid, 1, 'ushort');
file_month  = fread(fid, 1, 'ushort');
file_day    = fread(fid, 1, 'ushort');
file_hour   = fread(fid, 1, 'ushort');
file_min    = fread(fid, 1, 'ushort');
file_sec    = fread(fid, 1, 'ushort');
file_datetime = datenum([file_year,file_month,file_day,file_hour,file_min,file_sec]);

lat_deg     = fread(fid, 1, 'short');
lat_min     = fread(fid, 1, 'ushort');
lat_sec     = fread(fid, 1, 'ushort')/1000;
lat_dec     = dms2degrees([lat_deg,lat_min,lat_sec]);

lon_deg     = fread(fid, 1, 'short');
lon_min     = fread(fid, 1, 'ushort');
lon_sec     = fread(fid, 1, 'ushort')/1000;
lon_dec     = dms2degrees([lon_deg,lon_min,lon_sec]);

ant_alt_up  = fread(fid, 1, 'ushort');       %cm
ant_alt_low = fread(fid, 1, 'ushort');       %cm
ant_rot_spd = fread(fid, 1, 'ushort')/10;    %rpm
prf1        = fread(fid, 1, 'ushort')/10;    %Hz
prf2        = fread(fid, 1, 'ushort')/10;    %Hz
puls_noise  = fread(fid, 1, 'short')/100;    %dBm
freq_noise  = fread(fid, 1, 'short')/100;    %dBm
num_smpls   = fread(fid, 1, 'ushort');       %qty
num_gates   = fread(fid, 1, 'ushort');       %qty
gate_res    = fread(fid, 1, 'ushort')/100;   %m

%create rng_vec from parameters
scan_rng   = gate_res:gate_res:num_gates*gate_res;

const_horz_mantissa = fread(fid, 1, 'long');
const_horz_characteristic = fread(fid, 1, 'short');
radar_horz_constant       = const_horz_mantissa * 10^const_horz_characteristic;
const_vert_mantissa = fread(fid, 1, 'long');
const_vert_characteristic = fread(fid, 1, 'short');
radar_vert_constant       = const_vert_mantissa * 10^const_vert_characteristic;

%calc utc time
rec_utc_datetime = addtodate(file_datetime,v2_utc_offset,'hour');

%unknown pulse spec in v2 files
tx_pulse_spec = 0;
tx_blind_rng  = 0;
rec_item      = 0;

azi_offset = fread(fid, 1, 'ushort')/100; %degTn

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
scan_id         = empty_vec;
scan_azi        = empty_vec;
scan_bytes      = empty_vec;
scan_elv        = empty_vec;
scan_rain       = empty_mat;
scan_zhh        = empty_mat;
scan_vel        = empty_mat;
scan_zdr        = empty_mat;
scan_kdp        = empty_mat;
scan_phidp      = empty_mat;
scan_rhohv      = empty_mat;
scan_specwidth  = empty_mat;
scan_qc         = empty_mat;

%begin data read loop
for j=1:num_smpls
    %read ray dims
    info_id    = fread(fid, 1, 'ushort');
    ray_azi   = fread(fid, 1, 'ushort')/100; %deg
    ray_elv   = fread(fid, 1, 'short')/100;  %deg
    
    %Read ray data
    
    %number of bytes in ray
    ray_bytes = fread(fid, 1, 'ushort');
    
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
    
    %allocate
    scan_id(j)          = info_id;
    scan_azi(j)         = ray_azi;
    scan_elv(j)         = ray_elv;
    scan_bytes(j)       = ray_bytes;
    scan_rain(j,:)      = ray_rain;
    scan_zhh(j,:)       = ray_zhh;
    scan_vel(j,:)       = ray_vel;
    scan_zdr(j,:)       = ray_zdr;
    scan_kdp(j,:)       = ray_kdp;
    scan_phidp(j,:)     = ray_phidp;
    scan_rhohv(j,:)     = ray_rhohv;
    scan_specwidth(j,:) = ray_specwidth;
    
end
fclose(fid);

%export header
header_suffix = 'header';
data_struct.(header_suffix) = struct('header_size',header_size,'file_vrsion',file_vrsion,...
    'file_datetime',file_datetime,'lat_dec',lat_dec,'lon_dec',lon_dec,...
    'ant_alt_up',ant_alt_up,'ant_alt_low',ant_alt_low,'ant_rot_spd',ant_rot_spd,...
    'prf1',prf1,'prf2',prf2,'puls_noise',puls_noise,'freq_noise',freq_noise,...
    'num_smpls',num_smpls,'num_gates',num_gates,'gate_res',gate_res,...
    'radar_horz_constant',radar_horz_constant,'radar_vert_constant',radar_vert_constant,...
    'azi_offset',azi_offset,'scan_type',scan_type,'scn_ppi_step',scn_ppi_step,'scn_ppi_total',scn_ppi_total,...
    'rec_utc_datetime',rec_utc_datetime,'rec_item',rec_item,...
    'tx_blind_rng',tx_blind_rng,'tx_pulse_spec',tx_pulse_spec);
%export data
data_suffix = 'data';
data_struct.(data_suffix) = struct('scan_id',scan_id,'scan_azi',scan_azi,'scan_elv',scan_elv,'scan_rng',scan_rng,...
    'scan_bytes',scan_bytes,'scan_rain',scan_rain,'scan_zhh',scan_zhh,'scan_vel',scan_vel,'scan_zdr',scan_zdr,...
    'scan_kdp',scan_kdp,'scan_phidp',scan_phidp,'scan_rhohv',scan_rhohv,'scan_specwidth',scan_specwidth,'scan_qc',scan_qc);