function ec2_process

%WHAT: Runs when ec2 machine starts. Listens to sqs for new files.
%Transfers from s3 to local folder. converts to odimh5. passes to pyart
%script for image generation. moves images back to s3 web/img folder.

%NOTES: AWS commands configured for personal account

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

%temp download path
tmp_path = [tempdir,'ec2_process_tmp/'];
if exist(tmp_path) == 7
    rmdir(tmp_path);
end
mkdir(tmp_path);

%create kill file
[status,out] = unix('touch process.stop');

while true
    
    %check for kill file
    if exist('process.stop') ~=2
        break
    end
    
    %check sqs
    [message_out] = sqs_receive_personal(sqs_url);
    for i = 1:length(message_out)
        %extract message parts
        C = textscan(message_out{i},'%s %f %f %f %f','delimiter',',');
        s3_ffn = C{1}{1};
        r_azi  = C{2};
        r_lat  = C{3};
        r_lon  = C{4};
        r_alt  = C{5};
        
        %transfer from s3 to local
        disp(['download ',s3_ffn,' from s3'])
        [~,fn,ext]   = fileparts(s3_ffn);
        local_ffn    = [tmp_path,fn,ext];
        cmd          = ['aws s3 cp --profile personal ',s3_ffn,' ',local_ffn];
        [status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
        
        keyboard
        %convert to odimh5 (delete local binary)
        
        %genenerate images using py-art script (delete odimh5)
        
        %transfer images back to s3 web/img
    end
        
    
end