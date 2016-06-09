###See wiki for user guide

###Change notes
- 20151128 - Created v3 binary reader script
- 20151216 - Finish building first working version of wr2100 to hdf conversion utility (testing required) possible issues with scaling/null values too
- 20151217 - Bug fixes from first version - now working with pyart
- 20151220 - Bug fixes and new tutorial notebook
- 20151226 - Added all Furuno variaibles to odimh5 file and changed data_struct to a more universal format for adding new variables
- 20151227 - Added new lib "add_field_to_struct" and "read_odimh5"
- 20160214 - Added odim5_to_image.m and lib/write_image.m as a temporary measure for lack of odimh5 support in py-art
- 20160318 - Added calc_gc.m to repo
- 20160403 - Added attenuation_calc.m to repo
- 20160407 - Added calc_smth_data.m to repo
- 20160427 - Added documentation for GC & Attenuation to /doc
- 20160608 - Moved FURUNO_ID AZI and ELV data from h5 files into headers to be h5 compliant. Changed readers (binary, odim), odim writer, gc script
- 20160609 - Modified /what/object /data/product and /data/prodpar to match odim specs. No more PVOL since we don't produce volumes
