function [header header_short]= tiffstackheader_read(file, do_wait, show_fig)


if nargin<1
    [f p] = uigetfile({'*.tif; *.tiff', 'Tif files'});
    file = [p f];
end

if nargin<2
    do_wait = 1;
end

if nargin<3
    show_fig = 1;
end


%Split file
[pathstr, name, ext] = fileparts(file);

if isempty(ext)
    ext = 'tif';
end

%Find char in name
charinds = regexpi(name, '[a-z]');
if isempty(charinds)
    name_part = [];
else
    name_part = name(1:charinds(end));
end

%Load File names
tmp = dir([pathstr '\' name_part '*' ext]);
header.NoImages = max(size(tmp));

header.FileNames = cell(header.NoImages,1);
header.FileIdentifier = {[],[]};
for n = 1:header.NoImages
    header.FileNames{n} = [pathstr '\' tmp(n).name];
end


%Read header info for 1st image - assume same for all images
t = Tiff(header.FileNames{1}, 'r'); %CHANGED FROM TIFF1!!
i = imfinfo(header.FileNames{1});
header.Imfinfo = i;
header.TiffStruct = t;
header.ImageHeight = t.getTag('ImageLength');
header.ImageWidth = t.getTag('ImageWidth');
bps = t.getTag('BitsPerSample');
switch bps
    case 8
        header.DataType = 'uint8';
    case 16
        header.DataType = 'uint16';
    case 32
        header.DataType = 'single';
end   

%header.ReadFunction = 'Tiff'; 
header.StripOffsets = t.getTag('StripOffsets');
header.StripByteCounts = t.getTag('StripByteCounts');
header.PixelsPerStrip = 8*header.StripByteCounts./bps;


if show_fig
    vis = 'on';
else
    vis = 'off';
end

%Get extra information
set(0, 'units', 'pixels');
scrsz = get(0,'ScreenSize');

%Size of figure
mpos = 0.5*scrsz(3:4);
W = 300;
H = 500;
fpos = [mpos(1)-H/2 mpos(2)-W/2 W H];
handles.f = figure('MenuBar', 'none',...
           'NumberTitle','off', 'Tag', 'TiffStack', 'Name', 'TiffStack Info', 'Visible', 'on', 'units', 'pixels',...
            'WindowButtonDownFcn', [], 'position', fpos, 'colormap', gray(256),'CloseRequestFcn', @closefigfn, 'Visible', vis);

handles.Niml = uicontrol('Style', 'text', 'parent', handles.f, 'units', 'pixels', 'position', [30 H-30-10 100 20], 'String', 'Image range:');                
col = get(handles.Niml, 'BackgroundColor');
set(handles.f, 'Color', col);
handles.Nim = uicontrol('Style', 'edit', 'parent', handles.f, 'units', 'pixels', 'position', [300-100-50 H-30-5 50 20], 'String', ['1:1:' num2str(header.NoImages)], 'BackgroundColor', [1 1 1]);

handles.imtypel = uicontrol('Style', 'text', 'parent', handles.f, 'units', 'pixels', 'position', [30 H-65-10 100 20], 'String', 'Stack contents:');        
handles.imtype = uicontrol('Style', 'popupmenu', 'parent', handles.f, 'units', 'pixels', 'position', [300-100-50 H-65 100 15], 'String', {'radiographs' 'slices' 'sinograms'}, 'BackgroundColor', [1 1 1], 'Callback', @switch_imtype);
        
handles.pixelsizel = uicontrol('Style', 'text', 'parent', handles.f, 'units', 'pixels', 'position', [30 H-100-10 100 20], 'String', 'Pixel size (microns):');         
handles.pixelsize = uicontrol('Style', 'edit', 'parent', handles.f, 'units', 'pixels', 'position', [300-100-50 H-100-5 50 20], 'String', 1, 'BackgroundColor', [1 1 1], 'Callback', @update_dps);
 
%Radiograph panel
handles.radpanel = uipanel('Parent',handles.f,'Units','normalized','Position', [0.05 0.05 0.9 (H-190)/H], 'Title', 'Radiograph properties'); 
set(handles.radpanel, 'units', 'pixels');
pan_pos = get(handles.radpanel, 'position');

handles.geometryl = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [10 pan_pos(4)-55 100 20], 'String', 'Geometry:');         
handles.geometry = uicontrol('Style', 'popupmenu', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-100-50 pan_pos(4)-45 100 15], 'String', {'parallel beam' 'cone beam'}, 'BackgroundColor', [1 1 1], 'Callback', @switch_geometry);

handles.sourcedistancel = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [5 pan_pos(4)-55-50 140 20], 'String', 'Source distance (m):');         
handles.sourcedistance = uicontrol('Style', 'edit', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-100-30 pan_pos(4)-45-55 50 20], 'String', 'Inf', 'BackgroundColor', [1 1 1], 'Enable', 'off', 'Callback', @update_dps);

handles.detectordistancel = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [5 pan_pos(4)-55-100 140 20], 'String', 'Detector distance (m):');         
handles.detectordistance = uicontrol('Style', 'edit', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-100-30 pan_pos(4)-45-105 50 20], 'String', '0.5', 'BackgroundColor', [1 1 1], 'Enable', 'off', 'Callback', @update_dps);

handles.anglesl = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [5 pan_pos(4)-55-150 140 20], 'String', 'Angles (degrees):');       
angstep = 180/(header.NoImages-1);
angs_orig = ['0:' num2str(angstep) ':180'];
handles.angles = uicontrol('Style', 'edit', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-100-30 pan_pos(4)-45-155 100 20], 'String', ['0:' num2str(angstep) ':180'], 'BackgroundColor', [1 1 1]);


handles.dcalcpixelsize1 = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [5 pan_pos(4)-55-190 180 20], 'String', 'Dectector pixel size (microns):');       
handles.dcalcpixelsize = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-90 pan_pos(4)-55-190 50 20], 'String', '1');

handles.referencel = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [5 pan_pos(4)-55-225 150 20], 'String', 'Reference correction:');
handles.reference = uicontrol('Style', 'popupmenu', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-120 pan_pos(4)-55-220 100 20], 'String', {'Included';'Apply single ref';'Apply multi ref'}, 'BackgroundColor', [1 1 1], 'Callback', @update_ref);
reference_info.mode = [];
reference_multi_inds_w = [];
reference_multi_inds_b = [];

handles.filterl = uicontrol('Style', 'text', 'parent', handles.radpanel, 'units', 'pixels', 'position', [5 pan_pos(4)-55-260 150 20], 'String', 'Apply filter:');
handles.filter = uicontrol('Style', 'popupmenu', 'parent', handles.radpanel, 'units', 'pixels', 'position', [pan_pos(3)-120 pan_pos(4)-55-255 100 20], 'String', {'None';'Remove extreme pixels'}, 'BackgroundColor', [1 1 1], 'Callback', @update_filter);

header.Filter = {'none'};
header_short = [];


%Check if there is an xml file present
tmp = dir([pathstr '\*.xml']);
if ~isempty(tmp)
    extra_data = xml_read([pathstr '\' tmp(1).name]);
    
    %Remove fields that are calculated on the fly
    rmcell = {'NoOfImages', 'ImageHeight', 'ImageWidth', 'DataType'};
    for m = 1:numel(rmcell)
        if isfield(extra_data, rmcell{m});
            extra_data = rmfield(extra_data, rmcell{m});
        end
    end
   
    
    %Copy fields
    f = fieldnames(extra_data);
    for m = 1:numel(f)
        header.(f{m}) = extra_data.(f{m});
    end
        
    
    %Put in pixel size
    if isfield(extra_data, 'PixelSize')
       if ~isempty(extra_data.PixelSize)
            set(handles.pixelsize, 'String', num2str(extra_data.PixelSize));
       end        
    end      
    
    %Set StackContents
    if isfield(extra_data, 'StackContents')       
        switch extra_data.StackContents
            case 'Reconstructed slices'
                set(handles.imtype, 'Value', 2);
            case 'Sinograms'
                set(handles.imtype, 'Value', 3);
            case 'Radiographs'
                set(handles.imtype, 'Value', 1);
            case 'Projections'
                set(handles.imtype, 'Value', 1);
        end
        switch_imtype;
    end
   
    if isfield(extra_data, 'Geometry')
        switch extra_data.Geometry %Changed from Geometry.Type
            case 'parallel beam'
                set(handles.geometry, 'Value', 1);
            case 'cone beam'
                set(handles.geometry, 'Value', 2);
        end
        switch_geometry;
    end
    
end
    

if do_wait
    waitfor(handles.f);
else
    close(handles.f)
end


%Create short info
header.File = file;
header_short.File = header.FileNames;
header_short.FileContents = header.StackContents;
header_short.PixelSize = header.PixelSize;
header_short.PixelUnits = 'microns';
header_short.Units = 'microns';
header_short.ImageWidth = header.ImageWidth;
header_short.ImageHeight = header.ImageHeight;
header_short.NoOfImages = numel(header.UseInds);
header_short.DataType = header.DataType;
if isfield(header, 'DataRange')
       header_short.DataRange = header.DataRange;
else
    header_short.DataRange = [];
end
header_short.read_fcn = @(x, tmp) tiffstackimage_read(header,x, tmp{1}, tmp{2});
t.close();

    function switch_imtype(~,~)
       
        val = get(handles.imtype, 'Value');
        %get(handles.radpanel)
        if val==2           
            set(get(handles.radpanel, 'Children'), 'Enable', 'off');
        else
            set(get(handles.radpanel, 'Children'), 'Enable', 'on');
            switch_geometry;
            
        end
        
        
    end

    function switch_geometry(~,~)
       
         val = get(handles.geometry, 'Value');
        if val==1           
            set(handles.sourcedistance, 'Enable', 'off');
            set(handles.sourcedistance, 'String', 'Inf');
            %set(handles.detectordistance, 'Enable', 'off');
        else
            set(handles.sourcedistance, 'Enable', 'on');
            %set(handles.detectordistance, 'Enable', 'on');
        end
        update_dps
    end

    function update_dps(~,~)
        
        ps = get(handles.pixelsize, 'String');
        val = get(handles.geometry, 'Value');
        if val==1            
            set(handles.dcalcpixelsize, 'String', ps);
        else
            R1 = str2num(get(handles.sourcedistance, 'String'));
            R2 = str2num(get(handles.detectordistance, 'String'));
            M = 1+R2/R1;
            dps = str2num(ps)*M;
            set(handles.dcalcpixelsize, 'String',num2str(dps));
        end
        
    end

    %function update_nim(~,~)        
    %   header.Image = str2num(get(handles.nim, 'String'));
    %end
    
    function update_ref(~,~)
       
        val = get(handles.reference, 'Value');
        if val==2
            get_reference_info_single;
        elseif val==3
            get_reference_info_multi;
        end
    end

    function closefigfn(~,~)
       
        %Pixel Size
        header.PixelSize = str2num(get(handles.pixelsize, 'String'));
        header.ReferenceCorrection.mode = [];
        %File contents
        val = get(handles.imtype, 'Value');
        header.UseInds = eval((get(handles.Nim, 'String')));
        switch val
            case 1
                header.StackContents = 'Projections';                
                val = get(handles.geometry, 'Value');
                if val==1
                    header.Geometry.Type = 'parallel beam';
                else
                    header.Geometry.Type = 'cone beam';
                    
                end
                header.Geometry.R1 = str2num(get(handles.sourcedistance, 'String'));
                header.Geometry.R2 = str2num(get(handles.detectordistance, 'String'));
                header.Angles = eval(get(handles.angles, 'String'));
                header.ReferenceCorrection = reference_info;
                
                if strcmpi(reference_info.mode, 'multi');
                    %reference_info.white_ref
                    h = waitbar(0,'Loading references...');
                    if ~iscell(reference_info.white_ref.images)
                        tmp_inds = ones(header.NoImages,1);
                        tmp_inds(reference_info.white_ref.images) = 0;
                        header.UseInds = header.UseInds((tmp_inds(header.UseInds)>0));      
                        
                        %Assume files located sequentially should be
                        %grouped
                        jumps = find(diff(header.ReferenceCorrection.white_ref.images)>1);
                        if isempty(jumps) & reference_info.white_ref.mode~=1
                            reference_info.white_ref.mode = 1;
                        end
                            
                        
                        %Load white refs
                        wi = cell(numel(reference_info.white_ref.images),1);
                        waitbar(0,h,'Loading white references...');
                        for r = 1:numel(reference_info.white_ref.images) 
                            
                           wi{r} = imread(header.FileNames{reference_info.white_ref.images(r)});  
                           %header.Filter{1}
                           if ~strcmpi(header.Filter{1}, 'none');
                              wi{r} = header.Filter{2}(wi{r});  
                           end
                           waitbar(r/numel(reference_info.white_ref.images),h);
                        end
                        if reference_info.white_ref.mode==1
                            %average all
                            waitbar(0,h,'Averaging all white references...');
                            wr_net = zeros(size(wi{1}), 'single');
                            for rp = 1:numel(wi)
                                wr_net = wr_net+single(wi{rp});
                                waitbar(rp/numel(wi),h);
                            end
                            wr_net = wr_net./numel(wi);
                            header.ReferenceCorrection.white_ref.data = wr_net;
                        else
                            %average all consecutive files
                            waitbar(0,h,'Averaging consecutive white references...');
                            n_groups = numel(jumps)+1;
                            %pause
                            reference_info.white_ref.jumps = header.ReferenceCorrection.white_ref.images(sort([1 jumps jumps+1 numel(header.ReferenceCorrection.white_ref.images)]));
                            wg = cell(n_groups,1);
                            mid_inds = zeros(n_groups,1);
                            for ng = 1:n_groups  
                                ind_start = reference_info.white_ref.jumps((ng-1)*2+1);
                                ind_end = reference_info.white_ref.jumps((ng-1)*2+2);
                                wg{ng} = single(0);
                                mid_inds(ng) = round((ind_end+ind_start)/2);
                                for ngr = ind_start:ind_end 
                                   ngi = find(reference_info.white_ref.images==ngr,1);
                                   wg{ng} = wg{ng}+single(wi{ngi});                                    
                                end
                                wg{ng} = wg{ng}/(ind_end-ind_start+1);
                                waitbar(ng/n_groups,h);
                            end
                            %header.ReferenceCorrection.white_ref.data = wi;
                            header.ReferenceCorrection.white_ref.data = wg;
                            header.ReferenceCorrection.white_ref.images = mid_inds;
                        end
                            
                    else
                       %Read white refs from files
                       %Load white refs
                       waitbar(0,h,'Loading white references...');
                        wi = cell(numel(reference_info.white_ref.images),1);
                        for r = 1:numel(reference_info.white_ref.images)                            
                           wi{r} = imread(reference_info.white_ref.images{r});
                           if ~strcmpi(header.Filter{1}, 'none');
                               wi{r} = header.Filter{2}(wi{r});                              
                           end
                           waitbar(r/numel(reference_info.white_ref.images),h);
                           
                        end
                        
                        if reference_info.white_ref.mode==1
                            %average all
                            wr_net = zeros(size(wi{1}), 'single');
                            for rp = 1:numel(wi)
                                wr_net = wr_net+single(wi{rp});
                            end
                            wr_net = wr_net./numel(wi);
                            header.ReferenceCorrection.white_ref.data = wr_net;
                        else
                            header.ReferenceCorrection.white_ref.data = wi;
                        end
                        
                        
                    end
                    if ~iscell(reference_info.black_ref.images)
                        tmp_inds = ones(header.NoImages,1);
                        tmp_inds(reference_info.black_ref.images) = 0;
                        header.UseInds = header.UseInds((tmp_inds(header.UseInds)>0)); 
                        
                        %Load black refs
                        waitbar(0,h,'Loading black references...');
                        bi = cell(numel(reference_info.black_ref.images),1);
                        for r = 1:numel(reference_info.black_ref.images)                            
                           bi{r} = imread(header.FileNames{reference_info.black_ref.images(r)});
                           if ~strcmpi(header.Filter{1}, 'none');
                               bi{r} = header.Filter{2}(bi{r});                              
                           end
                           waitbar(r/numel(reference_info.black_ref.images),h);
                        end
                        if reference_info.black_ref.mode==1
                            %average all
                            waitbar(0,h,'Averaging all black references...');
                            br_net = zeros(size(bi{1}), 'single');
                            for rp = 1:numel(bi)
                                br_net = br_net+single(bi{rp});
                                waitbar(rp/numel(bi),h);
                            end
                            br_net = br_net./numel(bi);
                            header.ReferenceCorrection.black_ref.data = br_net;
                        else
                            header.ReferenceCorrection.black_ref.data = bi;
                        end
                        
                    else
                        %Read black refs from files
                       %Load black refs
                       waitbar(0,h,'Loading black references...');
                        bi = cell(numel(reference_info.black_ref.images),1);
                        for r = 1:numel(reference_info.black_ref.images)                            
                           bi{r} = imread(reference_info.black_ref.images{r}); 
                           if ~strcmpi(header.Filter{1}, 'none');
                               bi{r} = header.Filter{2}(bi{r});                              
                           end
                           waitbar(r/numel(reference_info.black_ref.images),h);
                        end
                        
                        if reference_info.black_ref.mode==1
                            %average all
                            br_net = zeros(size(bi{1}), 'single');
                            for rp = 1:numel(bi)
                                br_net = br_net+single(bi{rp});
                            end
                            br_net = br_net./numel(bi);
                            header.ReferenceCorrection.black_ref.data = br_net;
                        else
                            header.ReferenceCorrection.black_ref.data = bi;
                        end
                        
                        
                    end
                    close(h);
                end
                
                
            case 2
                header.StackContents = 'Reconstructed slices';
            case 3
                header.StackContents = 'Sinograms';
        end
        
        delete(handles.f);
    end
    

    function get_reference_info_single
        
        W = 300;
        H = 300;
        fpos = [mpos(1)-H/2 mpos(2)-W/2 W H];
        ref_fig = figure('MenuBar', 'none',...
           'NumberTitle','off', 'Tag', 'TiffStack', 'Name', 'TiffStack Info - reference correction', 'Visible', 'on', 'units', 'pixels',...
            'WindowButtonDownFcn', [], 'position', fpos, 'colormap', gray(256), 'CloseRequestFcn', @save_ref_info);
        set(ref_fig, 'Color', col);
        
        if strcmpi(reference_info.mode, 'single');
            white_fn =reference_info.white_ref;
            black_fn =reference_info.black_ref;
        else
            white_fn = [];
            black_fn = [];
        end
        black_ref_button = uicontrol('Style', 'pushbutton', 'parent', ref_fig,'units', 'pixels', 'position', [25 250 75 35], 'String', 'black ref', 'Callback', @getblackref);
        black_ref_filename = uicontrol('Style', 'edit', 'parent', ref_fig,'units', 'pixels', 'position', [25 200 220 25], 'String', black_fn, 'BackgroundColor', [1 1 1]);

        
        
        white_ref_button = uicontrol('Style', 'pushbutton', 'parent', ref_fig,'units', 'pixels', 'position', [25 100 75 35], 'String', 'white ref', 'Callback', @getwhiteref);
        white_ref_filename = uicontrol('Style', 'edit', 'parent', ref_fig,'units', 'pixels', 'position', [25 50 220 25], 'String', white_fn, 'BackgroundColor', [1 1 1]);
        
        function getblackref(~,~)
        
            [bfn bp] = uigetfile({'*.tif;*.tif', 'Tif files'},'Select black ref', pathstr); 
            if ~isempty(bfn)               
                set(black_ref_filename, 'String', [bp bfn]);                
            end
            
        end
        
        function getwhiteref(~,~)
        
            [bfn bp] = uigetfile({'*.tif;*.tif', 'Tif files'},'Select white ref', pathstr); 
            if ~isempty(bfn)               
                set(white_ref_filename, 'String', [bp bfn]);                
            end
            
        end
        
        function save_ref_info(~,~)
            reference_info.mode = 'single';
            reference_info.white_ref.images = get(white_ref_filename, 'String');
            reference_info.black_ref.images = get(black_ref_filename, 'String');
            delete(ref_fig);
        end
    end


    function get_reference_info_multi
        
        W = 675;
        H = 450;
        fpos = [mpos(1)-H/2 mpos(2)-W/2 W H];
        ref_fig = figure('MenuBar', 'none',...
           'NumberTitle','off', 'Tag', 'TiffStack', 'Name', 'TiffStack Info - reference correction', 'Visible', 'on', 'units', 'pixels',...
            'WindowButtonDownFcn', [], 'position', fpos, 'colormap', gray(256), 'CloseRequestFcn', @save_ref_info);
        set(ref_fig, 'Color', col);
        
        if strcmpi(reference_info.mode, 'multi');
            white_fn =reference_info.white_ref.images';
            black_fn =reference_info.black_ref.images';
        else
            white_fn = [];
            black_fn = [];
        end
        %black_ref_button = uicontrol('Style', 'pushbutton', 'parent', ref_fig,'units', 'pixels', 'position', [25 250 75 35], 'String', 'black ref', 'Callback', @getblackref);
        black_refl = uicontrol('Style', 'text', 'parent', ref_fig,'units', 'pixels', 'position', [15 400 150 35], 'String', 'Black reference');
        black_ref_button = uicontrol('Style', 'pushbutton', 'parent', ref_fig,'units', 'pixels', 'position', [35 375 75 35], 'String', 'browse', 'Callback', @getblackref);
        black_ref_table = uitable('parent', ref_fig,'units', 'pixels', 'position', [25 75 300 225],'ColumnName', {''}, 'ColumnFormat',{'char'},  'Data', black_fn, 'BackgroundColor', [1 1 1]);
        set(black_ref_table, 'ColumnWidth', {600});
        
        black_refindsl = uicontrol('Style', 'text', 'parent', ref_fig,'units', 'pixels', 'position', [15 325 150 35], 'String', 'Or select image indices');
        black_ref_inds = uicontrol('Style', 'edit', 'parent', ref_fig,'units', 'pixels', 'position', [25 310 125 25], 'String', [], 'BackgroundColor', [1 1 1], 'Callback', @update_br_inds);
        
        black_ref_model = uicontrol('Style', 'text', 'parent', ref_fig,'units', 'pixels', 'position', [15 25 75 25], 'String', 'Mode:');
        black_ref_mode = uicontrol('Style', 'popupmenu', 'parent', ref_fig,'units', 'pixels', 'position', [105 30 100 25], 'String', {'average all'}, 'BackgroundColor', [1 1 1]);
        
        %white_ref_button = uicontrol('Style', 'pushbutton', 'parent', ref_fig,'units', 'pixels', 'position', [25 100 75 35], 'String', 'white ref', 'Callback', @getwhiteref);
        %white_ref_filename = uicontrol('Style', 'edit', 'parent', ref_fig,'units', 'pixels', 'position', [25 50 220 25], 'String', white_fn, 'BackgroundColor', [1 1 1]);
        white_refl = uicontrol('Style', 'text', 'parent', ref_fig,'units', 'pixels', 'position', [360 400 150 35], 'String', 'White reference');
        white_ref_button = uicontrol('Style', 'pushbutton', 'parent', ref_fig,'units', 'pixels', 'position', [390 375 75 35], 'String', 'browse', 'Callback', @getwhiteref);
        white_ref_table = uitable('parent', ref_fig,'units', 'pixels', 'position', [360 75 300 225],'ColumnName', {''}, 'ColumnFormat',{'char'},  'Data', white_fn, 'BackgroundColor', [1 1 1]);
        set(white_ref_table, 'ColumnWidth', {600});
        
        white_refindsl = uicontrol('Style', 'text', 'parent', ref_fig,'units', 'pixels', 'position', [360 325 150 35], 'String', 'Or select image indices');
        white_ref_inds = uicontrol('Style', 'edit', 'parent', ref_fig,'units', 'pixels', 'position', [375 310 125 25], 'String', [], 'BackgroundColor', [1 1 1], 'Callback', @update_wr_inds);
        
        white_ref_model = uicontrol('Style', 'text', 'parent', ref_fig,'units', 'pixels', 'position', [360 25 75 25], 'String', 'Mode:');
        white_ref_mode = uicontrol('Style', 'popupmenu', 'parent', ref_fig,'units', 'pixels', 'position', [450 30 100 25], 'String', {'average all';'nearest';'interpolate'}, 'BackgroundColor', [1 1 1]);
        
        function getblackref(~,~)
        
            [bfn bp] = uigetfile({'*.tif;*.tif', 'Tif files'},'Select black ref', pathstr); 
            if ~isempty(bfn)               
                set(black_ref_filename, 'String', [bp bfn]);                
            end
            reference_multi_inds_b = [];
        end
        
        function getwhiteref(~,~)
        
            [bfn bp] = uigetfile({'*.tif;*.tif', 'Tif files'},'Select white ref', pathstr); 
            if ~isempty(bfn)               
                set(white_ref_filename, 'String', [bp bfn]);                
            end
            reference_multi_inds_w = [];
        end
        
        function save_ref_info(~,~)
            reference_info.mode = 'multi';
            nw = 0;
            nb = 0;
            if isempty(reference_multi_inds_b)            
                reference_info.black_ref.images = get(black_ref_table, 'Data');
            else
                reference_info.black_ref.images = reference_multi_inds_b;
                nb = numel(reference_info.black_ref.images);
            end
            if isempty(reference_multi_inds_w)            
                reference_info.white_ref.images = get(white_ref_table, 'Data');
            else
                reference_info.white_ref.images = reference_multi_inds_w;
                nw = numel(reference_info.white_ref.images);
            end
            reference_info.black_ref.mode = get(black_ref_mode, 'Value');
            reference_info.white_ref.mode = get(white_ref_mode, 'Value');
            if strcmpi(get(handles.angles, 'String'), angs_orig);
                
                nimgs = header.NoImages-nb-nw;
                ang_step = 180/(nimgs-1);
                set(handles.angles, 'String', ['0:' num2str(ang_step) ':180']);
                angs_orig = ['0:' num2str(ang_step) ':180'];
                
            end
            delete(ref_fig);
            
            
        end
        
        function update_wr_inds(~,~)
            inds_tmp = get(white_ref_inds, 'String');
            strcmpi(inds_tmp(1:4), 'snse')
            if strcmpi(inds_tmp(1:4), 'snse')
                inds_tmp = eval(inds_tmp(regexpi(inds_tmp, '[0-9 []]')));
                tmp1 = repmat([inds_tmp(1) inds_tmp(1)+inds_tmp(2)+inds_tmp(3)+1:inds_tmp(2)+inds_tmp(3):inds_tmp(4)], [inds_tmp(2) 1]);
                tmp2 = repmat([0:inds_tmp(2)-1]', [1 size(tmp1,2)]);
                tmp3 = tmp1+tmp2;
                inds = tmp3(:)';
                %set(white_ref_inds, 'String', num2str(inds));
            else
                inds = eval(get(white_ref_inds, 'String'));
            end
            data = header.FileNames(inds);
            set(white_ref_table, 'Data', data);
            reference_multi_inds_w = inds;
        end
        
        function update_br_inds(~,~)
            
            inds = eval(get(black_ref_inds, 'String'));
            data = header.FileNames(inds);
            set(black_ref_table, 'Data', data);
            reference_multi_inds_b = inds;
        end
        
    end


    function update_filter(~,~)
        
        val = get(handles.filter, 'Value');
        
        switch val
            case 1
                header.Filter = {'none'};
            case 2
                prompt = {'Enter filter size:', 'Enter # sigmas:', 'Mode (local/global):'};
                def = {'[11,11]', '6', 'local'};
                numlines=1;
                answer = inputdlg(prompt,'Remove extreme pixels filter options',numlines,def);
                header.Filter = {'Remove extreme pixels', @(x) remove_extreme_pixels1(x, eval(answer{1}), eval(answer{2}), answer{3})};
                
        end
        
    end

end