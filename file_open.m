function [handles, fsuccess]= file_open(handles)


handles.hdr = [];

path = get(handles.fopen_edit, 'String');
if isempty(path)
path = handles.defaults.data_dir;
end    
[filename dir handles.filetype] = uigetfile(handles.defaults.file_types, 'Select file',path);
if isnumeric(filename)
    fsuccess = 0;
    return;
else
     fsuccess = 1;
end

%Determine file type
[pathstr, name, ext] = fileparts(filename);   
handles.filetype = find(cellfun(@(x) ~isempty(x), strfind(handles.defaults.file_types(2:end,1), ext), 'UniformOutput', 1));

%Open file to get information and preview
set(handles.status_text, 'String', 'Loading file information...');
set(handles.fig, 'Pointer', 'watch');
pause(0.1);

[hdr_full, hdr_short] = feval(handles.defaults.loadmethods{handles.filetype,1}, [dir filename]);       
handles.hdr = hdr_full;

%if handles.filetype<3    
    FileContents = hdr_short.FileContents;    
%else
%    FileContents = hdr_short.StackContents;
%end

set(handles.fopen_edit, 'String', [dir filename]);
%set(handles.diropen_edit, 'String', dir);




%Determine datatype
   
% % switch hdr_short.DataType
% %     case 'uint8'
% %         datatype = {'uint8', 1};
% %  %       set(handles.datatype_menu, 'Value', 1);
% %         handles.rng = [0 255];
% %     case 'uint16'
% %         datatype = {'uint16', 2};        
% % %        set(handles.datatype_menu, 'Value', 2);
% %         handles.rng = [0 65535];
% %     case 'float32'
% %         datatype = {'float32', 4};        
% % %        set(handles.datatype_menu, 'Value', 3);        
% %         handles.rng = hdr_short.DataRange;
% %     case 'single'
% %         datatype = {'float32', 4};        
% %  %       set(handles.datatype_menu, 'Value', 3);        
% %         handles.rng = hdr_short.DataRange;        
% % end   


%Set file ino string
file_info_string = [FileContents  char(10) char(10)];
if isfield(hdr_short, 'Voltage')
    file_info_string = [file_info_string 'Voltage (kV):  ' num2str(hdr_short.Voltage) char(10)];
end
if isfield(hdr_short, 'Current')
    file_info_string = [file_info_string 'Current (mA):  ' num2str(hdr_short.Current) char(10)];
end
if isfield(hdr_short, 'OpticalMagnification')
    file_info_string = [file_info_string 'Optical mag.:  ' num2str(hdr_short.OpticalMagnification) char(10)];
end
if isfield(hdr_short, 'ImageHeight')
    file_info_string = [file_info_string 'Image size:  ' num2str(hdr_short.ImageWidth) ' x ' num2str(hdr_short.ImageHeight) char(10)];
end
if isfield(hdr_short, 'DataType')
    file_info_string = [file_info_string 'Data type:  ' hdr_short.DataType char(10)];
end
pu = [];
if isfield(hdr_short, 'PixelUnits')    
    pu = [' (' hdr_short.PixelUnits ')'];
end
u = [];
if isfield(hdr_short, 'Units')
    u = [' (' hdr_short.Units ')'];
end
if isfield(hdr_short, 'PixelSize')
    if isempty(hdr_short.PixelSize)       
       answer = inputdlg({'Enter pixel size in microns:'},'TomoTools error: pixel size missing',1,{'1'});
       hdr_short.PixelSize = str2num(answer{1});
       hdr_short.PixelUnits = 'microns';
       pu = [' (' hdr_short.PixelUnits ')'];
    end
    file_info_string = [file_info_string 'Pixel size' pu ':  ' num2str(hdr_short.PixelSize) char(10)];
end
if isfield(hdr_short, 'R1')
    file_info_string = [file_info_string 'R1'  u ':  ' num2str(hdr_short.R1) char(10)];
end
if isfield(hdr_short, 'R2')
    file_info_string = [file_info_string 'R2'  u ':  ' num2str(hdr_short.R2) char(10)];
end


handles.hdr_short = hdr_short;
handles.static_text = file_info_string;
set(handles.info_text, 'String', file_info_string, 'visible', 'on');
set(handles.status_text, 'String', 'Loading preview image...');


%CREATE DATA HANDLE
handles.DATA = DATA3D([dir filename], hdr_short);
handles.rng = handles.DATA.data_range;

%Enable/Disable methods based on file contents
handles.update_text = [];
switch FileContents(1)
    case 'P'
        %Projection images
%        set(handles.flatfield_cbox, 'Enable', 'on', 'Value', 1)
%        set(handles.flatfield_cbox, 'Tag', 'Local');
 %       set(handles.action_menu, 'String', {'Export', 'Phase Retrieval','Reconstruction', 'Feature Tracking', 'Filters'});
%        set(handles.previewslice, 'String', num2str(ceil(hdr_short.ImageHeight/2)));
        handles.do_flatfield = 1;        
        handles.SINODATA = SINO_DATA3D(handles.DATA);
        handles.update_text = cell(3,1);
        if isfield(hdr_short, 'Angles')            
            handles.update_text{1} = {'Angle', hdr_short.Angles};            
        end
        if isfield(hdr_short, 'Shifts')            
            handles.update_text{2} = {'X shift', hdr_short.Shifts(:,1)};  
            handles.update_text{3} = {'Y shift', hdr_short.Shifts(:,2)};  
        end
        do_scalebar = 1;
    case 'R'
        %Reconstruction images
%        set(handles.flatfield_cbox, 'Enable', 'off', 'Value', 0);                    
%        set(handles.flatfield_cbox, 'Tag', '');
%        set(handles.action_menu, 'String', {'Export'}, 'Value', 1);
        %handles.DATA.apply_ff_default
        handles.do_flatfield = 0;    
        do_scalebar = 1;

    case 'S'
        %Sinogram stack
%        set(handles.flatfield_cbox, 'Enable', 'off', 'Value', 0);                    
%        set(handles.flatfield_cbox, 'Tag', '');
 %       set(handles.action_menu, 'String', {'Reconstruction'}, 'Value', 1);
        handles.do_flatfield = 0;  
        handles.SINODATA = SINO_DATA3D(handles.DATA);
        do_scalebar = 0;
end

%Loop over modules to enable/disable
enable_str = {[]};
q = 0;
modules = handles.addins();

for n = 1:numel(modules)    
    if strfind(modules{n}.target, upper(FileContents(1)))  
        q = q+1;
        enable_str{q} = modules{n}.name;    
    end 
    
    %Run load functions
    if isfield(modules{n}, 'load_function')
    if ~isempty(modules{n}.load_function)
        modules{n}.load_function(handles);
    end
    end
end
set(handles.action_menu, 'String', enable_str);
set(handles.action_menu, 'Value', 1);
feval(get(handles.action_menu, 'Callback'));


%READ 1st IMAGE
if handles.DATA.apply_ff_default==1
    handles.do_flatfield = 1;
    handles.DATA.apply_ff=1;
    set(handles.flatfield_cbox, 'Enable', 'on', 'Value', 1);
else
    handles.do_flatfield = 0;
    set(handles.flatfield_cbox, 'Enable', 'off', 'Value', 0);
end
img = handles.DATA(:,:,1);

%Set display range
if isempty(handles.rng)
    handles.rng = double([min(img(:)) max(img(:))]);
    if handles.rng(1)==handles.rng(2)
       img1 = handles.DATA(:,:,round(hdr_short.NoOfImages/2));
       handles.rng = double([min(img1(:)) max(img1(:))]);
    end
end


%DISPLAY 1st IMAGE
cdata = uint8(255*(img-handles.rng(1))/(handles.rng(2)-handles.rng(1)));
delete(handles.image);
handles.image = image(cdata, 'parent', handles.preview_axes, 'CDataMapping', 'direct');
axis image
handles.current_img = img;
set(handles.preview_axes, 'visible', 'off');


scroll_max = max([1.00001 double(hdr_short.NoOfImages)]);           
set(handles.preview_scroll, 'visible', 'on', 'min', 1, 'max', scroll_max, 'Value',1, 'SliderStep', [1 1]./scroll_max);
set(handles.next_button, 'visible', 'on');
set(handles.status_text, 'String', 'Loading file...Done');

%Display scale
set(handles.displayscale_min, 'String', num2str(handles.rng(1)), 'Enable', 'on');
set(handles.displayscale_max, 'String', num2str(handles.rng(2)), 'Enable', 'on');
set(handles.calc_histogram, 'Enable', 'on');


%Crop boxes
set(handles.croptop_box, 'String', '0', 'Enable', 'on');
set(handles.cropbottom_box, 'String', '0', 'Enable', 'on');
set(handles.cropleft_box, 'String', '0', 'Enable', 'on');
set(handles.cropright_box, 'String', '0', 'Enable', 'on');
set(handles.cropfirst_box, 'String', '1', 'Enable', 'on');
set(handles.croplast_box, 'String', num2str(hdr_short.NoOfImages), 'Enable', 'on');            


%Create croppatches            
%Set patches
xlim = get(handles.preview_axes, 'XLim');
ylim = get(handles.preview_axes, 'YLim');
if isempty(handles.croppatches{1})
    handles.croppatches{1} = patch([xlim(1) xlim(2) xlim(2) xlim(1)],[ylim(1) ylim(1) ylim(1) ylim(1)], handles.defaults.crop_col,'Parent',  handles.preview_axes);
    handles.croppatches{2} = patch([xlim(1) xlim(2) xlim(2) xlim(1)],[ylim(2) ylim(2) ylim(2) ylim(2)], handles.defaults.crop_col,'Parent',  handles.preview_axes);
    handles.croppatches{3} = patch([xlim(1) xlim(1) xlim(1) xlim(1)],[ylim(1) ylim(2) ylim(2) ylim(1)], handles.defaults.crop_col,'Parent',  handles.preview_axes);
    handles.croppatches{4} = patch([xlim(2) xlim(2) xlim(2) xlim(2)],[ylim(1) ylim(2) ylim(2) ylim(1)], handles.defaults.crop_col,'Parent',  handles.preview_axes);
    handles.croppatches{5} = patch([xlim(1) xlim(2) xlim(2) xlim(1)],[ylim(1) ylim(1) ylim(2) ylim(2)], handles.defaults.crop_col,'Parent',  handles.preview_axes);
    handles.croppatches{6} = patch([xlim(1) xlim(2) xlim(2) xlim(1)],[ylim(1) ylim(1) ylim(2) ylim(2)], handles.defaults.crop_col,'Parent',  handles.preview_axes);
else
    set(handles.croppatches{1}, 'XData', [xlim(1) xlim(2) xlim(2) xlim(1)] ,'YData',[ylim(1) ylim(1) ylim(1) ylim(1)]);
    set(handles.croppatches{2}, 'XData', [xlim(1) xlim(2) xlim(2) xlim(1)] ,'YData',[ylim(2) ylim(2) ylim(2) ylim(2)]);
    set(handles.croppatches{3}, 'XData', [xlim(1) xlim(1) xlim(1) xlim(1)] ,'YData',[ylim(1) ylim(2) ylim(2) ylim(1)]);
    set(handles.croppatches{4}, 'XData', [xlim(2) xlim(2) xlim(2) xlim(2)] ,'YData',[ylim(1) ylim(2) ylim(2) ylim(1)]);
    set(handles.croppatches{5}, 'XData', [xlim(1) xlim(2) xlim(2) xlim(1)] ,'YData',[ylim(1) ylim(1) ylim(2) ylim(2)]);
    set(handles.croppatches{6}, 'XData', [xlim(1) xlim(2) xlim(2) xlim(1)] ,'YData',[ylim(1) ylim(1) ylim(2) ylim(2)]);
end
for p = 1:6
    set(handles.croppatches{p}, 'EdgeColor', 'none', 'FaceColor', handles.defaults.crop_col, 'FaceAlpha', 0.1);
end
set(handles.croppatches{5}, 'Visible', 'off', 'FaceColor', handles.defaults.crop_col2);
set(handles.croppatches{6}, 'Visible', 'off', 'FaceColor', handles.defaults.crop_col2);


%Create scalbar
if ~isempty(handles.scalebar)
    delete(handles.scalebar{1});
    delete(handles.scalebar{2});
    handles.scalebar = [];
end
if do_scalebar
   x = double(hdr_short.PixelSize(1));
   sf = handles.defaults.scalebar.relsize;
   w = double(hdr_short.ImageWidth);
   if sf*w*x<10
       mf = 0.5;
   elseif sf*w*x<100
       mf = 0.1;
   else
       mf = 1;
   end
   
   sb_len = ((sf*w*x)/(mf*10^round(log10(sf*w*x))));
   if round(sb_len)==0
      sb_len = 0.5; 
   else
      sb_len = round(sb_len); 
   end
   sb_len = sb_len*(mf*10^round(log10(sf*w*x)))/x;
   
   
   pfp = get(handles.previewframe, 'position');
   mpix = double([hdr_short.ImageWidth, hdr_short.ImageHeight]);
   pr = handles.defaults.scalebar.offset*max(mpix)/pfp(3);
   
   switch handles.defaults.scalebar.position
       case 'SE'
            X = [pr pr+sb_len]; 
            Y = [mpix(2)-2*pr mpix(2)-2*pr]; 
       case 'SW'
            X = [mpix(1)-pr-sb_len mpix(1)-pr]; 
            Y = [mpix(2)-2*pr mpix(2)-2*pr]; 
       case 'NW'
            X = [mpix(1)-pr-sb_len mpix(1)-pr]; 
            Y = [2*pr 2*pr]; 
       case 'NE'
            X = [pr pr+sb_len]; 
            Y = [2*pr 2*pr];            
   end
    
   units = hdr_short.PixelUnits;
   switch units
       case 'microns'
           units = '\mum';
   end
   hold on;   
   handles.scalebar{1} = line(X,Y,'Color', handles.defaults.scalebar.colour, 'LineWidth',handles.defaults.scalebar.linewidth, 'Tag', 'TTscalebar');
   handles.scalebar{2} = text(mean(X),Y(1)+pr, sprintf('%s',[num2str(sb_len*x) ' ' units]), 'Color', handles.defaults.scalebar.colour,...
       'FontName', handles.defaults.scalebar.font, 'FontSize', handles.defaults.scalebar.fontsize, 'HorizontalAlignment', 'center', 'Tag', 'TTscalebar' ); 
else
    handles.scalebar = [];
end

%Enable pixel value display
handles.do_pointer_val = 1;

%Update text display
set(handles.preview_text, 'String','1');
set(handles.licence_txt, 'Visible', 'off');

set(handles.fig, 'Pointer', 'arrow');


%Enable ruler and snapshot buttons
set(handles.ruler_btn, 'Visible', 'on');
set(handles.snapshot_btn, 'Visible', 'on');
set(handles.zoomin_btn, 'Visible', 'on');
set(handles.zoomout_btn, 'Visible', 'on');
set(handles.pan_btn, 'Visible', 'on');

end



