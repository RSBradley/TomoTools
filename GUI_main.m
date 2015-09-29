function handles = GUI_main(handles)

%Main function for generating the TomoTools GUI
% Written by: Robert S. Bradley (c) 2015
   

%% LOAD DEFAULTS FOR SIZING COMPONENTS =================================
version = handles.defaults.version;
margin = handles.defaults.margin_sz;
button_sz = handles.defaults.button_sz;
edit_sz = handles.defaults.edit_sz;
info_sz = handles.defaults.info_sz;
axes_sz = handles.defaults.axes_sz;
status_sz = handles.defaults.status_sz;
central_pos = handles.defaults.central_pos;
panel_pos =  handles.defaults.panel_pos;
subpanel_pos = handles.defaults.subpanel_pos;

%Determine screen size
set(0, 'units', 'pixels');
scrsz = get(0, 'MonitorPositions');
if size(scrsz,1)>1
    %Side by side monitor setup
    [~,mind] = min(abs(scrsz(:,1)));
    scrsz = scrsz(mind,:);    
end
scrsz1 = get(0, 'ScreenSize');

%Set size of figure
apr = scrsz(3)/scrsz(4);
switch apr
    case 16/9
        fpos = [0.15 0.15 0.63 0.78];
    case 341/192
        fpos = [0.15 0.1 0.7 0.8];
    otherwise
        fpos = [0.15 0.2 0.63 0.73];
end
fpos(1:2:3) = floor(fpos(1:2:3)*scrsz(3));
fpos(2:2:4) = floor(fpos(2:2:4)*scrsz(4));

fpos(1:2) = fpos(1:2)-scrsz1(1:2);

%if fpos(3)<570
%    %Minimum height
%    fpos(3) = 570;
%end
%if fpos(4)<595
%    %Minimum width
%    fpos(4) = 595;
%end


%% CREATE FIGURE ========================================================
%Create main figure and basic components
handles.fig = figure('MenuBar', 'none',...
                    'NumberTitle','off', 'Tag', 'TomoTools', 'Name', ['TomoTools v' version], 'Visible', 'off', 'units', 'pixels',...
                    'WindowButtonMotionFcn', @image_curr_val, 'position', fpos, 'colormap', gray(256),...
                    'WindowButtonDownFcn',{@imageclick, 1},'WindowButtonUpFcn',{@imageclick, 0},'CloseRequestFcn', @closefig, 'Color', handles.defaults.fig_colour);
setappdata(handles.fig, 'imageclick', 0);

pos = get(handles.fig, 'position');
handles.current_panel = 1;

%Next and back buttons
button_sz_ratio = [1.4 0.8];
handles.next_button = uicontrol('Style', 'pushbutton', 'Parent', handles.fig, 'Position',...
    [pos(3)-margin-button_sz(1)*button_sz_ratio(1) margin button_sz(1)*button_sz_ratio(1) button_sz(2)*button_sz_ratio(2)],...
    'String', 'Next', 'visible', 'off', 'Callback', @switch_panel, 'FontName', handles.defaults.btn_font, 'FontSize', handles.defaults.btn_fontsize, 'FontWeight', handles.defaults.btn_fontweight);
pos = get(handles.next_button, 'position'); 

handles.back_button = uicontrol('Style', 'pushbutton', 'Parent', handles.fig, 'Position',...
    [pos(1)-0.5*margin-2*button_sz(1)*button_sz_ratio(1) margin button_sz(1)*button_sz_ratio(1) button_sz(2)*button_sz_ratio(2)],...
    'String', 'Back', 'visible', 'off', 'Callback', @switch_panel, 'FontName', handles.defaults.btn_font, 'FontSize', handles.defaults.btn_fontsize, 'FontWeight', handles.defaults.btn_fontweight);
handles.queue_button = uicontrol('Style', 'pushbutton', 'Parent', handles.fig, 'Position',...
    [pos(1)-0.25*margin-button_sz(1)*button_sz_ratio(1) margin button_sz(1)*button_sz_ratio(1) button_sz(2)*button_sz_ratio(2)],...
    'String', '+Queue', 'visible', 'off', 'Callback', @switch_panel, 'FontName', handles.defaults.btn_font, 'FontSize', handles.defaults.btn_fontsize, 'FontWeight', handles.defaults.btn_fontweight);
handles.status_text = uicontrol('Style', 'text', 'Parent', handles.fig, 'Position',....
        [panel_pos(1)*pos(1) margin status_sz], 'HorizontalAlignment', 'Left','BackgroundColor', handles.defaults.fig_colour);

%Colour buttons
%colorbutton(handles.queue_button, handles.defaults.queue_colour(1,:), handles.defaults.queue_colour(2,:));
%colorbutton(handles.next_button, handles.defaults.next_colour(1,:), handles.defaults.next_colour(2,:));
colorbutton(handles.queue_button, handles.defaults.queue_colour(2,:), [1 1 1]+0*handles.defaults.queue_colour(2,:), 'edge');
colorbutton(handles.next_button, handles.defaults.next_colour(2,:), [1 1 1]+0*handles.defaults.next_colour(2,:),'edge');
colorbutton(handles.back_button, handles.defaults.back_colour(2,:), [1 1 1]+0*handles.defaults.back_colour(2,:), 'edge');


%Close figure method - delete objects
    function closefig(~,~,~)                    
       handles.del_fcn(handles.fig);
       
       %delete(handles.DATA);       
       %delete(handles);
       %delete(handles.fig);   
       
    end



%% OPEN PANEL ========================================================
%Create panel for file chooser

handles.fopen_panel = uipanel('Parent', handles.fig,'Units', 'normalized', 'Position', panel_pos, 'Title', 'Start', 'BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour);
set(handle(handles.fopen_panel), 'BorderType', 'line',  'HighlightColor', handles.defaults.border_colour, 'BorderWidth', handles.defaults.border_width);           

set(handles.fopen_panel, 'units', 'pixels');
panel_sz = get(handles.fopen_panel, 'position');
panel_sz(2) = panel_sz(2)+40;
panel_sz(4) = panel_sz(4)-40;
set(handles.fopen_panel, 'position', panel_sz);

% try
%     jfopen_panel = handles.fopen_panel.JavaFrame.getPrintableComponent;
% catch
%     jfopen_panel = findjobj(handles.fopen_panel);
% end
% jfopen_panel
% jNewBorder = javax.swing.border.LineBorder(java.awt.Color(1,1,1), 3, true);
% jfopen_panel.getBorder.setBorder(jNewBorder);
% jfopen_panel.repaint; 


info_sz = [(panel_sz(3)-3*margin)/2.5 (panel_sz(4)-3*margin)/3];%(panel_sz(3)-3*margin)*[1/2.5 1/3];
axes_sz = min(panel_sz(3)-info_sz(1)-5*margin,panel_sz(4)-central_pos-button_sz(2)-6*margin)*[1 1];

%Add open push button
handles.fopen_button = uicontrol('Style', 'pushbutton', 'Parent', handles.fopen_panel, 'String', 'Open', 'units', 'pixels', 'Callback', @file_open_callback);
set(handles.fopen_button, 'position', [margin panel_sz(4)-central_pos-button_sz(2)/2 1.2*button_sz(1) button_sz(2)], 'FontWeight', handles.defaults.btn_fontweight); 
colorbutton(handles.fopen_button, handles.defaults.open_colour(2,:), [1 1 1]+0*handles.defaults.open_colour(2,:),'edge');

%Add icon
%iconUrl = strrep(['file:/' pwd '/TTicon60.jpg'],'\','/');

%handles.icon_button = uicontrol('Style', 'pushbutton', 'Parent', handles.fopen_panel, 'String', ['<html><img src="' iconUrl '"/></html>'], 'units', 'pixels', 'Enable', 'on');
%set(handles.icon_button, 'position', [panel_sz(3)-button_sz(1)-margin panel_sz(4)-central_pos-button_sz(2)/2 58 60]); 

pos = get(handles.fopen_button, 'position');

%Add file edit box
handles.fopen_edit = uicontrol('Style', 'edit', 'Parent', handles.fopen_panel);
set(handles.fopen_edit, 'position', [pos(1)+pos(3)+margin panel_sz(4)-central_pos-edit_sz(2)/2 1.5*edit_sz(1) edit_sz(2)], 'HorizontalAlignment', 'Left');
set(handles.fopen_edit, 'BackgroundColor', [1 1 1]);

%Add file info text control
handles.info_text = uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'BackgroundColor', [1 1 1], 'Max', 1.5, 'visible', 'off');
set(handles.info_text, 'position', [margin pos(2)-info_sz(2)-2*margin info_sz(1) info_sz(2)], 'HorizontalAlignment', 'Left', 'String', '');
pos = get(handles.info_text, 'position');

%Add axes for preview image
handles.previewframe = uipanel('parent', handles.fopen_panel, 'units', 'pixels', 'BorderType', 'line','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour);
set(handles.previewframe, 'position', [panel_sz(3)-axes_sz(1)-2*margin, pos(2)+pos(4)-axes_sz(2)-10 axes_sz(1) axes_sz(2)+10]);

%old pos = [pos(1)+pos(3)+margin, pos(2)+pos(4)-axes_sz(2)-10 axes_sz(1) axes_sz(2)+10]

handles.licence_txt = uicontrol('Style', 'text', 'parent', handles.previewframe, 'position', [5*margin 10*margin axes_sz(1)-10*margin axes_sz(2)-30*margin], 'String', get_license, 'HorizontalAlignment', 'Left','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour);

handles.ruler_btn = uicontrol('Style', 'push', 'parent', handles.previewframe, 'position', [axes_sz(1)-48 axes_sz(2)+10 24 24], 'String', ['<html><img src="file:/' handles.defaults.ruler_icon '"></html>'], 'Callback', @ruler, 'Visible', 'off');
handles.snapshot_btn = uicontrol('Style', 'push', 'parent', handles.previewframe, 'position', [axes_sz(1)-24 axes_sz(2)+10 24 24], 'String', ['<html><img src="file:/' handles.defaults.snapshot_icon '"></html>'],'Callback', @snapshot,'Visible', 'off');
handles.zoomin_btn = uicontrol('Style', 'push', 'parent', handles.previewframe, 'position', [axes_sz(1)-72 axes_sz(2)+10 24 24], 'String', ['<html><img src="file:/' handles.defaults.zoomin_icon '"/></html>'], 'Callback', {@Zoom, 1/handles.defaults.zoom_step}, 'Visible', 'off');
handles.zoomout_btn = uicontrol('Style', 'push', 'parent', handles.previewframe, 'position', [axes_sz(1)-96 axes_sz(2)+10 24 24], 'String', ['<html><img src="file:/' handles.defaults.zoomout_icon '"/></html>'],'Callback', {@Zoom, handles.defaults.zoom_step},'Visible', 'off');
handles.pan_btn = uicontrol('Style', 'togglebutton', 'parent', handles.previewframe, 'position', [axes_sz(1)-120 axes_sz(2)+10 24 24], 'String', ['<html><img src="file:/' handles.defaults.pan_icon '"/></html>'],'Callback', 'pan;','Visible', 'off');


handles.preview_axes = axes('parent', handles.fopen_panel, 'units', 'pixels');
set(handles.preview_axes, 'position', [panel_sz(3)-axes_sz(1)-2*margin, pos(2)+pos(4)-axes_sz(2) axes_sz(1) axes_sz(2)], 'visible', 'off');

%Slice changer for preview image
handles.preview_scroll = uicontrol('Style', 'slider', 'parent', handles.fopen_panel, 'Position',  [panel_sz(3)-axes_sz(1)-2*margin, pos(2)+pos(4)-axes_sz(2)-2*margin axes_sz(1) 2*margin],...
                        'visible', 'off', 'SliderStep', [1 1],'Callback', @slice_change,'BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour);
                    
pos_scroll = get(handles.preview_scroll, 'Position');
                    
%Text specifying preview image number
%handles.preview_text_panel = uicontainer('parent', handles.fopen_panel, 'units', 'pixels','Position',  [pos_scroll(1), pos_scroll(2)-2.5*margin axes_sz(1) 2*margin],...
%                        'visible', 'on', 'BackgroundColor', handles.defaults.panel_colour);   
handles.preview_text = uicontrol('Style', 'edit', 'parent', handles.fopen_panel, 'Units', 'pixels', 'Position',  [pos_scroll(1), pos_scroll(2)-2.5*margin axes_sz(1) 2*margin],...
                        'visible', 'on', 'String', '','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour,'Callback', @slice_change);   

clip1 =  uicontrol('Style', 'text', 'parent', handles.fopen_panel, 'Position',  [pos_scroll(1), pos_scroll(2)-2.5*margin-2 axes_sz(1) 4],'BackgroundColor', handles.defaults.panel_colour);                      
clip2 =  uicontrol('Style', 'text', 'parent', handles.fopen_panel, 'Position',  [pos_scroll(1), pos_scroll(2)-2.5*margin-2+2*margin axes_sz(1) 4],'BackgroundColor', handles.defaults.panel_colour);                      

%Display scale options                    
handles.displayscale_text =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1), pos(2)+pos(4)-info_sz(2)-7*margin 9*margin 2*margin],...
        'HorizontalAlignment', 'Left', 'String', 'Display Options:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');                 
                    
pos = get(handles.displayscale_text, 'Position');
pos(3) = pos(3)*2/3;  
handles.displayscale_mintext =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1)+3*margin, pos(2)-3*margin pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Minimum:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts'); 
   
posmin = get(handles.displayscale_mintext, 'Position');  
handles.displayscale_min =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [posmin(1)+posmin(3)+margin posmin(2) 6*margin posmin(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @slice_change, 'Enable', 'off' , 'Tag', 'TTmainopts');    
   
handles.displayscale_maxtext =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [posmin(1)+posmin(3)+2*margin+6*margin, posmin(2) pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Maximum:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');    

posmax =  get(handles.displayscale_maxtext, 'Position');   
    
handles.displayscale_max =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [posmax(1)+posmax(3)+margin posmax(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @slice_change, 'Enable', 'off' , 'Tag', 'TTmainopts');     

posmax =  get(handles.displayscale_max, 'Position');  
    
handles.calc_histogram = uicontrol('Style', 'pushbutton', 'Parent', handles.fopen_panel, 'String', ['<html><img src="file:/' handles.defaults.hist_icon '"/></html>'], ...
         'Position', [posmax(1)+posmax(3)+margin posmax(2) 28 28],'Callback', @plot_histogram, 'Enable', 'off', 'Tag', 'TTmainopts'); 
%colorbutton(handles.calc_histogram,0.2*[1 1 1]+0.8*handles.defaults.open_colour(2,:), [1 1 1]+0*handles.defaults.open_colour(2,:),'edge');   
     
posc = get(handles.calc_histogram, 'Position');
handles.curr_position_x = uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1)+3*margin posc(2)-5*margin pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'x:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts'); 
handles.curr_position_y = uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1)+pos(3)+3.5*margin posc(2)-5*margin pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'y:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts'); 

handles.curr_position_z = uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1)+2*pos(3)+4*margin posc(2)-5*margin pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'z:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');     
    
handles.curr_img_value = uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1)+3*pos(3)+4.5*margin posc(2)-5*margin 2*pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'value:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');   

   
handles.set_coords = uicontrol('Style', 'pushbutton', 'Parent', handles.fopen_panel, 'Position', [posc(1) posc(2)-5*margin 28 28], 'String', ['<html><img src="file:/' handles.defaults.coordinates_icon '"/></html>'],...
        'Callback', @set_coordinates, 'Enable', 'off', 'Tag', 'TTmainopts');       

    
    
    
%Crop boxes
posmax = get(handles.displayscale_max, 'Position');
margin_new = pos(1);
pos(2) = posmax(2)-10*margin;
handles.crop_text = uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [margin_new pos(2) 2*pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Crop Options:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');
posmin = get(handles.displayscale_mintext, 'Position');
    
handles.croptop_label =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [pos(1)+3*margin, pos(2)-3*margin pos(3) pos(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Top:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');  
postop = get(handles.croptop_label, 'Position');   
    
handles.croptop_box =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [postop(1)+postop(3) postop(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @recrop, 'Enable', 'off' , 'Tag', 'TTmainopts');
    
   
handles.cropbottom_label =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [postop(1)+postop(3)+posmax(3)+2*margin postop(2) 6*margin postop(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Bottom:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');  
posbottom = get(handles.cropbottom_label, 'Position');   
    
handles.cropbottom_box =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [posbottom(1)+posbottom(3) posbottom(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @recrop, 'Enable', 'off' , 'Tag', 'TTmainopts');    
         

handles.cropleft_label =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [postop(1) postop(2)-3*margin 6*margin posmin(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Left:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');  
posleft = get(handles.cropleft_label, 'Position');   
    
handles.cropleft_box =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [posleft(1)+posleft(3) posleft(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @recrop, 'Enable', 'off' , 'Tag', 'TTmainopts');
    
handles.cropright_label =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [postop(1)+postop(3)+posmax(3)+2*margin posleft(2) 6*margin posleft(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Right:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');  
posright = get(handles.cropright_label, 'Position');   
    
handles.cropright_box =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [posright(1)+posright(3) posright(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @recrop, 'Enable', 'off' , 'Tag', 'TTmainopts');    
    
    
handles.cropfirst_label =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [postop(1) posleft(2)-3*margin 6*margin posmin(4)],...
        'HorizontalAlignment', 'Left', 'String', 'First:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');  
posfirst = get(handles.cropfirst_label, 'Position');   
    
handles.cropfirst_box =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [posfirst(1)+posfirst(3) posfirst(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @recrop, 'Enable', 'off' , 'Tag', 'TTmainopts');
    
handles.croplast_label =  uicontrol('Style', 'text', 'Parent', handles.fopen_panel, 'Position', [postop(1)+postop(3)+posmax(3)+2*margin posfirst(2) 6*margin posfirst(4)],...
        'HorizontalAlignment', 'Left', 'String', 'Last:','BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour, 'Tag', 'TTmainopts');  
poslast = get(handles.croplast_label, 'Position');   
    
handles.croplast_box =  uicontrol('Style', 'edit', 'Parent', handles.fopen_panel, 'Position', [poslast(1)+poslast(3) poslast(2) 6*margin posmax(4)],...
        'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1], 'Callback', @recrop, 'Enable', 'off', 'Tag', 'TTmainopts' ); 
    
if poslast(2)<margin
   dpos = margin-poslast(2);
   MO = findobj('Tag', 'TTmainopts');
   for nMO = 1:numel(MO)
      ptmp = get(MO(nMO), 'Position');
      ptmp(2) = ptmp(2)+dpos;
      set(MO(nMO), 'Position', ptmp);       
   end
end
    
%Create crop patches    
handles.croppatches = {[] [] [] [] [] []};

%Image used for selecting crop
handles.featurecrop_img =[];
 
%Add mouse motion events
handles.flatfield_cbox = [];

%current image and handle
handles.current_img = [];
handles.current_imgh = @() get_img;

%scalebar
handles.scalebar = [];

%set coordinates
handles.use_coordinates = 0;

handles.getDATA = @getDATA;
handles.getSINODATA = @getSINODATA;

    function cimg = get_img
        
        cimg = handles.current_img;
        
        %Crop as cimg is uncropped
        Lcrop = round(str2num(get(handles.cropleft_box, 'String')));       
        Rcrop = round(str2num(get(handles.cropright_box, 'String')));
        TOPcrop = round(str2num(get(handles.croptop_box, 'String')));        
        BTMcrop = round(str2num(get(handles.cropbottom_box, 'String')));
        
        cimg = cimg(1+TOPcrop:end-BTMcrop,1+Lcrop:end-Rcrop);
        
        
    end

    function data = getDATA
        
        data = handles.DATA;
        
        
    end

    function data = getSINODATA
        
        data = handles.SINODATA;        
        
    end

    function Zoom(~,~,factor)
        
        %Get current limits
        xl = get(handles.preview_axes, 'XLim');
        yl = get(handles.preview_axes, 'YLim');
        
        xrng = factor*(xl(2)-xl(1));
        yrng = factor*(yl(2)-yl(1));
        
        xmn = (xl(2)+xl(1))/2;
        ymn = (yl(2)+yl(1))/2;
        
        
        dims = handles.DATA.dimensions;
        if xrng>=dims(2) | yrng>=dims(1)
            xrng = dims(2);
            yrng = dims(1);
            xmn = dims(2)/2+0.25;
            ymn = dims(1)/2+0.25;
        end
        
        set(handles.preview_axes, 'XLim', xmn+xrng*0.5*[-1 1], 'YLim', ymn+yrng*0.5*[-1 1]);
    end

    function slice_change(hObject,~,~)        
        %CHANGE DISPLAY SLICE
        
        %load image
        warning off
        
        if isempty(handles.DATA)
            return;
        end
        
        %Load when stopped changing
        try
            if strcmp(get(hObject, 'ValueIsAdjusting'), 'on')                
                return;
            end
        catch
        end        
        
        tic;
        
        %Slice
        if~strcmpi(get(hObject, 'Style'), 'slider')
           img_no = str2num(get(handles.preview_text, 'String'));          
           if img_no<1 || img_no>get(handles.preview_scroll, 'max')
               set(handles.preview_text, 'String', num2str(round(get(handles.preview_scroll, 'Value'))));  
           else
               set(handles.preview_scroll, 'Value', img_no);
           end 
        end
        img_no = round(get(handles.preview_scroll, 'Value'));                
        handles.DATA.apply_ff=handles.do_flatfield; 
        
        img = single(handles.DATA(:,:,img_no));        
        handles.current_img = img;
        
        rngmin = str2num(get(handles.displayscale_min, 'String'));
        rngmax = str2num(get(handles.displayscale_max, 'String'));
        
        %Scale for display
        try
            cdata = uint8(255*(img-rngmin)/(rngmax-rngmin));
        catch
            cdata = uint8(255*(img-handles.DATA.data_rng(1))/(handles.DATA.data_rng(2)-handles.DATA.data_rng(1)));
        end
        
                
        %Show image
        set(handles.image, 'CData', cdata);
        set(handles.preview_text, 'String',num2str(img_no));
        
        
        %Update text
        if ~isempty(handles.update_text)
          str = [];
          for nut = 1:numel(handles.update_text)
             if ~isempty(handles.update_text{nut})
                str = [str sprintf([handles.update_text{nut}{1} ':  ' num2str(handles.update_text{nut}{2}(img_no)) '\n' ])];   
             end
          end
          set(handles.info_text, 'String', [handles.static_text str]); 
            
        end
        
        %Show crop if necessary
        Fcrop = round(str2num(get(handles.cropfirst_box, 'String')));
        set(handles.cropfirst_box, 'String', num2str(Fcrop));
        LSTcrop = round(str2num(get(handles.croplast_box, 'String')));
        set(handles.croplast_box, 'String', num2str(LSTcrop));
        if img_no<Fcrop            
           set(handles.croppatches{5}, 'Visible', 'on');
        else            
            set(handles.croppatches{5}, 'Visible', 'off');
        end    
        if img_no>LSTcrop
           set(handles.croppatches{6}, 'Visible', 'on');
        else
            set(handles.croppatches{6}, 'Visible', 'off');
        end
        
        toc
        warning on
    
        
    end  


    function recrop(~,~,~)
        %UPDATE CROP INDICATORS
        dims = handles.DATA.dimensions;
        
        %Get crop values
        Lcrop = max(0,round(str2num(get(handles.cropleft_box, 'String'))));        
        Rcrop = max(0,round(str2num(get(handles.cropright_box, 'String'))));        
        TOPcrop = max(0,round(str2num(get(handles.croptop_box, 'String'))));        
        BTMcrop = max(0,round(str2num(get(handles.cropbottom_box, 'String'))));        
        Fcrop = max(1,round(str2num(get(handles.cropfirst_box, 'String'))));        
        LSTcrop = min(dims(3),round(str2num(get(handles.croplast_box, 'String'))));
        
        set(handles.cropleft_box, 'String', num2str(Lcrop));
        set(handles.cropright_box, 'String', num2str(Rcrop));
        set(handles.croptop_box, 'String', num2str(TOPcrop));
        set(handles.cropbottom_box, 'String', num2str(BTMcrop));
        set(handles.cropfirst_box, 'String', num2str(Fcrop));
        set(handles.croplast_box, 'String', num2str(LSTcrop));
        
        %UPDATE DATA3D ROI
        handles.DATA.ROI = [1+TOPcrop 1+Lcrop Fcrop;1 1 1;dims(1)-BTMcrop dims(2)-Rcrop LSTcrop];
        
        
        %Get limits
        %xlim = get(handles.preview_axes, 'XLim');
        %ylim = get(handles.preview_axes, 'YLim');
        
        %set patch positions for x and y
        Ty = get(handles.croppatches{1}, 'YData');
        %Ty = get(handles.croppatches{1}, 'XData');
        
        %Ty(1:2) = ylim(1)+TOPcrop;
        Ty(1:2) = TOPcrop;
        set(handles.croppatches{1}, 'YData', Ty);
        
        By = get(handles.croppatches{2}, 'YData');
        %By(1:2) = ylim(2)-BTMcrop;
        By(1:2) = dims(1)-BTMcrop;
        set(handles.croppatches{2}, 'YData', By);
        
        Lx = get(handles.croppatches{3}, 'XData');
        %Lx(1:2) = xlim(1)+Lcrop;
        Lx(1:2) = Lcrop;
        set(handles.croppatches{3}, 'XData', Lx);
        
        Rx = get(handles.croppatches{4}, 'XData');
        %Rx(1:2) = xlim(2)-Rcrop;
        Rx(1:2) = dims(2)-Rcrop;
        set(handles.croppatches{4}, 'XData', Rx);
        
        %set patch visibility for z
        img_no = round(get(handles.preview_scroll, 'Value'));
        
        if img_no<Fcrop            
           set(handles.croppatches{5}, 'Visible', 'on');
        else            
            set(handles.croppatches{5}, 'Visible', 'off');
        end    
        if img_no>LSTcrop
           set(handles.croppatches{6}, 'Visible', 'on');
        else
            set(handles.croppatches{6}, 'Visible', 'off');
        end
        
        
        
    end

    function plot_histogram(~,~,~)
        %PLOT DATA HISTOGRAM               
        
        options.FigColor = handles.defaults.panel_colour;
        options.ButtonNames = {'current image', 'image stack'};
        answers = TTinputdlg({'Number of histogram bins:','Skips images:', }, 'Histogram options', 1, {'256','10'}, options);
        
        if isempty(answers)
            return;
        end
        nbins = str2num(answers{1});
        
        rng = [str2num(get(handles.displayscale_min, 'String')), str2num(get(handles.displayscale_max, 'String'))];
        
        step = (rng(2)-rng(1))/nbins;
        x = rng(1)+[0:(nbins-1)]*step;
        set(handles.fig, 'Pointer', 'watch');
        pause(0.1);
        
        f = figure;
        set(f, 'Name', 'histogram','NumberTitle','off', 'Color', handles.defaults.panel_colour);
        a = axes;
        hbar = bar(x,ones(numel(x),1));
        xlabel('grey level');
        ylabel('count');
        apos = get(a, 'Position');
        apos(4)= 0.75;
        set(gca, 'Position', apos);
        set(gca, 'Units','pixels');
        axis_mode = {'linear', 'log'};
        axistype_cbox = uicontrol('Style', 'checkbox', 'Parent', f,...
                                    'BackgroundColor', handles.defaults.panel_colour, 'Position',[fpos(3)-75-25-80 fpos(4)-40 65 30], 'String', 'Log axis', 'Callback', {@(x, y, z) set(gca, 'YScale', axis_mode{get(x, 'Value')+1})});
        drawnow;
        pause(0.01)
        fpos = get(f, 'Position');
        do_stop = 0;
        stop_btn = uicontrol('Style', 'pushbutton', 'Parent', f, 'Position',[fpos(3)-75-25 fpos(4)-40 65 30], 'String', 'stop', 'Callback', {@(x, y, z) eval('do_stop = z;'), 1}, 'Visible', 'off');
        fit_btn = uicontrol('Style', 'pushbutton', 'Parent', f, 'Position',[fpos(3)-75-25 fpos(4)-40 65 30], 'String', 'peaks', 'Callback', @(x, y, z) kdepeak_pos(get(hbar, 'XData'),get(hbar, 'YData')), 'Visible', 'off');
        
        
        %SET CROPPING
        %Determine slice range
        Fcrop = round(str2num(get(handles.cropfirst_box, 'String')));
        LSTcrop = round(str2num(get(handles.croplast_box, 'String')));
        

        %Determine crop range
        Tcrop = round(str2num(get(handles.croptop_box, 'String')));
        Bcrop = round(str2num(get(handles.cropbottom_box, 'String')));
        Lcrop = round(str2num(get(handles.cropleft_box, 'String')));
        Rcrop = round(str2num(get(handles.cropright_box, 'String')));
    
        ROI = handles.DATA.ROI;
        crop_rng = [1+Tcrop 1+Lcrop Fcrop; 1 1 1; handles.DATA.dimensions(1)-Bcrop handles.DATA.dimensions(2)-Rcrop LSTcrop];        
 
        switch answers{3}
            case 'current image'               
                warning off
                img_scale = uint16((nbins-1)*(handles.current_img-rng(1))/(rng(2)-rng(1)));                
                h = histc(img_scale(:), 0:(nbins-1));
                warning on
                set(hbar, 'YData',h);
                set(fit_btn, 'Visible', 'on');
            case 'image stack'
                             
                set(stop_btn, 'Visible', 'on');
                h = 0;
                img_step = str2num(answers{2});
                if(img_step<1)
                    img_step = 1;
                end    
                pause(0.01);                
                
                warning off
                
                for n = Fcrop:img_step:LSTcrop%double(handles.hdr_short.NoOfImages)
                    
                    set(handles.status_text, 'String', ['Loading image ' num2str(n) '...']);
                    img = handles.DATA(crop_rng(1,1):crop_rng(2,1):crop_rng(3,1),crop_rng(1,2):crop_rng(2,2):crop_rng(3,2),n);                     
                    img_scale = uint16((nbins-1)*(double(img)-rng(1))/(rng(2)-rng(1)));
                    h_tmp = histc(img_scale(:), 0:(nbins-1));
                    
                    
                    h = h+h_tmp;
                    
                   
                    set(handles.status_text, 'String', ['Loading image ' num2str(n) '...Done']);
                    pause(0.001);
                    try
                    set(hbar, 'YData',h);
                    catch
                        do_stop = 2;
                    end
                    pause(0.01);

                    
                    if do_stop
                        break;
                    end    
                    %toc
                end
                if do_stop ~=2
                    set(stop_btn, 'Visible', 'off');
                    set(fit_btn, 'Visible', 'on');
                end
                warning on                
                
        end 
        set(handles.fig, 'Pointer', 'arrow');     
        handles.DATA.ROI = ROI;
    end   

    function image_curr_val(~,~,~) 
        if handles.do_pointer_val
            if ~isempty(handles.image)
                cp = get(handles.preview_axes, 'CurrentPoint');                
                dp = round([cp(1,2) cp(1,1)]);
                dz = get(handles.preview_scroll, 'Value');
                if dp(1)>0 && dp(1)<handles.hdr_short.ImageHeight+0.5 && dp(2)>0 && dp(2)<handles.hdr_short.ImageWidth+0.5
                    if handles.use_coordinates                         
                        xp = handles.DATA.coords.x.direction*(dp(2)-0.5*double(handles.hdr_short.ImageWidth))*handles.hdr_short.PixelSize+handles.DATA.coords.x.position;
                        yp = handles.DATA.coords.y.direction*(dp(1)-0.5*double(handles.hdr_short.ImageHeight))*handles.hdr_short.PixelSize+handles.DATA.coords.y.position;
                        zp = handles.DATA.coords.z.direction*(dz-0.5*double(handles.hdr_short.NoOfImages))*handles.hdr_short.PixelSize+handles.DATA.coords.z.position;
                        set(handles.curr_position_x, 'String', ['x: ' sprintf('%6.3g',xp)]);
                        set(handles.curr_position_y, 'String', ['y: ' sprintf('%6.3g',yp)]);
                        set(handles.curr_position_z, 'String', ['y: ' sprintf('%6.3g',zp)]);
                        set(handles.curr_img_value, 'String', ['value: ' sprintf('%-9.5g',handles.current_img(dp(1), dp(2)))]);                        
                    else
                    	set(handles.curr_position_x, 'String', ['x: ' num2str(dp(2))]);
                        set(handles.curr_position_y, 'String', ['y: ' num2str(dp(1))]);
                        set(handles.curr_position_z, 'String', ['y: ' sprintf('%6.3g',dz)]);
                        set(handles.curr_img_value, 'String', ['value: ' sprintf('%-9.5g',handles.current_img(dp(1), dp(2)))]);
                    end
                end
                %Crop cursor
                %Determine crop range
                Tcrop = round(str2num(get(handles.croptop_box, 'String')));
                Bcrop = round(str2num(get(handles.cropbottom_box, 'String')));
                Lcrop = round(str2num(get(handles.cropleft_box, 'String')));
                Rcrop = round(str2num(get(handles.cropright_box, 'String')));
                
                if ~getappdata(handles.fig, 'imageclick')
                if abs(dp(2)-Lcrop)<5
                    set(handles.fig, 'pointer','left');
                    setappdata(handles.fig, 'crop', 'left');
                elseif abs(dp(2)-handles.hdr_short.ImageWidth+Rcrop)<5
                    set(handles.fig, 'pointer','right');
                    setappdata(handles.fig, 'crop', 'right');
                elseif abs(dp(1)-Tcrop)<5
                    set(handles.fig, 'pointer','top');
                    setappdata(handles.fig, 'crop', 'top');
                elseif abs(dp(1)-handles.hdr_short.ImageHeight+Bcrop)<5
                    set(handles.fig, 'pointer','bottom');
                    setappdata(handles.fig, 'crop', 'bottom');
                else
                   set(handles.fig, 'pointer','arrow')
                   setappdata(handles.fig, 'crop', []);
                end
                else
                   crop_dir = getappdata(handles.fig, 'crop');
                   if ~isempty(crop_dir)
                      switch crop_dir
                          case 'left'
                             set(handles.cropleft_box,'String',num2str(round(dp(2))));  
                          case 'right'
                              set(handles.cropright_box,'String',num2str(handles.hdr_short.ImageWidth-round(dp(2))));
                          case 'top'
                              set(handles.croptop_box,'String',num2str(round(dp(1))));
                          case 'bottom'
                              set(handles.cropbottom_box,'String',num2str(handles.hdr_short.ImageHeight-round(dp(1))));
                      end
                      recrop();    
                       
                   end
                end
            end
        end
        
    end

    function imageclick(~,~,ud)
        
       if ud
           setappdata(handles.fig, 'imageclick', 1);
       else
           setappdata(handles.fig, 'imageclick', 0);
       end
        
    end


    function set_coordinates(~,~)
       %  handles.defaults.panel_colour
       f = figure('MenuBar', 'none');
       set(f, 'Name', 'Set coordinates','NumberTitle','off', 'Color',handles.defaults.panel_colour, 'position',[544 414 396 211], 'CloseRequestFcn', @close_coords);       
       h2 = uicontrol('Parent',f, 'Position',[30 170 120 23],'String','Show coordinates','HorizontalAlignment', 'left',...
            'Style','checkbox', 'value',handles.use_coordinates, 'BackgroundColor', handles.defaults.panel_colour);
       h3 = uicontrol('Parent',f, 'Position',[75 134 100 14],'String','Centre coordinates','HorizontalAlignment', 'center',...
            'Style','text','BackgroundColor', handles.defaults.panel_colour);
       h4 = uicontrol('Parent',f, 'Position',[225 134 100 14],'String','Axis direction','HorizontalAlignment', 'center',......
            'Style','text','BackgroundColor', handles.defaults.panel_colour); 
       h5 = uicontrol('Parent',f, 'Position',[30 100 40 14],'String','x:','HorizontalAlignment', 'right',...
            'Style','text','BackgroundColor', handles.defaults.panel_colour); 
       h6 = uicontrol('Parent',f, 'Position',[30 68 40 14],'String','y:','HorizontalAlignment', 'right',...
            'Style','text','BackgroundColor', handles.defaults.panel_colour);
       h7 = uicontrol('Parent',f, 'Position',[30 36 40 14],'String','z:','HorizontalAlignment', 'right',...
            'Style','text','BackgroundColor', handles.defaults.panel_colour);
       h8 = uicontrol('Parent',f, 'Position',[100 100 65 16],'String',num2str(handles.DATA.coords.x.position),'HorizontalAlignment', 'right',...
            'Style','edit', 'BackgroundColor', [1 1 1]); 
       h9 = uicontrol('Parent',f, 'Position',[100 68 65 16],'String',num2str(handles.DATA.coords.y.position),'HorizontalAlignment', 'right',...
            'Style','edit', 'BackgroundColor', [1 1 1]);
       h10 = uicontrol('Parent',f, 'Position',[100 36 65 16],'String',num2str(handles.DATA.coords.z.position),'HorizontalAlignment', 'right',...
            'Style','edit', 'BackgroundColor', [1 1 1]); 
       h11 = uicontrol('Parent',f, 'Position',[230 102 65 16],'String',{'negative';'positive'},'HorizontalAlignment', 'right',...
            'Style','popupmenu', 'BackgroundColor', [1 1 1],'value', (handles.DATA.coords.x.direction+3)/2); 
       h12 = uicontrol('Parent',f, 'Position',[230 70 65 16],'String',{'negative';'positive'}, 'HorizontalAlignment','right',...
            'Style','popupmenu', 'BackgroundColor', [1 1 1],'value', (handles.DATA.coords.y.direction+3)/2);
       h13 = uicontrol('Parent',f, 'Position',[230 38 65 16],'String',{'negative';'positive'}, 'HorizontalAlignment','right',...
            'Style','popupmenu', 'BackgroundColor', [1 1 1],'value', (handles.DATA.coords.z.direction+3)/2);  
       
        function close_coords(~,~)
        
            handles.use_coordinates = get(h2,'value');            
            if handles.use_coordinates
                handles.DATA.coords.x.position = str2num(get(h8, 'String'));
                handles.DATA.coords.y.position = str2num(get(h9, 'String'));
                handles.DATA.coords.z.position = str2num(get(h10, 'String'));
                
                handles.DATA.coords.x.direction = 2*(get(h11,'Value'))-3;
                handles.DATA.coords.y.direction = 2*(get(h12,'Value'))-3;
                handles.DATA.coords.z.direction = 2*(get(h13,'Value'))-3;                
            end
            delete(gcf);
            
        end 
    end



    function show_queue(~,~)
        %View queue        
       if ~isempty(handles.queue) 
            inds = HMqueue_table(handles.queue);
            handles.queue = handles.queue(inds);
       end  
    end  

    function file_open_callback(~,~)  
        %FILE OPEN
        handles = file_open(handles);        
    end


    function ruler(~,~)
        
       rlr = imdistline(handles.preview_axes);
       %rlr.setLabelVisible(0)
       rlr_c = get(rlr, 'Children');       
       set(rlr_c(1), 'BackgroundColor', 'none');
       set(rlr_c(2), 'Marker', 'd');
       set(rlr_c(3), 'Marker', 'd');
       set(rlr_c(5), 'Visible', 'off');
       
       rlr.setColor([1 0 0]); 
       set(rlr_c(1), 'Color', [1 0 0]); 
       rlr.addNewPositionCallback(@update_ruler)       
       update_ruler([]);
            function update_ruler(~)
               
               d = rlr.getDistance;
               ang = rlr.getAngleFromHorizontal;
               rpos = rlr.getPosition;
               fsz = get(rlr_c(1), 'Extent');
               npos = mean(rpos,1)-[fsz(3) 0]+1.5*[sind(ang)*fsz(3) cosd(ang)*fsz(4)];
               
               %nchars = ceil(4*abs([cosd(ang) sind(ang)]))
               
               set(rlr_c(1), 'String', sprintf(['Dist:  %.2f\n'   'Ang:  %.2f' char(176)], [d*handles.hdr_short.PixelSize(1) ang])); 
               set(rlr_c(1), 'Position', npos);

            end
    
    end

    function snapshot(~,~)
        rngmin = str2num(get(handles.displayscale_min, 'String'));
        rngmax = str2num(get(handles.displayscale_max, 'String'));
        imager(handles.current_img, 'range', [rngmin rngmax], 'statusbar', 0);         
        set(gcf, 'Position', double([0 0 handles.hdr_short.ImageWidth handles.hdr_short.ImageHeight]));
        
        %Copy scalebar
        sb = copyobj(handles.scalebar{1}, gca);
        set(sb, 'LineWidth', 6);
        copyobj(handles.scalebar{2}, gca);
        
        %Copy annotations
        obj = findobj('parent',handles.preview_axes, 'Tag', 'imline'); 
        for nobj = 1:numel(obj)
           c = get(obj,'Children');
           for mc = 1:4               
               copyobj(c(mc), gca);
               set(c(mc), 'UIContextMenu', get(c(5), 'UIContextMenu'));
           end
        end
        try
           F = getframe(gcf); 
        catch
           movegui(gcf, 'center');
           F = getframe(gcf);
        end
        close(gcf);
        im = frame2im(F);
        [filename, path] = uiputfile({'*.png;*.tif', 'Image files (*.png, *.tif)'}, 'Select file name');
        
        if ischar(filename)           
            % Write the data
            imwrite(im,[path filename]);
        end        
        
    end

%% MODE CHOOSER==========================================================
%Create panel for selecting modes
handles.action_panel = uipanel('Parent', handles.fig,'Units', 'normalized', 'Position', panel_pos, 'Title', 'Select action', 'visible', 'off','BackgroundColor', handles.defaults.panel_colour);
set(handle(handles.action_panel), 'BorderType', 'line',  'HighlightColor', handles.defaults.border_colour, 'BorderWidth', handles.defaults.border_width);
set(handles.action_panel, 'units', 'pixels');
panel_sz = get(handles.action_panel, 'position');
panel_sz(2) = panel_sz(2)+40;
panel_sz(4) = panel_sz(4)-40;
set(handles.action_panel, 'position', panel_sz);

%Add label 
handles.action_label = uicontrol('Style', 'text' , 'Parent', handles.action_panel, 'String', 'Plugin:   ','FontWeight', handles.defaults.btn_fontweight,....
                  'Position', [2*margin panel_sz(4)-central_pos button_sz(1) button_sz(2)],'BackgroundColor', handles.defaults.panel_colour,'ForegroundColor', handles.defaults.text_colour);
uitextsize(handles.action_label);
pos = get(handles.action_label, 'Position');
%set(handles.action_label, 'Position',[pos(1) pos(2)-

%Add action menu
menu_sz_ratio = [2.5 1];
handles.action_menu = uicontrol('Style', 'popupmenu', 'Parent', handles.action_panel, 'BackgroundColor', [1 1 1],....
                  'Position', [pos(1)+pos(3)+margin panel_sz(4)-central_pos menu_sz_ratio(1)*button_sz(1) menu_sz_ratio(2)*button_sz(2)],....
                  'String', {'Export'; 'Recontruct'}, 'Callback', @action_change);
pos = get(handles.action_menu, 'Position');
ext = get(handles.action_menu, 'Extent');
set(handles.action_menu, 'Position', [pos(1) pos(2) pos(3) ext(4)])


pos = get(handles.action_menu, 'Position');
%handles.usecluster_cbox = uicontrol('Style', 'Checkbox', 'Parent',  handles.action_panel, 'String', 'Use cluster','Value', 1,....
%                  'Position', [pos(1)+pos(3)+2*margin panel_sz(4)-central_pos-button_sz(2)/4 2*button_sz(1) button_sz(2)], 'Callback', @switch_cluster_local);
              
%pos = get(handles.usecluster_cbox, 'Position');
handles.show_queue = uicontrol('Style', 'pushbutton', 'Parent', handles.action_panel, 'FontWeight', handles.defaults.btn_fontweight,'Position',...
    [pos(1)+pos(3)+2*margin pos(2)+pos(4)/2-button_sz(2)*button_sz_ratio(2)/2 1.1*button_sz(1)*button_sz_ratio(1) button_sz(2)*button_sz_ratio(2)],...
    'String', 'View queue', 'Callback', @view_queue);
colorbutton(handles.show_queue, handles.defaults.queue_colour(2,:), [1 1 1]+0*handles.defaults.queue_colour(2,:), 'edge');




    %Nested function to switch to action panel
    function switch_panel(hObject,~,~)
        ff_enable = get(handles.flatfield_cbox, 'Enable');
        btn_str = get(hObject, 'String');
        
        %Run queue
        if strcmpi(btn_str, 'Go') && ~isempty(handles.get_queue())
            btn_str = 'Run';
        end
        
        %Queue commands
        queue = 0;
        if strcmpi(btn_str, '+Queue')
            queue = 1;
            btn_str = 'Go';
        end    
       
        switch btn_str
            case 'Next'
                %Show action panel
                if handles.current_panel==1
                    set(handles.next_button, 'String', 'Go');
                    set(handles.back_button, 'visible', 'on');
                    set(handles.queue_button, 'visible', 'on');
                    set(handles.fopen_panel, 'visible', 'off');
                    set(handles.action_panel, 'visible', 'on');
                    handles.current_panel = 2;		        
                end    
                    
            case 'Back'
                %Go back to open panel
                if handles.current_panel==2
                    set(handles.next_button, 'String', 'Next');
                    set(handles.back_button, 'visible', 'off');
                    set(handles.queue_button, 'visible', 'off');
                    set(handles.fopen_panel, 'visible', 'on');
                    set(handles.action_panel, 'visible', 'off');
                    handles.current_panel = 1;
                end 
                
            case 'Go'
                %Perform requested action
                val = get(handles.action_menu, 'Value');                
                mstr = get(handles.action_menu, 'String');
                
               if ~iscell(mstr)
                   mstr = {mstr};
               end       
               addins = handles.addins();       
               for m = 1:numel(addins)           
                   if strcmpi(addins{m}.name,mstr{val})  
                       addins{m}.run_function(handles,queue);                                      
                   end
               end
                
                %modules{action}.run_function(handles,queue);
                
            case 'Run'                
                 
                 %Create queue mfile on local machine 
                handles.run_queue(); 
               
        end
        
        set(handles.flatfield_cbox, 'Enable', ff_enable);         
    end 

    function action_change(~,~,~)

       val = get(handles.action_menu,'value');
       mstr = get(handles.action_menu, 'String');
       if ~iscell(mstr)
           mstr = {mstr};
       end       
       addins = handles.addins();       
       for m = 1:numel(addins)           
           if strcmpi(addins{m}.name,mstr{val})              
               set(addins{m}.panel, 'visible', 'on');
           else
               set(addins{m}.panel, 'visible', 'off');
           end
       end
        
    end

    function view_queue(~,~,~)        
        handles.view_queue();
    end
    
    function resizefig(~,~,~)
        
       %Define movable elements
       
        
        
        
    end






%% STOP FOR NOW
return





    function LT = get_license
        
        
       LT =  sprintf(['TomoTools is a GUI and collection of MATLAB functions which provides the following functionality for tomography data sets:\n\n'...
                       '     - Export: Conversion between different file formats (read Xradia and X-tek files (radiographs and reconstructions) and tif stacks; export to tif stacks,\n         binary files and Avizo (.am) files)\n'...
                       '     - Alignment of radiographs using a short scan or feature tracking \n'...
                       '     - Phase retrieval using the TIE-HOM algorithm for in-line phase contrast\n'...
                       '     - Reconstruction based on the ASTRA tool box (currently only parallel beam reconstruction is available)\n'...
                       '     - Apply filters to radiograph or reconstructed slices\n\n\n'...
                       'The code is written, maintained and developed by Dr Rob S Bradley at the HMXIF, The University of Manchester; please acknowledge its use.\n\n'...
                       'Copyright (c) 2015 Rob S Bradley\n\n\n']);

        
        
        
    end

end