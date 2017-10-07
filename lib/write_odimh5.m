function [abort,h5_ffn] = write_odimh5(radar_struct,output_path,collate_volumes,radar_id,config_coords)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: writes radar object in radar_struct to odminh5 compliant file
abort             = 0;

%create h5 ffn
if collate_volumes == 1 %collate into volumes using shared fn_datetime
    postfix      = datestr(radar_struct.header.fn_datetime,'yyyymmdd_HHMMSS');
else %keep as seperate scans using unique rec_utc_datetime
    postfix      = [datestr(radar_struct.header.rec_utc_datetime,'yyyymmdd_HHMMSS'),'_',num2str(radar_struct.header.dataset_no,'%02.0f')];
end
scan_type    = radar_struct.header.scan_type;
h5_ffn       = [output_path,'/',num2str(radar_id,'%02.0f'),'_',postfix,'.h5'];
g_name       = ['dataset',num2str(radar_struct.header.dataset_no)];

%remove h5 filename if it exists
if exist(h5_ffn,'file')==2
    %check if datasetno exists
    h5_info     = h5info(h5_ffn);
    h5_datasets = {h5_info.Groups.Name};
    %if dataset exists, ask user what to do (required GUI)
    if any(strcmp(h5_datasets,['/',g_name]))
        out = questdlg([g_name,' already exists in ',h5_ffn],'Dataset Exists in h5 File','Abort','Delete File','Abort');
        if strcmp(out,'Abort')
            abort = 1;
            return
        else
            %delete file
            delete(h5_ffn);
            %create new file
            write_hdf_header(h5_ffn,radar_struct.header,radar_id,config_coords);
        end
    end
else
    %create new file, does not exist
    write_hdf_header(h5_ffn,radar_struct.header,radar_id,config_coords);
end

%write dataset
write_hdf_dataset(h5_ffn,radar_struct,g_name,config_coords);

 
function write_hdf_header(h5_fn,header_struct,radar_id,config_coords)

%set object type
scan_type = header_struct.scan_type;
if strcmp(scan_type,'scn')
    scan_object = 'SCAN'; %PPI, was "PVOL"
elseif strcmp(scan_type,'rhi')
    scan_object = 'ELEV'; %RHI
elseif strcmp(scan_type,'sppi')
    scan_object = 'AZIM'; %SPPI
end

%create new file
file_id = H5F.create(h5_fn, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');

%% root group
root_id = H5G.open(file_id, '/', 'H5P_DEFAULT');
H5Acreatestring(root_id, 'Conventions', 'ODIM_H5/V2_0');

%what root group
group_id = H5G.create(root_id, 'what', 0, 0, 0);
H5Acreatestring(group_id, 'date', datestr(header_struct.rec_utc_datetime,'yyyymmdd'));
H5Acreatestring(group_id, 'time', datestr(header_struct.rec_utc_datetime,'HHMMSS'));
H5Acreatestring(group_id, 'object', scan_object);
H5Acreatestring(group_id, 'source', ['RAD:AU',num2str(radar_id,'%02.0f'),',PLC:WOK']); %this makes it work with BOM odimh5 readers
H5Acreatestring(group_id, 'version', 'H5rad 2.2');
H5Acreatestring(group_id, 'FURUNO_radar_model','WR2100');

%where root group
group_id = H5G.create(root_id, 'where', 0, 0, 0);
if config_coords.radar_lat == -999
    H5Acreatedouble(group_id, 'lat', header_struct.lat_dec); %use data header
else
    H5Acreatedouble(group_id, 'lat', config_coords.radar_lat); %use config
end
if config_coords.radar_lon == -999
    H5Acreatedouble(group_id, 'lon', header_struct.lon_dec); %use data header
else
    H5Acreatedouble(group_id, 'lon', config_coords.radar_lon); %use config
end
if config_coords.radar_h == -999
    H5Acreatedouble(group_id, 'height', header_struct.ant_alt); %use data header
else
    H5Acreatedouble(group_id, 'height', config_coords.radar_h); %use config
end

%how root group
group_id = H5G.create(root_id, 'how', 0, 0, 0);
H5Acreatestring(group_id, 'copyright', 'University of Queensland, Climate Research Group https://www.gpem.uq.edu.au/crg');
H5Acreatedouble(group_id, 'beamwidth', 2.7); %deg: does not change for WR2100
H5Acreatedouble(group_id, 'wavelength', 3.165); %cm: does not change for WR2100
H5Acreatedouble(group_id, 'rpm', header_struct.ant_rot_spd); %azi speed in rpm
H5Acreatedouble(group_id, 'RXbandwidth', 60); %MHz: Does not change
H5Acreatedouble(group_id, 'lowprf', header_struct.prf1); %Hz
H5Acreatedouble(group_id, 'highprf', header_struct.prf2); %Hz
H5Acreatedouble(group_id, 'radconstH', header_struct.radar_horz_constant); %dB
H5Acreatedouble(group_id, 'radconstV', header_struct.radar_vert_constant); %dB
H5Acreatedouble(group_id, 'peakpwr', 0.1); %kW: Does not change

%add FURUNO specific fields to how root group (non odimh5 V2.2)
H5Acreatedouble(group_id, 'FURUNO_file_vrsion',header_struct.file_vrsion); %Hz
H5Acreatedouble(group_id, 'FURUNO_puls_noise',header_struct.puls_noise); %dBm
H5Acreatedouble(group_id, 'FURUNO_freq_noise',header_struct.freq_noise); %dBm
H5Acreatedouble(group_id, 'FURUNO_num_smpls',header_struct.num_smpls); %qty
H5Acreatedouble(group_id, 'FURUNO_num_gates',header_struct.num_gates); %qty
H5Acreatedouble(group_id, 'FURUNO_gate_res',header_struct.gate_res); %m
H5Acreatedouble(group_id, 'FURUNO_azi_offset',header_struct.azi_offset); %degTn
H5Acreatestring(group_id, 'FURUNO_scan_type',header_struct.scan_type);
H5Acreatedouble(group_id, 'FURUNO_product_no',header_struct.product_no);
H5Acreatedouble(group_id, 'FURUNO_rec_item',header_struct.rec_item); %qty
H5Acreatedouble(group_id, 'FURUNO_tx_blind_rng',header_struct.tx_blind_rng); %m
H5Acreatedouble(group_id, 'FURUNO_tx_pulse_spec',header_struct.tx_pulse_spec); %1-10
%These are not essential
% H5Acreatedoublearray(group_id, 'FURUNO_data_id', header_struct.data_id,size(header_struct.data_id));
% H5Acreatedoublearray(group_id, 'FURUNO_data_azi', header_struct.data_azi,size(header_struct.data_azi));
% H5Acreatedoublearray(group_id, 'FURUNO_data_elv', header_struct.data_elv,size(header_struct.data_elv));

%close file
H5F.close(file_id);

function write_hdf_dataset(h5_fn,radar_struct,g_name,config_coords)

%wrap azimuth data using radar_heading
if config_coords.radar_heading ~= -999
    data_azi = radar_struct.header.data_azi; %init
    data_azi = data_azi + config_coords.radar_heading;     %add heading
    data_azi = wrapTo360(data_azi);          %wrap
    radar_struct.header.data_azi = data_azi; %save
end

%set scan type
scan_type = radar_struct.header.scan_type;
if strcmp(scan_type,'scn')
    scan_product = 'SCAN';
    scan_param   = 'PPI';
elseif strcmp(scan_type,'rhi')
    scan_product = 'RHI';
    scan_param   = 'RHI';
elseif strcmp(scan_type,'sppi')
    scan_product = 'AZIM';
    scan_param   = 'PPI';
end

%set compression
chunk_size   = [45 80];
deflate_scal = 6;

%set h5 ids
file_id   = H5F.open(h5_fn,'H5F_ACC_RDWR','H5P_DEFAULT');
root_id  = H5G.open(file_id, '/', 'H5P_DEFAULT');
group_id = H5G.create(root_id, g_name, 0, 0, 0);

%% dataset group

%what group
g_id     = H5G.create(group_id, 'what', 0, 0, 0);

H5Acreatestring(g_id, 'product', scan_product);
H5Acreatestring(g_id, 'prodpar', scan_param);
H5Acreatestring(g_id, 'startdate', datestr(radar_struct.header.rec_utc_datetime,'yyyymmdd'));
H5Acreatestring(g_id, 'starttime', datestr(radar_struct.header.rec_utc_datetime,'HHMMSS'));
H5Acreatestring(g_id, 'enddate', datestr(radar_struct.header.rec_utc_datetime,'yyyymmdd'));
H5Acreatestring(g_id, 'endtime', datestr(radar_struct.header.rec_utc_datetime,'HHMMSS'));

%where dataset group
g_id     = H5G.create(group_id, 'where', 0, 0, 0);

nbins   = radar_struct.header.num_gates;
rscale  = radar_struct.header.gate_res;

if strcmp(scan_type,'scn') || strcmp(scan_type,'sppi') %scn and sppi where group
    
    elangle = radar_struct.header.data_elv(1); %elv
    rstart  = 0;
    nrays   = radar_struct.header.num_smpls;
   
    H5Acreatedouble(g_id, 'elangle', elangle);
    H5Acreatelong(g_id, 'nbins', int64(nbins));
    H5Acreatedouble(g_id, 'rstart', rstart);
    H5Acreatedouble(g_id, 'rscale', rscale);
    H5Acreatelong(g_id, 'nrays', int64(nrays));
    H5Acreatelong(g_id, 'a1gate', int64(0)); %just use 0 as 1st azimuth radiated in the scan
    if strcmp(scan_type,'sppi') %additional SPPI information
        
        startaz = radar_struct.header.data_azi(1);
        stopaz  = radar_struct.header.data_azi(end);
        
        H5Acreatedouble(g_id, 'startaz', startaz);
        H5Acreatedouble(g_id, 'stopaz', stopaz);
    end
else %RHI where group
    
    az_angle = radar_struct.header.data_azi(1); %azi
    angles   = radar_struct.header.data_elv; %elv
    range    = (nbins-1)*rscale/1000;
    
    H5Acreatedouble(group_id, 'lat', radar_struct.header.lat_dec);
    H5Acreatedouble(group_id, 'lon', radar_struct.header.lon_dec);
    H5Acreatedouble(g_id, 'az_angle', az_angle);
    H5Acreatedoublearray(g_id, 'angles', angles,size(angles));
    H5Acreatedouble(g_id, 'range', range);
end

%how group
g_id      = H5G.create(group_id, 'how', 0, 0, 0);
H5Acreatedouble(g_id, 'NI', 32);
H5Acreatedouble(g_id, 'scan_index', radar_struct.header.dataset_no);

%% data group

%sort azi index for scn scans for odhimh5 compliant
if strcmp(scan_type,'scn')
    [~,sort_ind] = sort(radar_struct.header.data_azi); %azi
else
    sort_ind = 1:length(radar_struct.header.data_azi); %azi
end

%write data
for i=1:length(fields(radar_struct))-1 %loop through all data sets (1 less for header)
    data_index_name = ['data',num2str(i)];
    dataset         = radar_struct.(data_index_name);
    create_data(i,sort_ind,group_id,dataset);
end

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
      

function create_data(index,sort_ind,group_id,dataset)

%sort data (polar compliant)
data = dataset.data(sort_ind,:);

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
H5Acreatestring(g_id, 'quantity',dataset.quantity);
H5Acreatedouble(g_id, 'gain', dataset.gain); %float
H5Acreatedouble(g_id, 'offset', dataset.offset); %float
H5Acreatedouble(g_id, 'nodata', dataset.nodata);
H5Acreatedouble(g_id, 'undetect', dataset.undetect);

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

    
