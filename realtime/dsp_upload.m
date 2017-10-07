function dsp_upload

%WHAT:
%Listens for new files in local WR2100 DSP continaing new data files.
%Filters by scan tilt. Once a new file has been detected of the correct
%tilt, upload to s3 and send sns to sqs queue

%add paths
addpath('../etc')
addpath('../lib')

%read config file
config_input_path =  '..//etc/dsp_upload.config';
temp_config_mat   = '../etc/dsp_upload_config.mat';
if exist(config_input_path,'file') == 2
    read_config(config_input_path,temp_config_mat);
    load(temp_config_mat);
else
    display('config file does not exist')
    return
end

%location input
if ask_location == 1
    r_azi_str = inputdlg('Azimuth(deg): ');   r_azi = str2num(r_azi_str{1});
    r_lat_str = inputdlg('Latitude(deg): ');  r_lat = str2num(r_lat_str{1});
    r_lon_str = inputdlg('Longitude(deg): '); r_lon = str2num(r_lon_str{1});
    r_alt_str = inputdlg('Elevation(m): ');   r_alt = str2num(r_alt_str{1});
end

%filter local path and add to upload list to ignore old files
disp('Inital scan of input folder')
upload_list = filter_local(local_data_path,{},dataset_index);

%start ec2
disp('Starting EC2 Machine')
cmd          = ['aws ec2 start-instances --instance-ids ',ec2_id];
[status,out] = dos(cmd);

%create kill file
cmd = 'copy NUL upload.stop';
[status,out] = dos(cmd);

while true
    
    %check for kill file
    if exist('upload.stop') ~=2
        break
    end

    %filter by tilts
    new_fn_list = filter_local(local_data_path,upload_list,dataset_index);
    
    %loop through list
    for i = 1:length(new_fn_list)
        local_fn  = new_fn_list{i};
        local_ffn = [local_data_path,local_fn];
        s3_ffn    = [s3_data_path,local_fn];
        fid = fopen(local_ffn);
        if fid == -1
            continue %file open for write, not ready
        end
        
        %upload to s3
        disp(['uploading ',local_ffn,' to s3'])
        cmd          = ['aws s3 cp ',local_ffn,' ',s3_ffn];
        [status,out] = dos(cmd);
        upload_list  = [upload_list;local_fn];
        
        %publish sns including s3 path, lat, lon, alt and azimuth
        disp(['sending sns for ',new_fn_list{i}])
        sns_msg      = [s3_ffn,',',num2str(r_azi),',',num2str(r_lat),',',...
            num2str(r_lon),',',num2str(r_alt)];
        cmd          = ['aws sns publish --topic-arn ',sns_arn,' --message "',sns_msg,'"'];
        [status,out] = dos(cmd);
    end
    
    %pause for 5 seconds
    disp('pausing for 5 seconds')
    pause(5)
end

%stop ec2 machine
disp('Stopping EC2 Machine')
cmd          = ['aws ec2 stop-instances --instance-ids ',ec2_id];
[status,out] = dos(cmd);

function new_fn_list = filter_local(local_data_path,upload_list,dataset_index)
%WHAT: for a local path, this function lists all files, filters out scn and
%rhi files, extracts dataset numbers, matches with dataset_index, then
%checks if file has already been uploaded.

%temp list
new_fn_list = {};

%list folders
listing = dir(local_data_path); listing(1:2) = [];
fn_list = {listing.name};

for i = 1:length(fn_list)
    binary_fn  = fn_list{i};
    %extract dataset number
    [~,tmp_name,scan_type]  = fileparts(binary_fn);
    tmp_parts  = textscan(tmp_name,'%s','Delimiter','_'); tmp_parts = tmp_parts{1};%split up
    if strcmp(scan_type,'.scn')  
        tmp_index = str2num(tmp_parts{4});    %scan number
    elseif strcmp(scan_type,'.rhi')  %RHI filenames start from dataset 0 in the filename, offset by 1
        tmp_index = str2num(tmp_parts{4});    %scan number
    else
        %file type unknown
        continue
    end
    
    %check dataset number
    if tmp_index~=dataset_index
        %dataset index doesn't match
        continue
    else
        %check if binary_ffn is in upload_list
        out = strcmp(binary_fn,upload_list);
        if any(out)
            continue
        else
            %add to new_ffn_list
            new_fn_list = [new_fn_list;binary_fn];
        end
    end
end

