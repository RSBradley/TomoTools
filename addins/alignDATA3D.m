function [shifts, tformC, matching_inds]= alignDATA3D(DATA3D_fixed, DATA3D_moving, options,show_wb)

%Process inputs
if nargin<4
    %waitbar
    show_wb = 0;
end
if nargin<3
    %options
    options = [];
end
if isfield(options, 'mode')
    mode = options.mode;
else
    mode = 'monomodal';
end
if isfield(options, 'transform')
    transform = options.transform;
else
    transform = 'translation';
end
if isfield(options, 'InitialRadius')
    InitialRadius = options.InitialRadius;
else
    InitialRadius = 0.0005;
end 
if isfield(options, 'MaximumIterations')
    MaximumIterations = options.MaximumIterations;
else
    MaximumIterations = 200;
end 
if isfield(options, 'ImageStep')
    ImageStep = options.ImageStep;
else
    ImageStep = 1;
end 
if isfield(options, 'PyramidLevels')
    PyramidLevels = options.PyramidLevels;
else
    PyramidLevels = 5;
end 
if isfield(options, 'ManualCrop')
    mcrop = options.ManualCrop;
else
    mcrop = 0;
end
rect = [];
if isfield(options, 'filter_size')
    filt_sz = options.filter_size;
else
    filt_sz = [];
end
if isfield(options, 'normalize')
    do_norm = options.normalize;
else
    do_norm = 0;
end

%ensure the shifts are applied
DATA3D_fixed.apply_shifts = 1;
DATA3D_moving.apply_shifts = 1;

%registration metric and optimiser

[optimizer,metric] = imregconfig(mode);
if strcmpi(mode, 'multimodal')
    optimizer.InitialRadius = InitialRadius;
end
optimizer.MaximumIterations = MaximumIterations;

%choose cropping
maxshifts = ceil(max(cat(1,DATA3D_fixed.shifts,DATA3D_moving.shifts),[],1));


%run registration
shifts = zeros(DATA3D_fixed.dimensions(3),2);
tformC = cell(DATA3D_fixed.dimensions(3),1);
tform_init = [];
matching_inds = zeros(DATA3D_fixed.dimensions(3),1)+NaN;
fixed = [];
moving = [];
movingReg = [];
moving_tmp = [];
fixed_tmp = [];

ROI = DATA3D_moving.ROI;
ind1 = ROI(1,1):ROI(2,1):ROI(3,1);
ind2 = ROI(1,2):ROI(2,2):ROI(3,2);

f_inds = 1:ImageStep:DATA3D_fixed.dimensions(3); 
TotImages = numel(f_inds);

if mcrop
    %semi-automatic mode
    f = figure('NumberTitle', 'off');
    p = get(f, 'position');
    DX = 50;DY = 0;
    set(f, 'position', [p(1:2) max(p(3:4))*[1 1]+[DX DY]]);
    p = get(f, 'position');
    h = [];
    
    
    %Image step
    label_sz = [0 0 2*58 25];
	control_sz =   [0 0 1*58 25]; 
    btn_sz = [0 0 1.2*58 35];
%     ImageStep_label = uicontrol('Style', 'text', 'Parent',f, 'String', 'Image step:', 'units', 'pixels', 'enable', 'on');
%     set(ImageStep_label, 'position', label_sz, 'HorizontalAlignment', 'right', 'UserData', [1 3]); 
%     ImageStepC = uicontrol('Style', 'edit', 'Parent', f, 'String', '1', 'units', 'pixels', 'enable', 'on');
%     set(ImageStepC, 'position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [2 3], 'BackgroundColor', [1 1 1]); 

    %Pyramid levels
    PyramidLevels_label = uicontrol('Style', 'text', 'Parent', f, 'String', 'Pyramid levels:', 'units', 'pixels', 'enable', 'on');
    set(PyramidLevels_label, 'position', label_sz, 'HorizontalAlignment', 'right', 'UserData', [1 2]); 
    PyramidLevelsC = uicontrol('Style', 'edit', 'Parent', f, 'String', num2str(PyramidLevels), 'units', 'pixels', 'enable', 'on');
    set(PyramidLevelsC, 'position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [2 2], 'BackgroundColor', [1 1 1]);

    %Optimizer intitial radius
    MaximumIterations_label = uicontrol('Style', 'text', 'Parent', f, 'String', 'Maximum Iterations', 'units', 'pixels', 'enable', 'on');
    set(MaximumIterations_label, 'position', label_sz, 'HorizontalAlignment', 'right', 'UserData', [1 1]); 
    MaximumIterationsC = uicontrol('Style', 'edit', 'Parent', f, 'String', num2str(optimizer.MaximumIterations), 'units', 'pixels', 'enable', 'on');
    set(MaximumIterationsC, 'position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [2 1], 'BackgroundColor', [1 1 1]);

    %tranform type
    Transform_label = uicontrol('Style', 'text', 'Parent', f, 'String', 'Transform:', 'units', 'pixels', 'enable', 'on');
    set(Transform_label, 'position', label_sz, 'HorizontalAlignment', 'right', 'UserData', [3 2]); 
    TransformC = uicontrol('Style', 'popup', 'Parent', f, 'String', {'translation', 'rigid'}, 'units', 'pixels', 'enable', 'on');
    set(TransformC, 'position', control_sz+[0 0 58 0], 'HorizontalAlignment', 'left', 'UserData', [4 2], 'BackgroundColor', [1 1 1]);
    
    Spinner_label = uicontrol('Style', 'text', 'Parent', f, 'String', 'Matching image:', 'units', 'pixels', 'enable', 'on');
    set(Spinner_label, 'position', label_sz, 'HorizontalAlignment', 'right', 'UserData', [5 2]); 
    spinner_model = javax.swing.SpinnerNumberModel(1,1,DATA3D_moving.dimensions(3),1);
    jspinner = javax.swing.JSpinner(spinner_model);
    [Spinner hSpinner] = javacomponent(jspinner, [10,10,60,20], f);
    set(hSpinner, 'UserData', [6 2])
    set(Spinner, 'StateChangedCallback', @update_match);
    
    
    ControlPt_btn = uicontrol('Style', 'pushbutton', 'Parent', f, 'String', 'Prealign', 'units', 'pixels', 'enable', 'on', 'Callback', @control_point_align);
    set(ControlPt_btn, 'position', btn_sz, 'HorizontalAlignment', 'left', 'UserData', [3 1]); 
    
    Run_btn = uicontrol('Style', 'pushbutton', 'Parent', f, 'String', 'Run', 'units', 'pixels', 'enable', 'on', 'Callback', @run_align_m);
    set(Run_btn, 'position', btn_sz, 'HorizontalAlignment', 'left', 'UserData', [4 1]); 
    
    Back_btn = uicontrol('Style', 'pushbutton', 'Parent', f, 'String', 'Back', 'units', 'pixels', 'enable', 'on', 'Callback', {@next_img, -1});
    set(Back_btn, 'position', btn_sz, 'HorizontalAlignment', 'left', 'UserData', [5 1]); 
    Next_btn = uicontrol('Style', 'pushbutton', 'Parent', f, 'String', 'Next', 'units', 'pixels', 'enable', 'on', 'Callback', {@next_img,1});
    set(Next_btn, 'position', btn_sz, 'HorizontalAlignment', 'left', 'UserData', [6 1]); 

    ch = findobj('Parent', f, 'Style', 'text');
    uitextsize(ch);

    simple_layout(f, 'LB-RM', 10*[1 1 1 1]);
    
    
    IP = get(PyramidLevelsC, 'Position');
    
    DY = IP(2)+control_sz(4)+10;
    S = p(4)-DY;
    DX = (p(3)-S)/2;
    a = axes('parent', f, 'units', 'pixels', 'position', [DX DY S S]);    
    %View shifts
    set(f, 'Name', ['alignDATA3D:  Image 1/' num2str(TotImages) '  ' num2str(DATA3D_fixed.angles(1)) 'deg']);
    curr_ind = 1;
    show_img(f_inds(curr_ind));  
    hp = [get(a, 'Xlim') get(a, 'Ylim')];
    h = imrect(a, hp([1 3 2 4]));
    waitfor(f);
    return
else
    %Automatic mode
    if show_wb
        options.Title = 'alignDATA3D';
        options.InfoString = 'Aligning data sets...';
        w = TTwaitbar(0, options);
    end
    for n = f_inds
        [mval, matching_inds(n)] = min(abs(DATA3D_moving.angles-DATA3D_fixed.angles(n)));
    
        moving = DATA3D_moving(:,:,matching_inds(n));
        moving = moving(ind1,ind2);
        fixed = DATA3D_fixed(:,:,n);
        fixed = fixed(ind1,ind2);
        fixed_tmp = fixed;
        moving_tmp = moving;
        tmpR = imref2d(size(fixed_tmp));
        R = tmpR;
        if ~isempty(filt_sz)
            moving = medfilt2(moving, filt_sz*[1 1]);
            fixed = medfilt2(fixed, filt_sz*[1 1]);
        end
        %tform.T(3,1:2)
        tform = [];
        run_align;
        tformC{n} = tform;
        shifts(n,:) = tform.T(3,1:2);
    
        if show_wb
            TTwaitbar(n/DATA3D_fixed.dimensions(3),w);        
        end
    end
    return;
end


for n = 1:ImageStep:DATA3D_fixed.dimensions(3)    
    %Find matching angle
    
    [mval, matching_inds(n)] = min(abs(DATA3D_moving.angles-DATA3D_fixed.angles(n)));
    
    moving = DATA3D_moving(:,:,matching_inds(n));
    moving = moving(ind1,ind2);
    fixed = DATA3D_fixed(:,:,n);
    fixed = fixed(ind1,ind2);
    fixed_tmp = fixed;
    moving_tmp = moving;
    tmpR = imref2d(size(fixed_tmp));
    R = tmpR;
    if ~isempty(filt_sz)
        moving = medfilt2(moving, filt_sz*[1 1]);
        fixed = medfilt2(fixed, filt_sz*[1 1]);
    end
    
    if mcrop
        imager(fixed);
        if isempty(rect)           
           h = imrect(gca);           
        else
           h = imrect(gca, rect);           
        end
        set(gcf, 'CloseRequestFcn', {@getcrop, h});
        waitfor(gcf);
        
        
        fixed = fixed(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3));
        moving = moving(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3));
        
        %fixed(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3)) = fixed_tmp(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3)); 
        
        %moving(:) = 0;
        %moving(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3)) = moving_tmp(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3)); 
        
    end
    if do_norm
       moving = 1e4*moving/mean(moving(:)); 
       fixed = 1e4*fixed/mean(fixed(:));         
    else
       mval = max(max(moving(:),max(fixed(:))));
       moving = moving*1e4/mval;
       fixed = fixed*1e4/mval;
    end
    
    %tform = imregtform(moving(1+maxshifts(1):end-maxshifts(1),1+maxshifts(2):end-maxshifts(2)),fixed(1+maxshifts(1):end-maxshifts(1),1+maxshifts(2):end-maxshifts(2)),transform,optimizer,metric, 'DisplayOptimization', 0, 'PyramidLevels',PyramidLevels);
    if strcmpi(transform,'rigid')
        tform = imregtform(moving,fixed,'translation',optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',PyramidLevels);
        tform = imregtform(moving,fixed,'rigid',optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',1, 'InitialTransform', tform);
    else
        tform = imregtform(moving,fixed,transform,optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',PyramidLevels);
    end
   
    
    fixed = fixed_tmp;
    moving = moving_tmp;
    if mcrop
       tform = tform2D_cropadj(tform,rect(1),rect(2));        
    end
    
    movingReg =  imwarp(moving,imref2d(size(fixed)),tform, 'OutputView', imref2d(size(fixed)));
    assignin('base', 'tform', tform);
    tform.T
    imager(cat(3,fixed, movingReg));
    waitfor(gcf);
    %tform.T
    %pause
    %figure;imshowpair(fixed, moving,'Scaling','joint');
    tform.T(3,1:2)
    tformC{n} = tform;
    shifts(n,:) = tform.T(3,1:2);
    
    if show_wb
        TTwaitbar(n/DATA3D_fixed.dimensions(3),w);        
    end
    

end

shifts = shifts(1:ImageStep:DATA3D_fixed.dimensions(3),:);
matching_inds = matching_inds(1:ImageStep:DATA3D_fixed.dimensions(3));
tformC = tformC(1:ImageStep:DATA3D_fixed.dimensions(3),1);

if show_wb
    close(w);
end

    function getcrop(~,~,h)
       
        rect = round(h.getPosition);
        delete(gcf)
    end

    function run_align_m(~,~)        
        
        rect = round(h.getPosition);
        rect = [max(1,rect(2)), min(size(fixed,1), rect(2)+rect(4)), max(1,rect(1)), min(size(fixed,2),rect(1)+rect(3))];
        %fixed = fixed(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3));
        fixed = fixed(rect(1):rect(2),rect(3):rect(4));
        %moving = moving(rect(2):rect(2)+rect(4),rect(1):rect(1)+rect(3));
        moving = moving(rect(1):rect(2),rect(3):rect(4));
        PyramidLevels = str2num(get(PyramidLevelsC, 'String'));
        TransType = get(TransformC, 'Value');
        switch TransType
            case 1
                transform = 'translation';
            case 2
                transform = 'rigid';
        end
            
        optimizer.MaximumIterations = str2num(get(MaximumIterationsC, 'String'));
        run_align;
        tformC{curr_ind} = tform;
        shifts(curr_ind,:) = tform.T(3,1:2);
        imager(cat(3,fixed, movingReg), 'fig', f, 'axes',a);
    end

    function control_point_align(~,~)
        [fxpoints,mvpoints] = ...
                cpselect(fixed,moving,'Wait',true);
 
        tform_init = fitrigidtrans(mvpoints,fxpoints);
        tform_init.T(1,1) = 1;
        tform_init.T(2,2) = 1;
        tform_init.T(3,3) = 1;
        tform_init.T
    end


    function run_align       
        
        if do_norm
           moving = 1e4*moving/mean(moving(:)); 
           fixed = 1e4*fixed/mean(fixed(:));         
        else
           mval = max(max(moving(:),max(fixed(:))));
           moving = moving*1e4/mval;
           fixed = fixed*1e4/mval;
        end

    %tform = imregtform(moving(1+maxshifts(1):end-maxshifts(1),1+maxshifts(2):end-maxshifts(2)),fixed(1+maxshifts(1):end-maxshifts(1),1+maxshifts(2):end-maxshifts(2)),transform,optimizer,metric, 'DisplayOptimization', 0, 'PyramidLevels',PyramidLevels);
        
        if strcmpi(transform,'rigid')
            if isempty(tform_init)
                tform = imregtform(moving,fixed,'translation',optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',PyramidLevels);
                tform = imregtform(moving,fixed,'rigid',optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',1, 'InitialTransform', tform);
            else
                tform = imregtform(moving,fixed,'rigid',optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',PyramidLevels, 'InitialTransform', tform_init);
            end
        else
            tform = imregtform(moving,fixed,transform,optimizer,metric, 'DisplayOptimization', 1, 'PyramidLevels',PyramidLevels);
        end

    
        fixed = fixed_tmp;
        moving = moving_tmp;
        if mcrop
           tform = tform2D_cropadj(tform,rect(1),rect(2));        
        end

        movingReg =  imwarp(moving,imref2d(size(fixed)),tform, 'OutputView', imref2d(size(fixed)));
        tform.T

    end
        
        
    function next_img(~,~,mdir)
       
        
        curr_ind = curr_ind+mdir*1;
        curr_ind(curr_ind<1)=1;
        if curr_ind<=numel(f_inds)
            show_img(f_inds(curr_ind));
        else
            close(f);
        end
        tform_init = [];
        %set(f, 'Name', ['alignDATA3D:  Image 1/' num2str(TotImages) '  ' num2str(DATA_fixed.angles(1)) 'deg']);
        set(f, 'Name', ['alignDATA3D:  Image ' num2str(curr_ind) '/' num2str(TotImages) '  ' num2str(DATA3D_fixed.angles(f_inds(curr_ind))) 'deg']);
        
        
    end
        
    function update_match(~,~)
        n = f_inds(curr_ind);
        matching_inds(n) = get(Spinner, 'value');
        show_img(n)
    end


    function show_img(n)
        if isnan(matching_inds(n))
            [mval, matching_inds(n)] = min(abs(DATA3D_moving.angles-DATA3D_fixed.angles(n)));            
        end
        set(Spinner, 'value',matching_inds(n));
        moving = DATA3D_moving(:,:,matching_inds(n));
        moving = moving(ind1,ind2);
        fixed = DATA3D_fixed(:,:,n);
        fixed = fixed(ind1,ind2);
        fixed_tmp = fixed;
        moving_tmp = moving;
        tmpR = imref2d(size(fixed_tmp));
        R = tmpR;
        if ~isempty(filt_sz)
            moving = medfilt2(moving, filt_sz*[1 1]);
            fixed = medfilt2(fixed, filt_sz*[1 1]);
        end
        imager(cat(3,fixed, moving), 'fig', f, 'axes',a, 'statusbar',0, 'autoresize',0);        
        
    end





end

