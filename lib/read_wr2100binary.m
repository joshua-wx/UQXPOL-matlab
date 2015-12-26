function data_struct=read_wr2100binary(binary_ffn)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: reads both v2 and v3 files using the version specification in the
%header. passes reading onto correct script

% Open file and read file version
fid         = fopen(binary_ffn);
[~]         = fread(fid, 1, 'ushort');
file_vrsion = fread(fid, 1, 'ushort');
fclose(fid);

%Select reader version
if file_vrsion==2
    data_struct = read_wr2100binary_v2(binary_ffn);
elseif file_vrsion==3
    data_struct = read_wr2100binary_v3(binary_ffn);
else
    msgbox('unknown wr2100 file version')
    return
end
    


