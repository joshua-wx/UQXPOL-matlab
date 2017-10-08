function restart_ec2_process

%WHAT:
%Listens for new files in local WR2100 DSP continaing new data files.
%Filters by scan tilt. Once a new file has been detected of the correct
%tilt, upload to s3 and send sns to sqs queue

%add paths
addpath('../etc')
addpath('../lib')

%read config file
config_input_path =  '../etc/dsp_upload.config';
temp_config_mat   = '../etc/dsp_upload_config.mat';
if exist(config_input_path,'file') == 2
    read_config(config_input_path,temp_config_mat);
    load(temp_config_mat);
else
    display('config file does not exist')
    return
end

%stop ec2 machine
disp('Stopping EC2 Machine')
cmd          = ['aws ec2 stop-instances --profile personal --instance-ids ',ec2_id];
if isunix
    [status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
else
    [status,out] = dos(cmd);
end

pause(10)

%start ec2
disp('Starting EC2 Machine')
cmd          = ['aws ec2 start-instances --profile personal --instance-ids ',ec2_id];
if isunix
    [status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
else
    [status,out] = dos(cmd);
end