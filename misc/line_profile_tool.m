function line_profile_tool(hparent)

%hparent must be axes
if nargin<1
    hparent = gca;
    img = [];
end    

if ~ishandle(hparent(1));
    img = hparent;
    imager(img);
    hparent = gca;
end
    
img_fig = get(hparent, 'Parent');
set(img_fig, 'units', 'pixels');
pos = get(img_fig, 'position');

%default width and height
def_height = 100;
def_width = 400;
control_fig = figure('MenuBar', 'none',...
                    'NumberTitle','off', 'Tag', 'line_profile_tool', 'Name', 'Line profile tool',...
                    'Units', 'pixels', 'Position', [pos(1) pos(2)-25-def_height def_width def_height]);



xstart_label = uicontrol ('Style', 'text', 'Parent', control_fig, 'Position', [10 70 50 20], 'string', 'x start:', 'HorizontalAlignment', 'Left');
xstart_box = uicontrol ('Style', 'edit', 'Parent', control_fig, 'Position', [60 72 50 20], 'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1]);

xend_label = uicontrol ('Style', 'text', 'Parent', control_fig, 'Position', [10 15 50 20], 'string', 'x end:', 'HorizontalAlignment', 'Left');
xend_box = uicontrol ('Style', 'edit', 'Parent', control_fig, 'Position', [60 17 50 20], 'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1]);


ystart_label = uicontrol ('Style', 'text', 'Parent', control_fig, 'Position', [130 70 50 20], 'string', 'y start:', 'HorizontalAlignment', 'Left');
ystart_box = uicontrol ('Style', 'edit', 'Parent', control_fig, 'Position', [180 72 50 20], 'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1]);

yend_label = uicontrol ('Style', 'text', 'Parent', control_fig, 'Position', [130 15 50 20], 'string', 'y end:', 'HorizontalAlignment', 'Left');
yend_box = uicontrol ('Style', 'edit', 'Parent', control_fig, 'Position', [180 17 50 20], 'HorizontalAlignment', 'Left', 'BackgroundColor', [1 1 1]);


thickness_label = uicontrol ('Style', 'text', 'Parent', control_fig, 'Position', [250 70 50 20], 'string', 'width:', 'HorizontalAlignment', 'Left');
v = uicontrol ('Style', 'edit', 'Parent', control_fig, 'Position', [310 72 50 20], 'HorizontalAlignment', 'Left', 'String', 1, 'BackgroundColor', [1 1 1]);

go_btn = uicontrol('Style', 'pushbutton', 'String', 'Plot profile', 'position', [290 17 80 40], 'Callback', @plot_profile); 


col = get(xstart_label, 'BackgroundColor');
set(control_fig, 'Color', col, 'CloseRequestFcn', @close_controlfig);
%Create patch
p = patch([0 0 0 0], [0 0 0 0], [0.8 0.8 0], 'FaceAlpha', 0.45, 'parent', hparent, 'EdgeColor', 'none');

%Create line
prof_fig = [];
hline = imline(hparent);
if isempty(hline)
    try close(control_fig);catch;end
    return;
end

id = addNewPositionCallback(hline,@(pos) disp_pos(pos));
disp_pos(getPosition(hline));

c = get(hline, 'Children');
set(xstart_box, 'Callback', @update_line);
set(xend_box, 'Callback', @update_line);
set(ystart_box, 'Callback', @update_line);
set(yend_box, 'Callback', @update_line);
set(v, 'Callback', @update_line);


    function close_controlfig(~,~)

       delete(hline);
       delete(control_fig);
       return;
        
    end

    function disp_pos(pos)
        pos = round(pos);
        %pause
        pos(pos<1)=1;        
        xstart = num2str(pos(1));
        xend = num2str(pos(2));
        ystart = num2str(pos(3));
        yend = num2str(pos(4));
        set(xstart_box, 'String',xstart);
        set(ystart_box, 'String', ystart);
        set(xend_box, 'String', xend);
        set(yend_box, 'String', yend);
        
        t = str2num(get(v, 'String'))-1;
        theta = pi()/2-atan2(-(pos(4)-pos(3)), pos(2)-pos(1));
        ct = cos(theta);
        st = sin(theta);
        
        x = [0 0 0 0];
        
        x(1) = pos(1)-(t/2)*ct;
        x(4) = pos(1)+(t/2)*ct;
        x(2) = pos(2)-(t/2)*ct;
        x(3) = pos(2)+(t/2)*ct;
        
        y = [0 0 0 0];
        y(1) = pos(3)-(t/2)*st;
        y(4) = pos(3)+(t/2)*st;
        y(2) = pos(4)-(t/2)*st;
        y(3) = pos(4)+(t/2)*st;
        
      
        %pause
        set(p, 'XData', x,'YData', y);
        
    end 

    function update_line(~,~,~)
       
        xs = str2num(get(xstart_box, 'String'));
        ys = str2num(get(ystart_box, 'String'));
        xe = str2num(get(xend_box, 'String'));
        ye = str2num(get(yend_box, 'String'));
        
        set(c(1), 'XData', xe);
        set(c(1), 'YData', ye);
        set(c(2), 'XData', xs);
        set(c(2), 'YData', ys);
        set(c(3), 'XData',[xs xe]);
        set(c(4), 'XData', [xs xe]);
        set(c(3), 'YData',[ys ye]);
        set(c(4), 'YData', [ys ye]);
        
        t = str2num(get(v, 'String'));
        theta = pi()/2-atan2(-(ye-ys), xe-xs);
        ct = cos(theta);
        st = sin(theta);
        %theta = atan2(-(ye-ys), xe-xs);
        
        x = [0 0 0 0];
        
        x(1) = xs-(t/2)*ct;
        x(4) = xs+(t/2)*ct;
        x(2) = xe-(t/2)*ct;
        x(3) = xe+(t/2)*ct;
        
        y = [0 0 0 0];
        y(1) = ys-(t/2)*st;
        y(4) = ys+(t/2)*st;
        y(2) = ye-(t/2)*st;
        y(3) = ye+(t/2)*st;
        
      
        %pause
        set(p, 'XData', x,'YData', y);
        
%         if isempty(prof_fig);
%             
%             try
%                 figure(prof_fig);
%                 
%             catch
%                
%             end
%         end
        
    end


    function plot_profile(hObject, eventdata, t)
        
        %Get image data
        %if isempty(img)
            h_img = findobj(hparent,'Type', 'image');
            img = get(h_img, 'cdata');
       % end
        
        %Check if greyscale image
        sz = size(img);
        if img(round(sz(1)/2), round(sz(1)/2),1)== mean(img(round(sz(1)/2), round(sz(1)/2),:))
           img = img(:,:,1); 
        end
        
        xstart = str2double(get(xstart_box, 'String'));
        xend = str2double(get(xend_box, 'String'));
        ystart = str2double(get(ystart_box, 'String'));
        yend = str2double(get(yend_box, 'String'));
        
        
        
        dist = sqrt((xend-xstart)^2+(yend-ystart)^2);
        
        n_steps = 4*upper(dist);
        %pause
        
        %Mid line
        x_rng = xstart:(xend-xstart)/n_steps:xend;
        y_rng = ystart:(yend-ystart)/n_steps:yend;
       
        if numel(x_rng)<2        
            x_rng = xstart*ones(numel(y_rng),1);
        end 
        if numel(y_rng)<2        
            y_rng = ystart*ones(numel(x_rng),1);
        end
        
        t = str2num(get(v, 'String'))-1;
        theta = atan2(-(yend-ystart), xend-xstart);
        ct = cos(theta);
        st = sin(theta);
        
        t_rng = -t/2:1:t/2;        
        xnet = zeros(numel(t_rng), numel(x_rng));
        ynet = zeros(numel(t_rng), numel(y_rng));
        
        for n = 1:size(xnet,1)           
            xnet(n,:) = x_rng+t_rng(n)*st;
            ynet(n,:) = y_rng+t_rng(n)*ct;           
        end
        
        
        %Sample data
        dist = cumsum(sqrt(diff(x_rng(:)').^2+diff(y_rng(:)').^2));
        dist = [0 dist];
        prof = zeros([size(dist,2) size(img,3)]);
        leg_str = cell(size(img,3),1);
        
        for q = 1:size(img,3)            
            prof_full = interp2(double(img(:,:,q)), xnet, ynet);        
            prof(:,q) = squeeze(mean(prof_full,1)); 
            leg_str{q} = num2str(q);
        end
        %pause
        if isempty(prof_fig);
            prof_fig = figure('Name', 'Line profiles');
        else 
            try
                figure(prof_fig);
            catch
               prof_fig = figure('Name', 'Line profiles');
            end
        end
        
        %Plot lines
        LPT.dist = dist';
        LPT.profile = prof';
        LPT.std = std(prof_full,1)';
        assignin('base', 'LPT', LPT);
        
        plot(dist,prof);
        hold on
        xlabel('distance (pixels)');
        ylabel('value');
        legend(leg_str, 'box', 'off', 'color', 'none', 'edgecolor', [1 1 1]);
        clear x_rng y_rng prof
        
    end    

end