function radar_struct=read_odimh5(input_path)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: Reads a single odimh5 v2.2 file (created by this program) into data_struct

%% Error checking

%check if input is a h5 file (not a folder etc)
if exist(input_path,'file')~=2
    display('input_path is not a single file, aborting')
    return
end
%check if h5 files
[~, ~, ext] = fileparts(input_path);
if ~strcmp(ext,'.h5')
    display('input_path not a h5 file')
    return
end
%attempt to read header attribute
try
    attval = h5readatt(input_path,'/what','FURUNO_radar_model');
catch
    display('failed to read /what/FURUNO_radar_model in odimh5 file')
    return
end
%check attribute value
if ~strcmp(deblank(attval),'WR2100')
    display('not a furuno_wr2100 odimh5 file produced by this library')
    return
end

%% read header

%read from odimh5
file_vrsion         = h5readatt(input_path,'/how','FURUNO_file_vrsion');

lat_dec             = h5readatt(input_path,'/where','lat');
lon_dec             = h5readatt(input_path,'/where','lon');    
ant_alt             = h5readatt(input_path,'/where','height');

rec_utc_date        = deblank(h5readatt(input_path,'/what','date'));
rec_utc_time        = deblank(h5readatt(input_path,'/what','time'));
rec_utc_datetime    = datenum([rec_utc_date,'_',rec_utc_time],'yyyymmdd_HHMMSS');

ant_rot_spd         = h5readatt(input_path,'/how','rpm');
prf1                = h5readatt(input_path,'/how','lowprf');
prf2                = h5readatt(input_path,'/how','highprf');
puls_noise          = h5readatt(input_path,'/how','FURUNO_puls_noise');
freq_noise          = h5readatt(input_path,'/how','FURUNO_freq_noise');
num_smpls           = h5readatt(input_path,'/how','FURUNO_num_smpls');
num_gates           = h5readatt(input_path,'/how','FURUNO_num_gates');
gate_res            = h5readatt(input_path,'/how','FURUNO_gate_res');
radar_horz_constant = h5readatt(input_path,'/how','radconstH');
radar_vert_constant = h5readatt(input_path,'/how','radconstV');
azi_offset          = h5readatt(input_path,'/how','FURUNO_azi_offset');
scan_type           = deblank(h5readatt(input_path,'/how','FURUNO_scan_type'));
scn_ppi_step        = h5readatt(input_path,'/how','FURUNO_scn_ppi_step');
scn_ppi_total       = h5readatt(input_path,'/how','FURUNO_scn_ppi_total');
rec_item            = h5readatt(input_path,'/how','FURUNO_rec_item');
tx_blind_rng        = h5readatt(input_path,'/how','FURUNO_tx_blind_rng');
tx_pulse_spec       = h5readatt(input_path,'/how','FURUNO_tx_pulse_spec');

%write to struct
radar_struct.header = struct('file_vrsion',file_vrsion,...
    'lat_dec',lat_dec,'lon_dec',lon_dec,...
    'ant_alt',ant_alt,'ant_rot_spd',ant_rot_spd,...
    'prf1',prf1,'prf2',prf2,'puls_noise',puls_noise,'freq_noise',freq_noise,...
    'num_smpls',num_smpls,'num_gates',num_gates,'gate_res',gate_res,...
    'radar_horz_constant',radar_horz_constant,'radar_vert_constant',radar_vert_constant,...
    'azi_offset',azi_offset,'scan_type',scan_type,'scn_ppi_step',scn_ppi_step,'scn_ppi_total',scn_ppi_total,...
    'rec_utc_datetime',rec_utc_datetime,...
    'rec_item',rec_item,'tx_blind_rng',tx_blind_rng,'tx_pulse_spec',tx_pulse_spec);

%% read data

data_info = h5info(input_path,'/dataset1/');
num_data = length(data_info.Groups)-3; %remove index for what/where/how groups

for i=1:num_data %loop through all data sets
    %read data
    data_name                   = ['data',num2str(i)];
    data                        = h5read(input_path,['/dataset1/',data_name,'/data']);
    quantity                    = deblank(h5readatt(input_path,['/dataset1/',data_name,'/what'],'quantity'));
    offset                      = h5readatt(input_path,['/dataset1/',data_name,'/what'],'offset');
    gain                        = h5readatt(input_path,['/dataset1/',data_name,'/what'],'gain');
    nodata                      = h5readatt(input_path,['/dataset1/',data_name,'/what'],'nodata');
    undetect                    = h5readatt(input_path,['/dataset1/',data_name,'/what'],'undetect');
    %add to struct
    radar_struct.(data_name)    = struct('data',data,'quantity',quantity,'offset',offset,'gain',gain,'nodata',nodata,'undetect',undetect);
end

keyboard
