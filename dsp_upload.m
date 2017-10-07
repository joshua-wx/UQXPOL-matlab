function dsp_upload

%WHAT:
%Listens for new files in local WR2100 DSP continaing new data files.
%Filters by scan tilt. Once a new file has been detected of the correct
%tilt, upload to s3 and send sns to sqs queue

%add paths
addpath('etc')
addpath('lib')

%filter local path and add to upload list to ignore old files
upload_list = filter_local(local_data_path,{},volume_tilt_index);

%start ec2
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
 
    %pause for 10 seconds
    pause(10)

    %filter by tilts
    new_fn_list = filter_local(local_data_path,upload_list,volume_tilt_index);
    
    %loop through list
    for i = 1:length(new_fn_list)
        local_ffn = [local_data_path,new_fn_list{i}];
        s3_ffn    = [s3_data_path,new_fn_list{i}];
        fid = fopen(target_ffn);
        if fid = -1
            continue %file open for write, not ready
        end
        %upload to s3
        cmd          = ['aws s3 cp ',local_ffn,' ',s3_ffn];
        [status,out] = dos(cmd);
        upload_list  = [upload_list;local_ffn];
        %add to sqs
        
    end
    %publish sns
    cmd          = ['aws sns publish --topic-arn ',sns_arn,' --message "',s3_ffn,'"'];
    [status,out] = dos(cmd);
    
end

%stop ec2 machine
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
    if strcmp(scan_type,'scn')  
        tmp_index = str2num(tmp_parts{4});    %scan number
    elseif strcmp(scan_type,'rhi')  %RHI filenames start from dataset 0 in the filename, offset by 1
        tmp_index = str2num(tmp_parts{4});    %scan number
    else
        disp('file type unknown')
        continue
    end
    
    %check dataset number
    if dataset_no~=dataset_index
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
end

