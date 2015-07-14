function TTtest(plugin)

%Main function for generating the TomoTools GUI
% Written by: Robert S. Bradley (c) 2015
   

%% LOAD DEFAULTS FOR SIZING COMPONENTS =================================
handles.defaults = TomoTools_defaults;
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
scrsz = scrsz(1,:);
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
                    'NumberTitle','off', 'Tag', 'TomoTools', 'Name', ['TomoTools v' version], 'Visible', 'on', 'units', 'pixels',...
                    'WindowButtonMotionFcn', [], 'position', fpos, 'colormap', gray(256), 'Color', handles.defaults.fig_colour);
pos = get(handles.fig, 'position');

%Create panel for selecting modes
handles.action_panel = uipanel('Parent', handles.fig,'Units', 'normalized', 'Position', panel_pos, 'Title', 'Select action', 'visible', 'on','BackgroundColor', handles.defaults.panel_colour);
set(handle(handles.action_panel), 'BorderType', 'line',  'HighlightColor', handles.defaults.border_colour, 'BorderWidth', handles.defaults.border_width);
set(handles.action_panel, 'units', 'pixels');
panel_sz = get(handles.action_panel, 'position');
panel_sz(2) = panel_sz(2)+40;
panel_sz(4) = panel_sz(4)-40;
set(handles.action_panel, 'position', panel_sz);

handles.mod_hdl{1} = eval([plugin '(handles);']);
set(handles.mod_hdl{1}.panel, 'visible', 'on')

