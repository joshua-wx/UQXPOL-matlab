function data_field = find_data_idx(radar_struct,quantity)
%Joshua Soderholm, April 2016
%Climate Research Group, University of Queensland

%WHAT: finds the data_field which matches quantity. data_field is a string
%so it can be used directly in radar_struct(data_field).data
%MUST BE CORRECT FIELD NAMES AS PER FURUNO SPECS

%init
data_field = '';
radar_struct_len = length(fields(radar_struct))-1; %first index is header
quantity_list = cell(length(radar_struct_len),1);

%build list of radar_struct quantities
for i=1:radar_struct_len 
    quantity_list{i} = radar_struct.(['data',num2str(i)]).quantity;
end

%find quanitity index
temp_idx = find(strcmp(quantity,quantity_list));
%error checking
if isempty(temp_idx)
    display(['could not find quantity ',quantity,' in radar_struct'])
    return
end
if length(temp_idx)>1
    display(['multiple entires for quantity ',quantity,' in radar_struct, does not confirm to file specs'])
    return
end
%output data_field as a string
if length(temp_idx)==1
    data_field = ['data',num2str(temp_idx)];
end


