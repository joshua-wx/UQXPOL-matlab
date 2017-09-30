function wr2100binary_to_odimh5(config_input_path)
%Joshua Soderholm, Feb 2016
%Climate Research Group, University of Queensland

%WHAT: master script for processing wr2100 binary files to odimh5

%testing config file
if nargin==0
    config_input_path =  'etc/wr2100binary_to_odimh5.config';
end

%addpaths
addpath('etc')
addpath('lib')

%read config file
temp_config_mat   = 'etc/current_config.mat';
if exist(config_input_path,'file') == 2
    read_config(config_input_path,temp_config_mat);
    load(temp_config_mat);
else
    display('config file does not exist')
    return
end

%read fileList mat
fileList_archive = {};
if exist(fileList_path,'file') == 2
    while true
        usr_ans = input('load fileList_archive? [1/0]');
        if usr_ans == 1
            %load fileList archive
            load(fileList_path)
            break
        elseif usr_ans == 0
            %delete old fileList archive
            delete(fileList_path)
            break
        else
            %reloop
            display('please use options [1/0]')
        end
    end
end
    
%create stop file for realtime processing (delete this stop file to halt
%loop)
if exist(kill_path,'file') == 2
    delete(kill_path)
end
if realtime_processing == 1
    [~,~] = system(['touch ',kill_path]);
end

%processing loop
while true
    %create file list from folder/file
    fileList = getAllFiles(input_path);
    
    %remove files already processed from fileList
    lia = ismember(fileList,fileList_archive);
    fileList = fileList(~lia); %only keep files not in fileList_archive
    
    %check for files
    if isempty(fileList)
        display('warning, no new files in input_path')
        pause(1)
    end
    
    %conversion loop
    for i=1:length(fileList)
        display(['converting file ',fileList{i}])
        %push file to wr2100binary reader
        radar_struct = read_wr2100binary(fileList{i});
        %push out to odimh5
        abort = write_odimh5(radar_struct,output_path);
        if abort == 1
            display('***processing aborted***')
            return
        end
    end
    
    %break while loop is kill file is not present
    if exist(kill_path,'file')~=2
        display('***processing killed***')
        break
    end
    
    %append fileList to temp archive
    if ~isempty(fileList)
        fileList_archive = [fileList_archive;fileList];
        save(fileList_path,'fileList_archive');
    end
    
    display([num2str(length(fileList)),' new files converted. ',num2str(length(fileList_archive)),' total files converted.',10])
end

display('***processing ended***')


