function ec2_process

%WHAT: Runs when ec2 machine starts. Listens to sqs for new files.
%Transfers from s3 to local folder. converts to odimh5. passes to pyart
%script for image generation. moves images back to s3 web/img folder.

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

%temp download path
tmp_path = [tempdir,'ec2_process_tmp/'];
if exist(tmp_path) == 7
    rmdir(tmp_path,'s');
end
mkdir(tmp_path);

%create kill file
[status,out] = unix('touch process.stop');

%set html to be online
cmd          = ['aws s3 cp --profile personal --acl public-read ',pwd,'/html/index_online.html ',s3_webindex_path];
[status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);

while true
    
    %check for kill file
    if exist('process.stop') ~=2
        break
    end
    
    %check sqs
    [message_out] = sqs_receive_personal(sqs_url);
    for i = 1:length(message_out)
		try
		    %extract message parts
		    C = textscan(message_out{i},'%s %f %f %f %f','delimiter',',');
		    s3_ffn = C{1}{1};
		    r_azi  = C{2};
		    r_lat  = C{3};
		    r_lon  = C{4};
		    r_alt  = C{5};
		    
		    %transfer from s3 to local
		    disp(['copying ',s3_ffn,' from s3'])
		    [~,fn,ext]   = fileparts(s3_ffn);
		    local_ffn    = [tmp_path,fn,ext];
		    cmd          = ['aws s3 cp --profile personal ',s3_ffn,' ',local_ffn];
		    [status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
		    
		    %skip remainder if file does not exist
		    if exist(local_ffn,'file') ~= 2
		        continue
		    end
		    
		    %convert to odimh5 (delete local binary)
		    disp('converting to odimh5')
		    radar_struct   = read_wr2100binary(local_ffn);
		    config_coords  = struct('radar_lat',r_lat,'radar_lon',r_lon,'radar_h',r_alt,'radar_heading',r_azi);
		    [abort,h5_ffn] = write_odimh5(radar_struct,tmp_path,0,99,config_coords,1);
		    if abort == 1
		        display('***processing aborted***')
		        return
		    end
		    
		    %skip remainder if file does not exist
		    if exist(h5_ffn,'file') ~= 2
		        continue
		    end
		    
		    %genenerate images using py-art script (delete odimh5)
		    disp('generating pyart images')
		    cmd = [python_path,' pyart_plot.py ',h5_ffn,' ',tmp_path];
		    [status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
		    
		    %transfer images back to s3 web/img
		    disp(['copying web images to s3'])
		    transfer_img_s3([tmp_path,'DBZH.png'],s3_webimg_path);
		    transfer_img_s3([tmp_path,'VRADH.png'],s3_webimg_path);
		    %transfer_img_s3([tmp_path,'WRADH.png'],s3_webimg_path);
		    transfer_img_s3([tmp_path,'KDP.png'],s3_webimg_path);
		    transfer_img_s3([tmp_path,'ZDR.png'],s3_webimg_path);
		    %transfer_img_s3([tmp_path,'RHOHV.png'],s3_webimg_path);
		    
		    %delete local files
		    delete(local_ffn)
		    delete(h5_ffn)
		catch err
			display(err)
			continue
		end
    end
    
    %pause for 5 seconds
    disp('pausing for 5 seconds')
    pause(5)
end

%set html to be offline
cmd          = ['aws s3 cp --profile personal --acl public-read ',pwd,'/html/index_offline.html ',s3_webindex_path];
[status,out] = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);


function transfer_img_s3(local_img_ffn,s3_webimg_path)
%upload image ffn to s3 using mv and public read
cmd             = ['aws s3 mv --profile personal --acl public-read ',local_img_ffn,' ',s3_webimg_path];
[status,out]    = unix(['export LD_LIBRARY_PATH=/usr/lib; ',cmd]);
