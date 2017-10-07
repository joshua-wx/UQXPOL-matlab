function radar_struct=add_dataset_to_radar_struct(radar_struct,data,quantity,offset,gain)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: adds a new dataset into radar_struct using next index value (field
%names). dataset contains data, quantity (uint16), offset and gain

%find next data integer
next_data_int = length(fields(radar_struct))-1+1; %note -1 reminds that their is a header field
%create field name
data_index_name = ['data',num2str(next_data_int)];
%add data using field name
radar_struct.(data_index_name)  = struct('data',data,'quantity',quantity,'offset',offset,'gain',gain);
