function odimh5_to_image
%WHAT
%tempory function for plotting odim rhi files until pyart is fixed...

input_path = '/home/meso/RecData_BCPE_20160213/rhi/set1_odim';

%create file list from folder/file
fileList = getAllFiles(input_path);

for i=1:length(fileList)    
   target_file = fileList{i};
   data_struct=read_odimh5(target_file);
   write_image(data_struct);
   
end