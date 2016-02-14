function write_image(data_struct)
%WHAT
%Modified 13-02-2016 as a temporary fix for pyart lack of odim rhi
%capability


%extract datasets
zhh_grid        = double(data_struct.data5.data);
zhh_offset      = double(data_struct.data5.offset);
zhh_gain        = double(data_struct.data5.gain);
zhh_grid        = zhh_grid.*zhh_gain+zhh_offset;

vel_grid        = double(data_struct.data6.data);
vel_offset      = double(data_struct.data6.offset);
vel_gain        = double(data_struct.data6.gain);
vel_grid        = vel_grid.*vel_gain+vel_offset;

zdr_grid        = double(data_struct.data7.data);
zdr_offset      = double(data_struct.data7.offset);
zdr_gain        = double(data_struct.data7.gain);
zdr_grid        = zdr_grid.*zdr_gain+zdr_offset;

rhohv_grid      = double(data_struct.data10.data);
rhohv_offset    = double(data_struct.data10.offset);
rhohv_gain      = double(data_struct.data10.gain);
rhohv_grid      = rhohv_grid.*rhohv_gain+rhohv_offset;

%extract time
file_datetime = data_struct.header.rec_utc_datetime;

%setup slant range
gate_res  = data_struct.header.gate_res;
num_gates = data_struct.header.num_gates;
azi_vec   = double(data_struct.data2.data);
elv_vec   = double(data_struct.data3.data);
rng_vec   = gate_res:gate_res:gate_res*num_gates;
scan_type = data_struct.header.scan_type;

%%

%setup input grids
ang_vec = elv_vec;

%monotonic ang_vec
ang_vec = linspace(ang_vec(1),ang_vec(end),length(ang_vec));
%ndgrid
[rng_grid,ang_grid] = ndgrid(rng_vec,ang_vec);

% %remove noise from wr2100 datasets, no noise removal required for CP2
% %hybrid pulse
% noise_grid = rhohv_grid > .4;
% 
% zhh_grid(~noise_grid) = nan;
% vel_grid(~noise_grid) = nan;
% zdr_grid(~noise_grid) = nan;

%filter extreme values from velocity
extreme_mask = abs(vel_grid)>=50;
vel_grid(extreme_mask) = nan;

%setup x,y output grids
max_intp_rng = 25000;
min_intp_rhi_h = 0;
max_intp_rhi_h = 5000;
intp_grid    = 50;

intp_x_vec = -max_intp_rng:intp_grid:max_intp_rng;
intp_y_vec = min_intp_rhi_h:intp_grid:max_intp_rhi_h; %max rhi depth 15km

%convert to ang/rng
[intp_x_grid,intp_y_grid]     = meshgrid(intp_x_vec,intp_y_vec);
intp_z_grid                   = zeros(size(intp_x_grid));
[intp_ang_grid,intp_rng_grid] = cart2pol(intp_x_grid,intp_y_grid);
intp_ang_grid = rad2deg(intp_ang_grid);

%apply medfilt2 to vel
vel_grid = medfilt2(vel_grid,[7,7]);

%run interpolant
intp_zhh = interpn(ang_grid',rng_grid',zhh_grid',intp_ang_grid,intp_rng_grid,'nearest');
intp_vel = interpn(ang_grid',rng_grid',vel_grid',intp_ang_grid,intp_rng_grid,'nearest');
intp_zdr = interpn(ang_grid',rng_grid',zdr_grid',intp_ang_grid,intp_rng_grid,'nearest');

%bypass filter
filt_vel2 = intp_vel;
filt_zhh2 = intp_zhh;

%% PLOTTING
%setup figure
hfig = figure;
hold on
%convert coordinates to km
plot_x_grid = intp_x_grid./1000;
plot_y_grid = intp_y_grid./1000;

    %set figure size/render
    set(hfig,'position',[1,1,900,600],'Color','w');
    
    %plot ZHH
    surface(plot_x_grid,plot_y_grid,intp_z_grid,'CData',filt_zhh2,'EdgeColor','none','FaceColor','texturemap');
    
%     %plot negative velocity
%     if contour_neg_plot
%         contour_interval=[contour_neg_min:contour_neg_int:contour_neg_max];
%         [doplpos_C,doplpos_h]=contour(plot_x_grid,plot_y_grid,eval(contour_neg_var),contour_interval,'Fill','off','LineColor',contour_neg_line_color,'LineWidth',contour_neg_line_width,'LineStyle','-');
%         if contour_pos_labels
%             text_handle = clabel(doplpos_C,doplpos_h,contour_neg_l_vec,'LabelSpacing',contour_neg_l_space); %MODIDY LABEL INTERVAL AND SPACING
%             set(text_handle,'FontWeight','bold','FontName','Helvetica','FontSize',contour_neg_l_size);
%         end
%     end
%     %plot positive velocity
%     if contour_pos_plot
%         contour_interval=[contour_pos_min:contour_pos_int:contour_pos_max];
%         [doplpos_C,doplpos_h]=contour(plot_x_grid,plot_y_grid,eval(contour_pos_var),contour_interval,'Fill','off','LineColor',contour_pos_line_color,'LineWidth',contour_pos_line_width,'LineStyle','--');
%         if contour_pos_labels
%             text_handle = clabel(doplpos_C,doplpos_h,contour_pos_l_vec,'LabelSpacing',contour_pos_l_space); %MODIDY LABEL INTERVAL AND SPACING
%             set(text_handle,'FontWeight','bold','FontName','Helvetica','FontSize',contour_pos_l_size);
%         end
%     end
    %     %plot negative velocity
%     if contour_neg_plot
%         contour_interval=[contour_neg_min:contour_neg_int:contour_neg_max];
%         [doplpos_C,doplpos_h]=contour(plot_x_grid,plot_y_grid,eval(contour_neg_var),contour_interval,'Fill','off','LineColor',contour_neg_line_color,'LineWidth',contour_neg_line_width,'LineStyle','-');
%         if contour_pos_labels
%             text_handle = clabel(doplpos_C,doplpos_h,contour_neg_l_vec,'LabelSpacing',contour_neg_l_space); %MODIDY LABEL INTERVAL AND SPACING
%             set(text_handle,'FontWeight','bold','FontName','Helvetica','FontSize',contour_neg_l_size);
%         end
%     end
%     %plot positive velocity
%     if contour_pos_plot
%         contour_interval=[contour_pos_min:contour_pos_int:contour_pos_max];
%         [doplpos_C,doplpos_h]=contour(plot_x_grid,plot_y_grid,eval(contour_pos_var),contour_interval,'Fill','off','LineColor',contour_pos_line_color,'LineWidth',contour_pos_line_width,'LineStyle','--');
%         if contour_pos_labels
%             text_handle = clabel(doplpos_C,doplpos_h,contour_pos_l_vec,'LabelSpacing',contour_pos_l_space); %MODIDY LABEL INTERVAL AND SPACING
%             set(text_handle,'FontWeight','bold','FontName','Helvetica','FontSize',contour_pos_l_size);
%         end
%     end

    
%     %plot ZDR
%     if zdr_medfilt
%         intp_zdr = medfilt2(intp_zdr,zdr_medfilt_sz);
%     end
%     if zdr_contour
%         [zdrpos_C,zdrpos_h]=contour(plot_x_grid,plot_y_grid,intp_zdr,zdr_pos_contour_vec,'Fill','off','LineColor',zdr_pos_contour_color,'LineWidth',zdr_pos_contour_width,'LineStyle','-');
%         [zdrneg_C,zdrneg_h]=contour(plot_x_grid,plot_y_grid,intp_zdr,zdr_neg_contour_vec,'Fill','off','LineColor',zdr_neg_contour_color,'LineWidth',zdr_neg_contour_width,'LineStyle','-');
%     end
    
%setup colormap
caxis([0,40]) %MODIFY ACCORDING TO LIMITS OF SURFACE IMAGE
temp_cmap=[[1,1,1];colormap(jet(128))];
colormap(temp_cmap)


%setup axis
axis tight
axis([0,15,0,4])
hXlabel = xlabel('Range(km)');
hYlabel = ylabel('Altitude(km)');
set([hXlabel,hYlabel],'fontsize',14);
set(gca,'fontsize',10);
set(gca,'layer','top')
grid on

%setup colorbar
hColorbar = colorbar('location','eastoutside');
set(get(hColorbar,'ylabel'),'string','Reflectivity(dBZH)','fontsize',14); %MODIFY LABEL ACCORDING TO SURFACE IMAGE UNITS

% setup title
azi_txt = num2str(round(azi_vec(1)));
title(['RHI cross section for ',datestr(file_datetime,'dd-mm-yyyy HH:MM:SS'),' at azimuth ',azi_txt],'FontSize',22);

%setup legend
%hLegend =keyboard legend([doplneg_h,doplpos_h,zdrpos_h,zdrneg_h],'-Doppler velocity (m/s)','+Doppler velocity (m/s)','-zdr (dB)','+zdr (dB)'); %REMOVE ELEMENTS IF NOT HANDLES/PLOTS NOT GENERATED
%set([hLegend, gca],'FontSize',legend_font_sz);

%export
addpath('export_fig')
export_ffn = ['/home/meso/RecData_BCPE_20160213/rhi/set1_images',datestr(file_datetime,'yyyymmddHHMMSS'),'_az',azi_txt,'.png'];
print(hfig,'-dpng','-painters',export_ffn)
close(hfig)