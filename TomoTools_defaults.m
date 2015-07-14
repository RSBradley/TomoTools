function defaults = TomoTools_defaults

% Default values used by TomoTools
% Robert S. Bradley (c) 2015
defaults.version = '1.0 beta';

%Locations-----------------------------------------------------
%data directory
defaults.data_dir = 'D:\';

%local temporary directory
defaults.local_tmp_dir = 'D:\';

%imageJ_path
defaults.imageJ_path = {'D:\ImageJ\ImageJ.exe','D:\ImageJ\ImageJ\ImageJ.exe', 'C:\Program Files\ImageJ\ImageJ.exe', 'D:\Fiji\ImageJ-win64.exe'};


%Sizes--------------------------------------------------------
defaults.margin_sz = 10;
defaults.button_sz = [58 42];
defaults.edit_sz = [300 25];
defaults.info_sz = [170 200];
defaults.axes_sz = [200 200];
defaults.status_sz = [175 25];
defaults.central_pos = 50;
defaults.menu_sz_ratio = [3.5 1];
defaults.panel_pos =  [0.02 0.02 0.96 0.96];
defaults.subpanel_pos = [defaults.panel_pos(1:3) 0.8];


%Figure colours
defaults.fig_colour = [1 1 1];
defaults.panel_colour = 1*[206 209 211]/240;
defaults.text_colour = [0.2 0.2 0.2];
defaults.border_colour = [0.7 0.7 0.7];
defaults.border_width = 2;
defaults.next_colour = [0.8745 0.8980 0.8627; 0.5333 0.7608 0.5725];
defaults.queue_colour = [0.8971 0.9000 0.8265; 0.8902 0.8863 0.4471];
defaults.back_colour = [[1 1 1]; 0.7*[1 1 1]];
defaults.open_colour = [[1 1 1]; 0.7*[1 1 1]];

%Fonts
defaults.font = 'MS Sans Serif';
defaults.font_size = 8;
defaults.btn_font = 'Arial';
defaults.btn_fontsize = 9;
defaults.btn_fontweight = 'bold';

%Icons
p = fileparts(mfilename('fullpath'));
defaults.ruler_icon = strrep([p '\icons\ruler20.png'], '\', '/');
defaults.snapshot_icon = strrep([p '\icons\snapshot20.png'], '\', '/');
defaults.zoomin_icon = strrep([p '\icons\zoom_in20.png'], '\', '/');
defaults.zoomout_icon = strrep([p '\icons\zoom_out20.png'], '\', '/');
defaults.pan_icon = strrep([p '\icons\move20.png'], '\', '/');

%Colours for cropping
defaults.crop_col = [0.8 0.8 0];
defaults.crop_col2 = [0.8 0.1 0];

%scalebar
defaults.scalebar.colour = [1 1 1];
defaults.scalebar.relsize = 0.1;
defaults.scalebar.position = 'SW';
defaults.scalebar.offset = 20;
defaults.scalebar.linewidth = 12;
defaults.scalebar.font = 'Palatino';
defaults.scalebar.fontsize = 10;

%zoom
defaults.zoom_step = 1.5;

%Load methods-------------------------------------------------
%each method in a row of the cell
defaults.file_types = {'*.txrm; *.xrm; *.txm;*.vgi;*.tif;*.tiff;*.xml;*.nxs', 'All supported files';'*.txrm; *.xrm; *.txm', 'Xradia files (*.xrm, *.txm, *.txrm)';'*.vgi', 'Volume Graphics files (*.vgi)';...
                        '*.tif;*.tiff', 'Tiff stack (*.tif(f))';'*.xml', 'TTxml (*.xml)'; '*.nxs', 'NeXus files (*.nxs)'};
defaults.loadmethods = {@txmheader_read8,@txmimage_read8, {0,0,0}, @txmdata_read8;@vgiheader_read,@vgivol_read, {}, {};...
                        @tiffstackheader_read,@tiffstackimage_read, {},{};@TTxml,{}, {},{};...
                        @NXheader_read, @NXimage_read, {0,0},{}};
%defaults.writemethods = {@txm2tiff9,@txm2am,@txm2bin;@xtekvol2tiff,@xtekvol2am,@xtekvol2bin; {},{},{}};

end