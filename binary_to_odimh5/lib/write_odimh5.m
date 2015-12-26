function write_odimh5(data_struct,output_path)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: writes radar object in data_struct to odminh5 compliant file

%read config
temp_config_mat   = 'etc/current_config.mat';
load(temp_config_mat);

%create h5 ffn
scan_date = datestr(data_struct.header.file_datetime,'yyyymmdd_HHMMSS');
scan_type = data_struct.header.scan_type;
if strcmp(scan_type,'scn') %append ppi numbers to scn filename
    scan_type = [scan_type,'_',num2str(data_struct.header.scn_ppi_total,'%02.0f'),'_',num2str(data_struct.header.scn_ppi_step,'%02.0f')];
end
h5_ffn = [output_path,'/uq-xpol_',scan_type,'_',scan_date,'.h5'];

%remove h5 filename if it exists
if exist(h5_ffn,'file')==2
    delete(h5_ffn)
end

%write header
write_hdf_header(h5_ffn,data_struct.header);

%write datasets
write_hdf_v2(h5_ffn,data_struct);

 
function write_hdf_header(h5_fn,header_struct)

%set object type
scan_type = header_struct.scan_type;
if strcmp(scan_type,'scn')
    scan_object = 'PVOL'; %SCAN
elseif strcmp(scan_type,'rhi')
    scan_object = 'ELEV';
elseif strcmp(scan_type,'sppi')
    scan_object = 'PVOL'; %SCAN
end

%create new file
file_id = H5F.create(h5_fn, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');

%% root group
root_id = H5G.open(file_id, '/', 'H5P_DEFAULT');
H5Acreatestring(root_id, 'Conventions', 'ODIM_H5/V2_0');

%what root group
group_id = H5G.create(root_id, 'what', 0, 0, 0);
H5Acreatestring(group_id, 'date', datestr(header_struct.file_datetime,'yyyymmdd'));
H5Acreatestring(group_id, 'time', datestr(header_struct.file_datetime,'HHMMSS'));
H5Acreatestring(group_id, 'object', scan_object);
H5Acreatestring(group_id, 'source', 'RAD:AU99,PLC:WOK');
H5Acreatestring(group_id, 'version', 'H5rad 2.2');

%where root group
group_id = H5G.create(root_id, 'where', 0, 0, 0);
H5Acreatedouble(group_id, 'lat', header_struct.lat_dec);
H5Acreatedouble(group_id, 'lon', header_struct.lon_dec);
H5Acreatedouble(group_id, 'height', header_struct.ant_alt_up*10000+header_struct.ant_alt_low);

%how root group
group_id = H5G.create(root_id, 'how', 0, 0, 0);
H5Acreatedouble(group_id, 'beamwidth', 2.7); %deg: does not change for WR2100
H5Acreatedouble(group_id, 'wavelength', 3.165); %cm: does not change for WR2100
H5Acreatedouble(group_id, 'rpm', header_struct.ant_rot_spd); %azi speed in rpm
H5Acreatedouble(group_id, 'pulsewidthmode', header_struct.tx_pulse_spec); %CUSTOM field for WR2100 pulse spec
H5Acreatedouble(group_id, 'RXbandwidth', 60); %MHz: Does not change
H5Acreatedouble(group_id, 'lowprf', header_struct.prf1); %Hz
H5Acreatedouble(group_id, 'highprf', header_struct.prf2); %Hz
H5Acreatedouble(group_id, 'radconstH', header_struct.radar_horz_constant); %dB
H5Acreatedouble(group_id, 'radconstV', header_struct.radar_vert_constant); %dB
H5Acreatedouble(group_id, 'TXpower', 0.1); %kW: Does not change

%add FURUNO specific fields to how root group (non odimh5 V2.2)
H5Acreatedouble(group_id, 'FURUNO_file_vrsion',header_struct.file_vrsion); %Hz
H5Acreatedouble(group_id, 'FURUNO_ant_rot_spd',header_struct.ant_rot_spd); %Hz
H5Acreatedouble(group_id, 'FURUNO_prf1',header_struct.prf1); %Hz
H5Acreatedouble(group_id, 'FURUNO_prf2',header_struct.prf2); %Hz
H5Acreatedouble(group_id, 'FURUNO_puls_noise',header_struct.puls_noise); %dBm
H5Acreatedouble(group_id, 'FURUNO_freq_noise',header_struct.freq_noise); %dBm
H5Acreatedouble(group_id, 'FURUNO_azi_offset',header_struct.azi_offset); %degTn
H5Acreatedouble(group_id, 'FURUNO_gate_res',header_struct.gate_res); %m
H5Acreatedouble(group_id, 'FURUNO_num_smpls',header_struct.num_smpls); %qty
H5Acreatedouble(group_id, 'FURUNO_num_gates',header_struct.num_gates); %qty
H5Acreatedouble(group_id, 'FURUNO_rec_item',header_struct.rec_item); %qty
H5Acreatedouble(group_id, 'FURUNO_tx_blind_rng',header_struct.tx_blind_rng); %m
H5Acreatedouble(group_id, 'FURUNO_tx_pulse_spec',header_struct.tx_pulse_spec); %1-10

%close file
H5F.close(file_id);

function write_hdf_v2(h5_fn,data_struct)

%set scan type
scan_type = data_struct.header.scan_type;
if strcmp(scan_type,'scn')
    scan_product = 'PVOL'; %SCAN
    scan_param   = 'PPI';
elseif strcmp(scan_type,'rhi')
    scan_product = 'RHI';
    scan_param   = 'RHI';
elseif strcmp(scan_type,'sppi')
    scan_product = 'PVOL'; %SCAN
    scan_param   = 'PPI';
end

%set compression
chunk_size   = [45 80];
deflate_scal = 6;

%get group name
g_name = ['dataset1'];

%set h5 ids
file_id   = H5F.open(h5_fn,'H5F_ACC_RDWR','H5P_DEFAULT');
root_id  = H5G.open(file_id, '/', 'H5P_DEFAULT');
group_id = H5G.create(root_id, g_name, 0, 0, 0);

%% dataset group

%what group
g_id     = H5G.create(group_id, 'what', 0, 0, 0);

H5Acreatestring(g_id, 'product', scan_product);
H5Acreatestring(g_id, 'prodpar', scan_param);
H5Acreatestring(g_id, 'startdate', datestr(data_struct.header.file_datetime,'yyyymmdd'));
H5Acreatestring(g_id, 'starttime', datestr(data_struct.header.file_datetime,'HHMMSS'));
H5Acreatestring(g_id, 'enddate', datestr(data_struct.header.file_datetime,'yyyymmdd'));
H5Acreatestring(g_id, 'endtime', datestr(data_struct.header.file_datetime,'HHMMSS'));

%where dataset group
g_id     = H5G.create(group_id, 'where', 0, 0, 0);

if strcmp(scan_type,'scn') || strcmp(scan_type,'sppi') %scn and sppi where group
    
    elangle = data_struct.data.scan_elv(1);
    nbins   = length(data_struct.data.scan_rng);
    rstart  = data_struct.data.scan_rng(1)/1000;
    rscale  = data_struct.data.scan_rng(2)-data_struct.data.scan_rng(1);
    nrays   = length(data_struct.data.scan_elv);
   
    H5Acreatedouble(g_id, 'elangle', elangle);
    H5Acreatelong(g_id, 'nbins', int64(nbins));
    H5Acreatedouble(g_id, 'rstart', rstart);
    H5Acreatedouble(g_id, 'rscale', rscale);
    H5Acreatelong(g_id, 'nrays', int64(nrays));
    H5Acreatelong(g_id, 'a1gate', int64(0)); %just use 0 as 1st azimuth radiated in the scan
    if strcmp(scan_type,'sppi') %additional SPPI information
        
        startaz = data_struct.data.scan_azi(1);
        stopaz  = data_struct.data.scan_azi(end);
        
        H5Acreatedouble(g_id, 'startaz', startaz);
        H5Acreatedouble(g_id, 'stopaz', stopaz);
    end
else %RHI where group
    
    az_angle = data_struct.data.scan_azi(1);
    angles   = data_struct.data.scan_elv;
    range    =  data_struct.data.scan_rng(end)/1000;
    
    H5Acreatedouble(group_id, 'lat', data_struct.header.lat_dec);
    H5Acreatedouble(group_id, 'lon', data_struct.header.lon_dec);
    H5Acreatedouble(g_id, 'az_angle', az_angle);
    H5Acreatedoublearray(g_id, 'angles', angles,size(angles));
    H5Acreatedouble(g_id, 'range', range);
end

%how group
g_id      = H5G.create(group_id, 'how', 0, 0, 0);

%% data group

%sort index for scn scans for odhimh5 compliant
if strcmp(scan_type,'scn')
    [~,sort_ind] = sort(data_struct.data.scan_azi);
else
    sort_ind = 1:length(data_struct.data.scan_azi);
end

%RAIN
create_data(1,sort_ind,group_id,data_struct.data.scan_rain,'RATE',.01,-327.68);
%DBZH
create_data(2,sort_ind,group_id,data_struct.data.scan_zhh,'DBZH',.01,-327.68);
%VRAD
create_data(3,sort_ind,group_id,data_struct.data.scan_vel,'VRADH',.01,-327.68);
%ZRD
create_data(4,sort_ind,group_id,data_struct.data.scan_zdr,'ZDR',.01,-327.68);
%KDP
create_data(5,sort_ind,group_id,data_struct.data.scan_kdp,'KDP',.01,-327.68);
%PHIDP
create_data(6,sort_ind,group_id,data_struct.data.scan_phidp,'PHIDP',360/65535,-360/65535);
%RHOHV
create_data(7,sort_ind,group_id,data_struct.data.scan_rhohv,'RHOHV',2/65534,-2/65534);
%WRAD
create_data(8,sort_ind,group_id,data_struct.data.scan_specwidth,'WRADH',-.01,-.01);
%QC
create_data(9,sort_ind,group_id,data_struct.data.scan_qc,'WR2100_QC',0,0);

H5F.close(file_id);

        
function H5Acreatestring(root_id, a_name, a_val)
%converts a matlab string into a C sting and writes to a H5 file as an att

a_val(length(a_val)+1)=setstr(0);
type_id  = H5T.copy('H5T_C_S1');
H5T.set_size(type_id, length(a_val));

space_id = H5S.create('H5S_SCALAR');
attr_id  = H5A.create(root_id, a_name, type_id, space_id, 'H5P_DEFAULT', 'H5P_DEFAULT');
H5A.write(attr_id, type_id, a_val);


function H5Acreatedouble(root_id, a_name, a_val)
%write a double att to H5
space_id = H5S.create('H5S_SCALAR');
attr_id  = H5A.create(root_id, a_name, 'H5T_IEEE_F64LE', space_id, 'H5P_DEFAULT', 'H5P_DEFAULT');
H5A.write(attr_id, 'H5T_NATIVE_DOUBLE', a_val);

function H5Acreatedoublearray(root_id, a_name, a_val,h5_dim)
%write a double att to H5
space_id = H5S.create_simple(2,fliplr(h5_dim),fliplr(h5_dim));
attr_id  = H5A.create(root_id, a_name, 'H5T_IEEE_F64LE', space_id, 'H5P_DEFAULT', 'H5P_DEFAULT');
H5A.write(attr_id, 'H5T_NATIVE_DOUBLE', a_val);


function H5Acreatelong(root_id, a_name, a_val)
%writes a long att to H5
space_id = H5S.create('H5S_SCALAR');
attr_id  = H5A.create(root_id, a_name, 'H5T_STD_I64LE', space_id, 'H5P_DEFAULT', 'H5P_DEFAULT');
H5A.write(attr_id, 'H5T_NATIVE_LONG', a_val);
      

function create_data(index,sort_ind,group_id,data,quantity,gain,offset)

%sort data (polar compliant)
data = data(sort_ind,:);

%rotate CHECK THIS!!!
data = flipud(rot90(data));

%set compression
chunk_size   = [45 80];
deflate_scal = 6;

%shink compression chunk size if needed (using C dims)
if size(data,2)<chunk_size(1)
    chunk_size(1) = size(data,2);
end
if size(data,1)<chunk_size(2)
    chunk_size(2) = size(data,1);
end

%create data entry variables
data_no = ['data',num2str(index)];
data_id = H5G.create(group_id, data_no, 0, 0, 0);

data_set = uint16(data);

%data what group
g_id = H5G.create(data_id, 'what', 0, 0, 0);
H5Acreatestring(g_id, 'quantity',quantity);
H5Acreatedouble(g_id, 'gain', gain); %float
H5Acreatedouble(g_id, 'offset', offset); %float
H5Acreatedouble(g_id, 'nodata', 0.0);
H5Acreatedouble(g_id, 'undetect', 0.1);

%data how group
g_id = H5G.create(data_id, 'how', 0, 0, 0);

%setup data variable
h5_size      = fliplr(size(data));
dataspace_id = H5S.create_simple(2, h5_size, h5_size);
plist        = H5P.create('H5P_DATASET_CREATE');
H5P.set_chunk(plist, chunk_size);
H5P.set_deflate(plist, deflate_scal);

%create data variable
dataset_id = H5D.create(data_id, 'data','H5T_STD_U16LE',dataspace_id, 'H5P_DEFAULT', plist, 'H5P_DEFAULT');

%write data variable
H5D.write(dataset_id, 'H5T_STD_U16LE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data_set);

%write data root group
H5Acreatestring(dataset_id, 'CLASS', 'IMAGE');
H5Acreatestring(dataset_id, 'IMAGE_VERSION', '1.2');

    
