function data_struct=read_wr2100binary_v3(binary_ffn_list)

%v3: updated Nov 2015 to read new header information regarding utc time and
%pulse specifications and QC data field. All files collected from 9/11/2015 onwards will
%require this reader. All files before this date use version 2

src_type='wr2100_binary';
for i = 1:length(binary_ffn_list)
    display(['loading binary file ',num2str(i),' of ',num2str(length(binary_ffn_list))])
    binary_ffn = binary_ffn_list{i};

    % Open file
    %binary_ffn = '/home/meso/test_binary/20141126_163707_000.rhi';
    fid = fopen(binary_ffn);

    %Read Header (apply scaling)
    header_size = fread(fid, 1, 'ushort');
    file_vrsion = fread(fid, 1, 'ushort');

    file_year   = fread(fid, 1, 'ushort');
    file_month  = fread(fid, 1, 'ushort');
    file_day    = fread(fid, 1, 'ushort');
    file_hour   = fread(fid, 1, 'ushort');
    file_min    = fread(fid, 1, 'ushort');
    file_sec    = fread(fid, 1, 'ushort');
    file_datetime = datenum(file_year,file_month,file_day,file_hour,file_min,file_sec);

    lat_deg     = fread(fid, 1, 'short');
    lat_min     = fread(fid, 1, 'ushort');
    lat_sec     = fread(fid, 1, 'ushort')/1000;
    lat_dec     = dms2degrees([lat_deg,lat_min,lat_sec]);

    lon_deg     = fread(fid, 1, 'short');
    lon_min     = fread(fid, 1, 'ushort');
    lon_sec     = fread(fid, 1, 'ushort')/1000;
    lon_dec     = dms2degrees([lon_deg,lon_min,lon_sec]);

    ant_alt_up  = fread(fid, 1, 'ushort');       %cm
    ant_alt_low = fread(fid, 1, 'ushort');       %cm
    ant_rot_spd = fread(fid, 1, 'ushort')/10;    %rpm
    prf1        = fread(fid, 1, 'ushort')/10;    %Hz
    prf2        = fread(fid, 1, 'ushort')/10;    %Hz
    puls_noise  = fread(fid, 1, 'short')/100;    %dBm
    freq_noise  = fread(fid, 1, 'short')/100;    %dBm
    num_smpls   = fread(fid, 1, 'ushort');       %qty
    num_gates   = fread(fid, 1, 'ushort');       %qty
    gate_res    = fread(fid, 1, 'ushort')/100;   %m

    %create rng_vec from parameters
    scan_rng   = gate_res:gate_res:num_gates*gate_res;

    const_horz_mantissa       = fread(fid, 1, 'long');
    const_horz_characteristic = fread(fid, 1, 'short');
    const_vert_mantissa       = fread(fid, 1, 'long');
    const_vert_characteristic = fread(fid, 1, 'short');

    azi_offset = fread(fid, 1, 'ushort')/100; %degTn
    
    rec_utc_year = fread(fid, 1, 'ushort');
    rec_utc_mon  = fread(fid, 1, 'ushort');
    rec_utc_day  = fread(fid, 1, 'ushort');
    rec_utc_hour = fread(fid, 1, 'ushort');
    rec_utc_min  = fread(fid, 1, 'ushort');
    rec_utc_sec  = fread(fid, 1, 'ushort');
    rec_item     = fread(fid, 1, 'ushort'); 
    
    tx_blind_rng  = fread(fid, 1, 'ushort'); %m
    tx_pulse_spec = fread(fid, 1, 'ushort'); %1-10
    
    scan_type  = binary_ffn(end-2:end); %filename extension

    %create empty data matricies
    empty_vec = zeros(num_smpls,1);
    empty_mat = zeros(num_smpls,num_gates);

    %preallocate
    scan_id         = empty_vec;
    scan_azi        = empty_vec;
    scan_bytes      = empty_vec;
    scan_elv        = empty_vec;
    scan_rain       = empty_mat;
    scan_zhh        = empty_mat;
    scan_vel        = empty_mat;
    scan_zdr        = empty_mat;
    scan_kdp        = empty_mat;
    scan_phidp      = empty_mat;
    scan_rohv       = empty_mat;
    scan_specwidth  = empty_mat;
    scan_qc         = empty_mat;

    %begin data read loop
    for j=1:num_smpls
        %read ray dims
        info_id    = fread(fid, 1, 'ushort');
        ray_azi   = fread(fid, 1, 'ushort')/100; %deg
        ray_elv   = fread(fid, 1, 'short')/100;  %deg

        %Read ray data

        %number of bytes in ray
        ray_bytes = fread(fid, 1, 'ushort');

        %Rain Rate (mm/h)
        ray_rain = fread(fid, num_gates, 'ushort');
        ray_rain(ray_rain==0) = NaN;
        ray_rain = (ray_rain-32768)./100;

        %Horz Refl (dBZ)
        ray_zhh = fread(fid, num_gates, 'ushort');
        ray_zhh(ray_zhh==0) = NaN;
        ray_zhh = (ray_zhh-32768)./100;

        %Doppler Velocity (m/s)
        ray_vel = fread(fid, num_gates, 'ushort');
        ray_vel(ray_vel==0) = NaN;
        ray_vel = (ray_vel-32768)./100;

        %Refl ratio (dB)
        ray_zdr = fread(fid, num_gates, 'ushort');
        ray_zdr(ray_zdr==0) = NaN;
        ray_zdr = (ray_zdr-32768)./100;

        %Propagation phase difference rate of change (deg/km) (kpd)
        ray_kdp = fread(fid, num_gates, 'ushort');
        ray_kdp(ray_kdp==0) = NaN;
        ray_kdp = (ray_kdp-32768)./100;

        %Differential Phase Shift (deg) (phidp)
        ray_phidp = fread(fid, num_gates, 'ushort');
        ray_phidp(ray_phidp==0) = NaN;
        ray_phidp = 360.*(ray_phidp-1)./65535;

        %Correlation coefficient (rhohv)
        ray_rohv = fread(fid, num_gates, 'ushort');
        ray_rohv(ray_rohv==0) = NaN;
        ray_rohv = 2.*(ray_rohv-1)./65534;

        %Doppler Spectral Width (m/s)
        ray_specwidth = fread(fid, num_gates, 'ushort');
        ray_specwidth(ray_specwidth==0) = NaN;
        ray_specwidth = (ray_specwidth-1)./100;

        %QC
        ray_qc = fread(fid, num_gates, 'ushort');

        %allocate
        scan_id(j)          = info_id;
        scan_azi(j)         = ray_azi;
        scan_elv(j)         = ray_elv;
        scan_bytes(j)       = ray_bytes;
        scan_rain(j,:)      = ray_rain;
        scan_zhh(j,:)       = ray_zhh;
        scan_vel(j,:)       = ray_vel;
        scan_zdr(j,:)       = ray_zdr;
        scan_kdp(j,:)       = ray_kdp;
        scan_phidp(j,:)     = ray_phidp;
        scan_rohv(j,:)      = ray_rohv;
        scan_specwidth(j,:) = ray_specwidth;
	scan_qc(j,:)        = ray_qc;

    end
    fclose(fid);

    %export header
    header_suffix = ['header',num2str(i)];
    data_struct.(header_suffix) = struct('header_size',header_size,'file_vrsion',file_vrsion,...
        'file_datetime',file_datetime,'lat_dec',lat_dec,'lon_dec',lon_dec,...
        'ant_alt_up',ant_alt_up,'ant_alt_low',ant_alt_low,'ant_rot_spd',ant_rot_spd,...
        'prf1',prf1,'prf2',prf2,'puls_noise',puls_noise,'freq_noise',freq_noise,...
        'num_smpls',num_smpls,'num_gates',num_gates,'gate_res',gate_res,...
        'const_horz_mantissa',const_horz_mantissa,'const_horz_characteristic',const_horz_characteristic,...
        'const_vert_mantissa',const_vert_mantissa,'const_vert_characteristic',const_vert_characteristic,...
        'azi_offset',azi_offset,'scan_type',scan_type,'src_type',src_type,...
        'rec_utc_year',rec_utc_year,'rec_utc_mon',rec_utc_mon,'rec_utc_day',rec_utc_day,...
        'rec_utc_hour',rec_utc_hour,'rec_utc_min',rec_utc_min,'rec_utc_sec',rec_utc_sec,...
        'rec_item',rec_item,'tx_blind_rng',tx_blind_rng,'tx_pulse_spec',tx_pulse_spec);
    %export data
    data_suffix = ['data',num2str(i)];
    data_struct.(data_suffix) = struct('scan_id',scan_id,'scan_azi',scan_azi,'scan_elv',scan_elv,'scan_rng',scan_rng,...
	'scan_bytes',scan_bytes,'scan_rain',scan_rain,'scan_zhh',scan_zhh,'scan_vel',scan_vel,'scan_zdr',scan_zdr,...
        'scan_kdp',scan_kdp,'scan_phidp',scan_phidp,'scan_rohv',scan_rohv,'scan_specwidth',scan_specwidth);
end

