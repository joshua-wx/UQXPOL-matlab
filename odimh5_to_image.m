function odimh5_to_image
%Joshua Soderholm, April 2016
%Climate Research Group, University of Queensland

%WHAT
%tempory function for plotting odim rhi files until pyart is fixed...

addpath('lib')

input_path = 'data/odimh5/';

%create file list from folder/file
fileList = getAllFiles(input_path);

for i=1:length(fileList)    
   target_file = fileList{i};
   radar_struct=read_odimh5(target_file);
   write_image(radar_struct);
   
end
