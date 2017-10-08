function realtime_offline

%WHAT: copies the offline html index to ensure radar is offline

%NOTES: AWS commands configured for personal account

%add paths
addpath('../etc')
addpath('../lib')

%read config file
config_input_path =  '../etc/ec2_process.config';
temp_config_mat   = '../etc/ec2_process_config.mat';
if exist(config_input_path,'file') == 2
    read_config(config_input_path,temp_config_mat);
    load(temp_config_mat);
else
    display('config file does not exist')
    return
end

%set html to be offline
cmd          = ['aws s3 cp --profile personal --acl public-read ',pwd,'/html/index_offline.html ',s3_webindex_path];
if isunix
    [status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
else
    [status,out] = dos(cmd);
end