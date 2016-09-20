function wb = TTwaitbar(x,whichbar, options)
%
%Waitbar for TomoTools, using TomoTools defaults
%
%   (c) 2015 Rob S Bradley

create_wb = 1;

%Load tomotools defaults
defs = TomoTools_defaults;
opts.Title = ['TTwaitbar ' defs.version];
opts.InfoString = 'Processing...';
opts.Size = [360 75];
opts.AxesHeight = 18;
opts.Font = defs.font;
opts.FontSize = 10;
opts.Split = 0.55;
opts.BorderWidth = 4;
opts.BusyWidth = 0.15;
opts.BusyPeriod = 0.02;

%Check if to update whichbar
do_update = 0;
do_busy = 0;
if nargin==3
    wb = whichbar;
    do_update = 1;
    create_wb = 0;
elseif nargin==2 && all(ishghandle(whichbar, 'figure'))
    wb = whichbar;
    opts = getappdata(wb, 'options');
    create_wb = 0;
    options = [];
elseif nargin==2
    options = whichbar;
    create_wb = 1;
end

if (nargin == 0)
    create_wb = 1;
    x = 0;
    options = [];
elseif (nargin == 1)    
    create_wb = 1;
    options = [];
end
if ~isempty(options)
    %Process options
    fn = fieldnames(opts);
    for nf = 1: numel(fn)
       if isfield(options, fn{nf}) 
          opts.(fn{nf}) = options.(fn{nf});
       end
    end    
end

if ~isnumeric(x) || ~isscalar(x)
    if ~strcmpi(x, 'Busy') & ~strcmpi(x, 'Busy1')
        error('First argument should be a scalar value between 0 and 1');
    end
    if  strcmpi(x, 'Busy')
        do_busy = 1; 
    else
        do_busy = 2;
    end
    x = opts.BusyWidth;
elseif ((x < 0) || (x > 1))
    if (x < 0)
        x = 0;
    elseif (x > 1)
        x = 1;
    end
end

%Create waitbar
if create_wb
    %Figure position
    u = get(0, 'units');
    set(0, 'units', 'pixels');
    mp = get(0, 'MonitorPositions');
    mp = mp(1,:);
    sz = get(0, 'ScreenSize');
    pos = [mp(3:4)/2-sz(1:2)-opts.Size(1:2)/2 opts.Size(1:2)];
    
    
    %Create figure
    wb = figure('Units', 'pixels', 'Position', pos, 'Name', opts.Title, 'Color', defs.panel_colour, 'NumberTitle', 'off',....
                'MenuBar', 'none', 'Resize', 'off', 'Tag', 'TTwaitbar','CloseRequestFcn', @closereqfcn);
    setappdata(wb, 'options', opts);
    up = uipanel('Parent', wb, 'Units', 'normalized', 'Position', [0 0 1 1], 'BackgroundColor', defs.panel_colour',...
                  'BorderType', 'line', 'BorderWidth', opts.BorderWidth, 'HighlightColor', defs.fig_colour);
    
    set(0, 'units', u);        
    opts.Size = opts.Size-2*opts.BorderWidth; 
    
    %Create info text
    pointsPerPixel = 72/get(0,'ScreenPixelsPerInch');
    ith = ceil((opts.FontSize+2)/pointsPerPixel);
    it_pos = [1 (opts.Split+(1-opts.Split)/2)*opts.Size(2)-ith/2 opts.Size(1) ith];            
    handles.info_text = uicontrol('Style', 'text', 'Parent', up, 'Units', 'pixels', 'Position', it_pos,'BackgroundColor', defs.panel_colour,...
                                'String', opts.InfoString, 'FontName', opts.Font, 'FontSize', opts.FontSize, 'Tag', 'TTwaitbar');        
    
    %Create axes
    ax_pos = [10 (opts.Split*opts.Size(2)-opts.AxesHeight)/2 opts.Size(1)-20 opts.AxesHeight];
    handles.axes = axes('Parent', up,'Units', 'pixels', 'Position', ax_pos, 'XLim',[0 100],...
            'YLim',[0 1],'Box','on','XTickMode','manual','YTickMode','manual',...
            'XTick',[],'YTick',[],'XTickLabelMode','manual','XTickLabel',[],...
            'YTickLabelMode','manual','YTickLabel',[],...
            'Color', defs.fig_colour, 'XColor', defs.border_colour, 'YColor', defs.border_colour,'ZColor', defs.border_colour,...
            'LineWidth', defs.border_width, 'Tag', 'TTwaitbar');
    axis fill;
    
    %Create patch
    handles.patch = patch([0.1 100*x 100*x 0.1], [0.005 0.005 0.98 0.98], [1 0 0], 'EdgeColor', 'none', 'Tag', 'TTwaitbar','Parent', handles.axes);
   
    drawnow;
    setappdata(wb, 'handles', handles);
    do_update = 0;
    
    TTimer = timer('TimerFcn', @(src,evt) busyfn, 'Period', opts.BusyPeriod, ...
                    'ExecutionMode', 'FixedRate', ...
                    'Tag', 'TTwaitbar', 'BusyMode', 'queue' );

    stop(TTimer);
    setappdata(wb, 'BusyTimer', {TTimer, {0,1}});

    p = fileparts(mfilename('fullpath'));
    je = javax.swing.JEditorPane('text/html', ['<html><img src="file:/' p '\TTbusy.gif"/></html>']);
    [hj, handles.busy] =  javacomponent(je,[],up);
    hj.setBackground(java.awt.Color(defs.panel_colour(1),defs.panel_colour(2),defs.panel_colour(3)))
    busy_pos = ax_pos+[-4 0 4 4];
    set(handles.busy, 'pos', busy_pos, 'visible', 'off')
    
    setappdata(wb, 'handles', handles);

end


%Update properties
handles = getappdata(wb, 'handles');
if do_update
    curr_opts = getappdata(wb, 'options');
    fn = fieldnames(curr_opts);
    for nf = 1:numel(fn);
       if ~isequal(curr_opts.(fn{nf}),opts.(fn{nf}))
          switch fn{nf}
              case 'Title'
                  set(wb, 'Name', opts.Title);
              case 'InfoString'
                  set(handles.info_text, 'String', opts.InfoString);
              case 'Size'
                  p = get(wb, 'Position');
                  p(3:4) = opts.Size;
                  set(wb, 'Position', p);
              case 'AxesHeight'
                  p = get(handles.axes, 'Position');
                  cp = p(2)+p(4)/2;
                  p(2) = cp-opts.AxesHeight/2;
                  p(4) = opts.AxesHeight;
                  set(handles.axes, 'Position', p);
              case 'Font'
                  set(handles.info_text, 'FontName', opts.Font);
              case 'FontSize'
                  set(handles.info_text, 'FontSize', opts.FontSize);
          end
       end
    end
end

if do_busy==2
    ttimer = getappdata(wb, 'BusyTimer');
    start(ttimer{1});
else
    ttimer = getappdata(wb, 'BusyTimer');
    stop(ttimer{1});
    
    if do_busy==1
        set(handles.axes, 'visible', 'off')
        set(handles.busy, 'visible', 'on')
    else    
        set(handles.busy, 'visible', 'off')
        set(handles.axes, 'visible', 'on')
        px = [0.01 100*x 100*x 0.01];
        set(handles.patch, 'XData', px);
    end
end
drawnow;

    function closereqfcn(~,~)
        ttimer = getappdata(wb, 'BusyTimer');
        stop(ttimer{1});
        delete(ttimer{1});
        delete(wb);        
    end


    function busyfn(~,~)
         
         for nt = 1:40
         nt
         frac = 1-(exp(-(((ttimer{2}{1}-50)/50).^4)./0.25));
         ttimer{2}{1} = ttimer{2}{1}+6*ttimer{2}{2}*(0.3*frac+(1-frac)*3);
         if ttimer{2}{1}>90
             ttimer{2}{2} = -1;
         end
         if ttimer{2}{1}<10
             ttimer{2}{2} = 1;
         end
         
         p = ttimer{2}{1}+0.5*100*opts.BusyWidth*[-1 1 1 -1];
         p(p<0.01)=0.01;
         p(p>99.9)=99.9;
         %frac = 1-(exp(-(((ttimer{2}{1}-50)/50).^4)./0.01));
         %c = [1 0 0]*frac+(1-frac)*[1 0.5 0.5];
         %set(handles.patch, 'XData', p, 'FaceColor',c);
         set(handles.patch, 'XData', p);
         drawnow;
         pause(0.02)
         im = getframe(handles.axes);
         %im(100) = struct('cdata',[],'colormap',[]);
         im = frame2im(im);
         imwrite(im, ['D:\HMtoolsV3\animations\a' num2str(nt) '.jpg']);        
         
         end
         %movie(im)
        pause
    end
end