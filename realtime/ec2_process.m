function ec2_process

%WHAT: Runs when ec2 machine starts. Listens to sqs for new files.
%Transfers from s3 to local folder. converts to odimh5. passes to pyart
%script for image generation. moves images back to s3 web/img folder.

%add paths
addpath('../etc')
addpath('../lib')
addpath('json_read')

%read config file
config_input_path =  '../etc/ec2_process.config';
temp_config_mat   = '../etc/ec2_process.mat';
if exist(config_input_path,'file') == 2
    read_config(config_input_path,temp_config_mat);
    load(temp_config_mat);
else
    display('config file does not exist')
    return
end

%vars
tmp_path = [tempdir,'ec2_process_tmp'];
if exist(tmp_path) == 7
    rmdir(tmp_path);
end
mkdir(tmp_path);

while true
    %check sqs
    [message_out] = sqs_receive_personal(sqs_url);
    keyboard
    %transfer from s3 to local
    %convert to odimh5 (delete local binary)
    %genenerate images using py-art script (delete odimh5)
    %transfer images back to s3 web/img
    
end