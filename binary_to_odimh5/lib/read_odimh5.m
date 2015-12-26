function data_struct=read_odimh5(input_path)
%Joshua Soderholm, December 2015
%Climate Research Group, University of Queensland

%WHAT: Reads odimh5 v2.2 file (created by this program) into data_struct

%check if input is a h5 file (not a folder etc)

%check if it's a furuno data h5 file

%read everything into the struct