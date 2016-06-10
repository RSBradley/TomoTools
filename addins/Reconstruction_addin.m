function mod_hdl = Reconstruction1_addin(handles)

% Panel addin for reconstruction with the ASTRA TOOLBOX
% Written by: Rob S. Bradley (c) 2015
%
%
% To do:
%1. add check to see if ASTRA toolbox is installed


%% LOAD DEFAULTS FOR SIZING COMPONENTS =================================
margin = handles.defaults.margin_sz;
button_sz = handles.defaults.button_sz;
edit_sz = handles.defaults.edit_sz;
info_sz = handles.defaults.info_sz;
axes_sz = handles.defaults.axes_sz;
status_sz = handles.defaults.status_sz;
central_pos = handles.defaults.central_pos;
panel_pos =  handles.defaults.panel_pos;
subpanel_pos = handles.defaults.subpanel_pos;
menu_sz_ratio = handles.defaults.menu_sz_ratio;


%recon algorithm names;algorithm syntax for ASTRA
algorithms = {'FBP/FDK', 'SIRT', 'CGLS'; 'BP3D_CUDA', 'SIRT3D_CUDA', 'CGLS3D_CUDA'};

%Load ring artefact reduction methods. method;default params
[~,RAmethods] = ring_artefact_reduction();
RAmethods = cat(1,{'none', {},[]},RAmethods);

%% PANEL NAME==========================================================
mod_hdl.name = 'Reconstruction';
mod_hdl.version = '1.0';
mod_hdl.target = 'PS';

mod_hdl.algorithms = {'FBP/FDK', 'SIRT', 'CGLS'; 'BP3D_CUDA', 'SIRT3D_CUDA', 'CGLS3D_CUDA'};


%check toolboxes exist
v = ver;
if isempty(find(strcmp({v.Name} , 'Parallel Computing Toolbox'), 1))
    do_parallel = 0;
    enable_parallel = 'off';
else
    do_parallel = 1;
    enable_parallel = 'on';
end




%% RECON Panel=========================================================
mod_hdl.panel = uipanel('Parent', handles.action_panel, 'Units', 'normalized', 'Position', subpanel_pos, 'Title', 'ASTRA toolbox reconstruction', 'visible', 'off');
set(handle(mod_hdl.panel), 'BorderType', 'line',  'HighlightColor', handles.defaults.border_colour, 'BorderWidth', handles.defaults.border_width, 'Units', 'pixels');  
subpanel_sz = get(mod_hdl.panel, 'Position');



%setup vertical tabs
TabNames = {'Algorithm', 'Geometry', 'Preprocessing', 'Output', 'User setting'};
TabSize = [125 50];
VTabs_opts.margin = 3*[1 1];
VTabs_opts.tabcolor = [0.96*handles.defaults.panel_colour;0.92*handles.defaults.panel_colour];
VTabs_opts.btncolor = 1.05*VTabs_opts.tabcolor;
VTabs_opts.highlightcolor = handles.defaults.fig_colour;

vpos = [5*margin subpanel_sz(4)-5*margin-(TabSize(2)+VTabs_opts.margin(2))*numel(TabNames)-VTabs_opts.margin(2) 0.75*subpanel_sz(3) (TabSize(2)+VTabs_opts.margin(2))*numel(TabNames)-0*VTabs_opts.margin(2)];
mod_hdl.VTabs = TTvtabs(mod_hdl.panel, vpos,...
                TabNames, TabSize,VTabs_opts);
% 
% vtab_pos_s = get(mod_hdl.VTabs.Tab1.Btn{2}, 'position');
% vtab_pos_e = get(mod_hdl.VTabs.(['Tab' num2str(numel(TabNames))]).Btn{2}, 'position');
% pos = get(mod_hdl.VTabs.Tab1.FullTab, 'position');
% pos(4) = vtab_pos_s(2)+TabSize(2)-vtab_pos_e(2);
% pos(2) = vtab_pos_e(2);

            
label_sz = [0 0 2*button_sz(1) edit_sz(2)];
control_sz =   [0 0 1.5*button_sz(1) edit_sz(2)];  

%GEOMETRY----------------------------------------------------
parentM = mod_hdl.VTabs.Tab2.MiniTab;
parentF = mod_hdl.VTabs.Tab2.FullTab;

mod_hdl.geometry = uicontrol('Style', 'popupmenu', 'Parent', parentM, 'String', {'parallel beam','cone beam'}, 'units', 'pixels',...
    'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1] ,'UserData', [1 1]);
simple_layout(parentM, 'LM-RM', margin*[2 1 1 1]);


mod_hdl.recon_PixelSize_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Pixel size (m):', 'units', 'pixels',...
                                'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor,'UserData', [1 1]);
mod_hdl.recon_PixelSize = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '1e-6', 'units', 'pixels',...
                                'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 1]);

mod_hdl.recon_R1_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'R1 (m):', 'units', 'pixels',...
                                'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 2]);
mod_hdl.recon_R1 = uicontrol('Style', 'edit', 'Parent', parentF, 'String', 'Inf', 'units', 'pixels',...
                            'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 2]);

mod_hdl.recon_R2_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'R2 (m):', 'units', 'pixels',...
                            'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 3]);
mod_hdl.recon_R2 = uicontrol('Style', 'edit', 'Parent', parentF, 'String', 'Inf', 'units', 'pixels',...
                            'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 3]);
                        
mod_hdl.recon_Angles_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Angles:', 'units', 'pixels', ...
                            'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 4]);
mod_hdl.recon_Angles = uicontrol('Style', 'edit', 'Parent', parentF, 'String', 'in file', 'units', 'pixels',...
                            'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 4]);

mod_hdl.recon_AnglesSkip_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Skip:', 'units', 'pixels',...
                            'position', label_sz.*[1 1 0.25 1], 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [3 4]);
mod_hdl.recon_AnglesSkip = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '1', 'units', 'pixels',...
                            'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [4 4]);

mod_hdl.recon_AnglesShift_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Shift:', 'units', 'pixels',...
                            'position', label_sz.*[1 1 0.25 1], 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [5 4]);
mod_hdl.recon_AnglesShift = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '0', 'units', 'pixels',...
                            'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [6 4]);


mod_hdl.recon_Shifts_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Alignment shifts:', 'units', 'pixels',...
                            'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 5]);
mod_hdl.recon_Shifts = uicontrol('Style', 'popupmenu', 'Parent', parentF, 'String', {'none', 'in file', 'load from add in..','load from variable..'}, 'units', 'pixels',...
                            'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'Callback', @load_reconshifts, 'Value', 2, 'UserData', [2 5]);
custom_AlignmentShifts = [];
ch = findobj('Parent', parentF, 'Style', 'text');
uitextsize(ch);

simple_layout(parentF, 'LT-RM', margin*[2 2 1 1]);

%ALGORITHM-----------------------------------
parentM = mod_hdl.VTabs.Tab1.MiniTab;
parentF = mod_hdl.VTabs.Tab1.FullTab;
mod_hdl.algorithm = uicontrol('Style', 'popupmenu', 'Parent', parentM, 'String', algorithms(1,:), 'units', 'pixels',...
                'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [1 1]);
simple_layout(parentM, 'LM-RM', margin*[2 1 1 1]);


mod_hdl.algiter_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'No. iterations:', 'units', 'pixels',...
                'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 1]); 
mod_hdl.algiter = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '7', 'units', 'pixels',...
                'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 1]);
mod_hdl.CPUmemory_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'CPU memory limit (GB):', 'units', 'pixels',...
                'position', label_sz.*[1 1 2 1], 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 2]); 
mod_hdl.CPUmemory = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '4', 'units', 'pixels',...
                'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 2]);
mod_hdl.GPUmemory_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'GPU memory limit (MB):', 'units', 'pixels',...
                'position', label_sz.*[1 1 2 1], 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 3]); 
mod_hdl.GPUmemory = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '200', 'units', 'pixels',...
                'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 3]);
mod_hdl.parallelcomp_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Use parallel computing:', 'units', 'pixels',...
                'position', label_sz.*[1 1 2 1], 'HorizontalAlignment', 'right','BackgroundColor',VTabs_opts.highlightcolor, 'UserData', [1 4]); 
mod_hdl.parallelcomp = uicontrol('Style', 'checkbox', 'Parent', parentF, 'String', '', 'units', 'pixels', 'value', do_parallel,'enable', enable_parallel,...
                'position', control_sz, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [2 4]);
ch = findobj('Parent', parentF, 'Style', 'text');
uitextsize(ch);
simple_layout(parentF, 'LT-RM', margin*[2 2 1 1]);


%PREPROCESSING---------------------------------------
parentM = mod_hdl.VTabs.Tab3.MiniTab;
parentF = mod_hdl.VTabs.Tab3.FullTab;
bgk = get(mod_hdl.VTabs.Tab3.MiniTab, 'BackgroundColor');
preproc_label = uicontrol('Style', 'text', 'Parent', parentM, 'String', 'Set preprocessing steps...', 'units', 'pixels', ...
                                        'position', label_sz, 'HorizontalAlignment', 'center', 'BackgroundColor', bgk, 'UserData', [1 1]); 


uitextsize(preproc_label);
simple_layout(parentM, 'LM-RM', margin*[2 1 1 1]);


%Ring artefact reduction
mod_hdl.ringartefact_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Ring artefact reduction:', 'units', 'pixels', ...
                                        'position', label_sz, 'HorizontalAlignment', 'center', 'BackgroundColor', VTabs_opts.highlightcolor, 'UserData', [1 1]); 
mod_hdl.ringartefact_method = uicontrol('Style', 'popup', 'Parent', parentF, 'String', RAmethods(:,1), 'units', 'pixels','HorizontalAlignment', 'left',...
                                    'BackgroundColor', [1 1 1], 'Position', control_sz, 'Value',1,'Callback', @RAmethodchange, 'UserData', [2 1]);
mod_hdl.ringartefact_params = uicontrol('Style', 'edit', 'Parent', parentF, 'String', cell2str(RAmethods{1,2}), 'units', 'pixels',...
                                    'BackgroundColor', [1 1 1], 'Position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [3 1]);


%Despeckle 
mod_hdl.despeckle_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Despeckle (n sigmas):', 'units', 'pixels', ...
            'position', label_sz, 'HorizontalAlignment', 'right', 'BackgroundColor', VTabs_opts.highlightcolor, 'UserData', [1 2]); 
mod_hdl.despeckle = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '10', 'units', 'pixels', 'BackgroundColor', [1 1 1],...
            'position', control_sz, 'HorizontalAlignment', 'left','UserData', [2 2]);


%Pad sinograms
mod_hdl.sino_pad_label = uicontrol('Style', 'text', 'Parent',parentF, 'String', 'Pad sinogram (width, value):', 'units', 'pixels', ...
                        'position', label_sz, 'HorizontalAlignment', 'right', 'BackgroundColor', VTabs_opts.highlightcolor, 'UserData', [1 3]); 
mod_hdl.sino_pad_w = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '50', 'units', 'pixels', 'BackgroundColor', [1 1 1], ...
                        'position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [2 3]);
mod_hdl.sino_pad_v = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '0', 'units', 'pixels', 'BackgroundColor', [1 1 1], ...
                        'position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [3 3]);


%Phase retrieval
mod_hdl.apply_PR_label = uicontrol('Style', 'text', 'Parent',parentF, 'String', 'Apply phase retrieval:', 'units', 'pixels', ...
                        'position', label_sz, 'HorizontalAlignment', 'right', 'BackgroundColor', VTabs_opts.highlightcolor, 'UserData', [1 4]);

mod_hdl.apply_PR = uicontrol('Style', 'checkbox', 'Parent',parentF, 'String', '', 'units', 'pixels', ...
                        'BackgroundColor', [1 1 1],'position', control_sz, 'HorizontalAlignment', 'left', 'UserData', [2 4], 'Value',0);
                    
ch = findobj('Parent', parentF, 'Style', 'text');
uitextsize(ch);
simple_layout(parentF, 'LT-RM', margin*[2 2 1 1]);
                    
%OUTPUT------------------------------------------------------
parentM = mod_hdl.VTabs.Tab4.MiniTab;
parentF = mod_hdl.VTabs.Tab4.FullTab;
mod_hdl.recon_dir = uicontrol('Style', 'edit', 'Parent', parentM, 'String', 'D:\test\', 'units', 'pixels', ...
                                        'position', [0 0 200 label_sz(4)], 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'UserData', [1 1]); 

simple_layout(parentM, 'LM-RM', margin*[2 1 1 1]);


%Recon slice dimensions
mod_hdl.recon_dims_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Recon slices dimensions:', 'units', 'pixels', ...
                'position', label_sz, 'BackgroundColor', VTabs_opts.highlightcolor,'HorizontalAlignment', 'right' ,'UserData', [1 1]); 

mod_hdl.recon_dims_w = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '', 'units', 'pixels', 'BackgroundColor', [1 1 1],...
                'position', control_sz, 'HorizontalAlignment', 'left','UserData', [2.1 1]);
mod_hdl.recon_dims_h = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '', 'units', 'pixels', 'BackgroundColor', [1 1 1], ...
                'position', control_sz, 'HorizontalAlignment', 'left','UserData', [2.2 1]);


%Apply recon mask
mod_hdl.applymask_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Apply mask:', 'units', 'pixels', 'value', 1,...
                            'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor', VTabs_opts.highlightcolor,'UserData', [1 2]); 
mod_hdl.applymask = uicontrol('Style', 'checkbox', 'Parent', parentF, 'String', '', 'units', 'pixels', 'value', 1,...
                            'position', control_sz,'HorizontalAlignment', 'left','BackgroundColor', [1 1 1],'UserData', [2 2]);
                        
%Sinogram directory
mod_hdl.sinogram_dir_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Sinogram directory:', 'units', 'pixels', 'value', 1,...
                            'position', label_sz, 'HorizontalAlignment', 'right','BackgroundColor', VTabs_opts.highlightcolor,'UserData', [1 3]); 
mod_hdl.sinogram_dir = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '', 'units', 'pixels', 'value', 1,...
                            'position', [0 0 200 label_sz(4)],'HorizontalAlignment', 'left','BackgroundColor', [1 1 1],'UserData', [2 3]);

ch = findobj('Parent', parentF, 'Style', 'text');
uitextsize(ch);

arrangement = {'LT', repmat({'RM', 'LM', 'LM', 'LM', 'LM'}, [5 1])};
simple_layout(parentF, arrangement, margin*[2 2 1 1]);


%USER_SETTINGS---------------------------------------------
parentM = mod_hdl.VTabs.Tab5.MiniTab;
parentF = mod_hdl.VTabs.Tab5.FullTab;
bgk = get(mod_hdl.VTabs.Tab5.MiniTab, 'BackgroundColor');
preproc_label = uicontrol('Style', 'text', 'Parent', parentM, 'String', 'Set centre-shift and beamhardening...', 'units', 'pixels', ...
                                        'position', label_sz, 'HorizontalAlignment', 'center', 'BackgroundColor', bgk, 'UserData', [1 1]); 

uitextsize(preproc_label);
simple_layout(parentM, 'LM-RM', margin*[2 1 1 1]);

%Centre shift
mod_hdl.cshiftrng_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Centre shift:', 'units', 'pixels',... 
                        'position', label_sz, 'HorizontalAlignment', 'right', 'BackgroundColor', VTabs_opts.highlightcolor, 'UserData', [1 1]); 

mod_hdl.cshiftrng_edit = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '-20:1:20', 'units', 'pixels', 'BackgroundColor', [1 1 1], ...
                        'position', control_sz, 'HorizontalAlignment', 'left','UserData', [2 1]); 


%Beam hardening correction
mod_hdl.beamhardening_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Beam hardening constant:', 'units', 'pixels', ...
                            'position', control_sz, 'HorizontalAlignment', 'right','BackgroundColor', VTabs_opts.highlightcolor, 'UserData', [1 2]); 

mod_hdl.beamhardening = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '0', 'units', 'pixels', 'BackgroundColor', [1 1 1], ...
                            'position', control_sz, 'HorizontalAlignment', 'left','UserData', [2 2]); 


ch = findobj('Parent', parentF, 'Style', 'text');
uitextsize(ch);
simple_layout(parentF, 'LT-RM', margin*[2 2 1 1]);                        


%PREVIEW-----------------------------------------------------------------
TabHeight = 100;
col = VTabs_opts.btncolor(rem(numel(TabNames)+1,2)+1,:); 
parentF = uipanel('Parent', mod_hdl.panel,'Units', 'pixels', 'Position', [vpos(1) vpos(2)-5*VTabs_opts.margin(2)-TabHeight vpos(3)+VTabs_opts.margin(1) TabHeight],...
                    'BorderType', 'none',  'BackgroundColor', col);

mod_hdl.previewslice_btn = uicontrol('Style', 'pushbutton', 'Parent', parentF, 'String', 'Preview', 'units', 'pixels', ...
                    'position', [0 0 1.5*button_sz(1) TabSize(2)-10], 'Callback', {@recon_preview,0},'UserData', [3 1]);
   
 
mod_hdl.previewslice_label = uicontrol('Style', 'text', 'Parent', parentF, 'String', 'Preview slice', 'units', 'pixels',...    
                'position', [0 0 TabSize(1)+VTabs_opts.margin(2)-margin*2 label_sz(4)], 'HorizontalAlignment', 'left', 'BackgroundColor', col,'UserData', [1 1]); 

mod_hdl.previewslice = uicontrol('Style', 'edit', 'Parent', parentF, 'String', '', 'units', 'pixels', 'BackgroundColor', [1 1 1], ...
                        'position', control_sz, 'HorizontalAlignment', 'left','UserData', [2 1]); 


mod_hdl.previewsino_btn = uicontrol('Style', 'pushbutton', 'Parent', parentF, 'String', 'View sinogram', 'units', 'pixels',...
                    'position', [0 0 1.5*button_sz(1) TabSize(2)-10], 'Callback', {@recon_preview,1}, 'Enable', 'on','UserData', [4 1]); 


ch = findobj('Parent', parentF, 'Style', 'text');
uitextsize(ch);
pos = get(mod_hdl.previewslice_label, 'Position');
pos(3) = TabSize(1)+VTabs_opts.margin(2)-margin*2;
set(mod_hdl.previewslice_label, 'Position', pos);
simple_layout(parentF, 'LM-LM', margin*[2 1 1 1]);

mod_hdl.recon_AlignmentShifts = [];
mod_hdl.prev_sinogram = [];




%% RUN FUNCTION ========================================================            
mod_hdl.run_function = @(h,q) reconstruct(h,mod_hdl,q);
mod_hdl.clear_previewdata = @clear_previewdata;
mod_hdl.load_function = @(h) file_load(h, mod_hdl);  % function to run on file load

%% NESTED RECON + SINO PREVIEW FUNCTIONs
    function clear_previewdata
        mod_hdl.prev_sinogram = [];
    end

    function recon_preview(~,~, only_s)
       
       %GET handle to sinogram DATA3D 
       SD = handles.getSINODATA();
       
       %Set parallel mode
        dp = get(mod_hdl.parallelcomp, 'Value');
        if dp
            SD.parallel_mode = 1;
        else
            SD.parallel_mode = 0;
        end
       
       
       %Get preview slice number 
       prev_slice = eval(get(mod_hdl.previewslice, 'String'));
       
       %Get geometry
       geom = get(mod_hdl.geometry, 'Value');
       
       %Get angles
       angs = get(mod_hdl.recon_Angles, 'String');
       if strcmpi(angs, 'in file')
           angs = SD.angles;
       else
           angs = eval(angs);    
           if numel(angs~=SD.dimensions(1)) %error checking
               errordlg('Number of custom angles does not equal the number of projection images')
               return
           end
       end
         
       
       %Get angs_skip
       angs_skip = eval(get(mod_hdl.recon_AnglesSkip, 'String'));
       
       
       
       %Get anglse shift
       angs_shift = eval(get(mod_hdl.recon_AnglesShift, 'String'));
       
       
       
       %Get shifts   - TO FIX!!!!
       shift_sel = get(mod_hdl.recon_Shifts, 'Value');
       shifts = SD.shifts;
       shifts_orig = shifts;
       switch shift_sel
           case 1
               SD.shifts = [];
               shifts = [];           
           case 3
               %SD.shifts = [];
               SD.shifts = custom_AlignmentShifts;   
               shifts = custom_AlignmentShifts; 
           case 4
               %SD.shifts = [];
               SD.shifts = custom_AlignmentShifts;   
               shifts = custom_AlignmentShifts; 
       end
       SD.apply_shifts = 1;
      
       rng_x_shifts = [];
       if ~isempty(shifts)
           rng_x_shifts = ceil(max(abs(shifts(:,1))));%[floor(min(shifts(:,1))) ceil(max(shifts(:,1)))];     
       end
       
       %Apply phase retrieval
       if get(mod_hdl.apply_PR, 'Value');           
          pr_fcn = feval(handles.get_shared_function('Phase_retrieval'));          
          if isempty(SD.prefilter_options)
            SD.prefilter_options = {@(im,x) pr_fcn(im),[]};
          else
            nsf = size(SD.prefilter_options,1);
            SD.prefilter_options(nsf,1:2) = {@(im,x) pr_fcn(im),{[]}};              
          end
       end
       
       
       %Check if sinogram can be reused
       if isempty(mod_hdl.prev_sinogram)
           %No exisiting sinogram
           do_sino = 1;          
       else
           %Existing sinogram
           %CHECK if current values match those of sinogram
           prev_vals = mod_hdl.prev_sinogram{1};
           t1 = prev_slice==prev_vals{2};
           %t2 = angs_skip==prev_vals{3}; Crop after!
           t2 = 1;
           try
               %Test if angles match
               t3 = min(angs==prev_vals{4})==1;
           catch
               t3 = false;
           end

           try
               %Test if shifts match
               t4 = min(min(shifts==prev_vals{5}))==1;
               if isempty(t4)
                   if isempty(shifts) & isempty(prev_vals{5})
                        t4 = true;
                   else
                        t4 = false;
                   end
               end
           catch
               t4 = false;
           end

           if t1 && t2 && t3 && t4
                do_sino = 0;                        
           else   
               do_sino = 1;

           end
       end
     
       
       %Load sinogram
       switch geom
           case 1
               % PARALLEL BEAM GEOMETRY
               
               %Check if sinogram can be reused
               if do_sino                    
                    
                    %s = handles.getcreate_sinogram_tiff(im_rd_fn, handles.rot90, ff,[1 handles.hdr_short.NoOfImages],prev_slice,angs_skip,angs,shifts, []);  
                    %UPDATE ROI      
                    SD.output_file_name = [];
                    SD.padding_options = [];
                    
                    mod_hdl.prev_sinogram = {{[1 SD.dimensions(1)], prev_slice, angs_skip, angs, shifts, [], [], []},SD(:,:,prev_slice)};                    
                    set(mod_hdl.previewsino_btn, 'Enable', 'on');
               end
               R12 = Inf*[1 1];
               options = [];
               pixel_size = eval(get(mod_hdl.recon_PixelSize, 'String'))*[1 1];
               do_permute = 1;
           case 2
               % CONE BEAM GEOMETRY
               %do_sino
               R12 = [str2num(get(mod_hdl.recon_R1, 'String')) str2num(get(mod_hdl.recon_R2, 'String'))];
               pixel_size = [1 1]*str2num(get(mod_hdl.recon_PixelSize, 'String'));
               
               %Extract check for row range
               row_range = conebeam_sinogram_rows(R12, pixel_size, [SD.dimensions(3) SD.dimensions(2)],prev_slice);
               if numel(row_range)==1;
                  row_range = [row_range-1:row_range+1];
               end
                    
               if ~do_sino & ~isequal(row_range, mod_hdl.prev_sinogram{1}{8})
                    do_sino = 1;
               end
               
               
               if do_sino
                    %row_range = conebeam_sinogram_rows(R12, pixel_size, handles.hdr_short.ImageHeight,prev_slice)                    
                    if numel(row_range)==1;
                        row_range = [row_range-1:row_range+1];
                    end
                    %UPDATE ROI
                    SD.ROI = SD.DATA3D_h.ROI;
                    
                    mod_hdl.prev_sinogram = {{[1 SD.dimensions(1)], prev_slice, angs_skip, angs, shifts, R12, pixel_size, row_range},SD(:,:,row_range)};
                    set(mod_hdl.previewsino_btn, 'Enable', 'on');
               end
               
               options.slices = mod_hdl.prev_sinogram{1}{8};
               options.detector_height = SD.dimensions(3);
               options.detector_shiftx = 0;
               options.detector_shifty = 0;
               
               pixel_size = eval(get(mod_hdl.recon_PixelSize, 'String'))*[1 1]; 
               do_permute = 1;
       end
       
       %Reset original shifts and angles
       SD.shifts = shifts_orig;       
       
       %Get sinogram
       s = double(mod_hdl.prev_sinogram{2}{1});       
       current_angs = double(mod_hdl.prev_sinogram{2}{2});
       
       %Crop sinogram only along dimension 1
%        if ~strcmpi(SD.DATA3D_h.contents, 'Sinograms')
%             pinds = SD.DATA3D_h.ROI(1,3):angs_skip:SD.DATA3D_h.ROI(3,3);  
%        else
%            pinds = SD.DATA3D_h.ROI(1,1):angs_skip:SD.DATA3D_h.ROI(3,1);
%        end
%        s = s(pinds,:,:);
%       current_angs = current_angs(pinds);  
       
       
       %Apply ring removal and despeckle
       raind = get(mod_hdl.ringartefact_method,'Value');
       ds = str2double(get(mod_hdl.despeckle, 'String'));
       size(s)
       if ~isempty(RAmethods{raind,3}) | ds>0

            %Apply before taking -ve log!
            s = exp(-s);
            
            %Despeckle            
            if ds>0
                s = remove_extreme_pixels1(s, [9 9], ds, 'local');
            end
            
            
            s = -log(s);
       end
       if ~isempty(RAmethods{raind,3})
           %ring artefact reduction
           try
                ra_params = str2cell(strtrim(get(mod_hdl.ringartefact_params, 'String')))              
                s = RAmethods{raind,3}(s,ra_params);                
           catch
               RAmethods{raind,3}
               s = RAmethods{raind,3}(s,ra_params);
                disp('Error: ring artefact reduction cannot be applied. Please check input parameters');
           end
       end

       %Apply beam hardening correction
       bh_param = str2num(get(mod_hdl.beamhardening, 'String'));
       bh_param = bh_param(1);
       s = (1-bh_param)*s+bh_param*s.^2; 

       %Pad sinogram
       pad_opts_w = str2num(get(mod_hdl.sino_pad_w, 'String'));
       minR = floor(size(s,2)/2)+1;
       if ~isempty(pad_opts_w) && pad_opts_w>0
          
           pad_opts_v = str2num(get(mod_hdl.sino_pad_v, 'String'));
           if isempty(pad_opts_v)
               pad_opts_v = 0;
           end
           
           if ~isempty(rng_x_shifts)
               
                s= padtovalue(s(:,rng_x_shifts+1:end-rng_x_shifts-1,:), [0 pad_opts_w],pad_opts_v);
              
           else
               s = padtovalue(s, [0 pad_opts_w],pad_opts_v);
           end
           
       elseif ~isempty(rng_x_shifts)
           %Remove interpolated edges of sinogram
           s = s(:,abs(rng_x_shifts(1))+1:end-rng_x_shifts(2)-1,:);
           
       end
       s(s==Inf)=0;
       
       if only_s
           imager(mod_hdl.prev_sinogram{2}{1},'name', 'original sinogram');
           imager(s,'name', 'processed sinogram');
           return
       end
       
       s = single(s);   
       if do_permute
           s = permute(s, [2 1 3]); %change to column, angle, row
       end
       
              
       %Reconstruct with centre shift
       cs = eval(get(mod_hdl.cshiftrng_edit, 'String')); 
       r_dims = eval(get(mod_hdl.recon_dims_w, 'String'));
       r_dims(2) = eval(get(mod_hdl.recon_dims_h, 'String')); 
       
       %Algorithm
       options.algorithm = algorithms{2,get(mod_hdl.algorithm, 'Value')};
       if get(mod_hdl.algorithm, 'Value')>1
            options.iterations = str2num(get(mod_hdl.algiter, 'String'));            
       end
       
       %Mask
       if get(mod_hdl.applymask, 'Value')
           [Y, X] = meshgrid(-r_dims(2)/2:r_dims(2)/2-1, -r_dims(1)/2:r_dims(1)/2-1);           
           options.mask = minR;
           %options.mask = (X.^2 + Y.^2 < minR^2);
           %imager(options.mask)
           %pause
       end
       %imager(s)
       %pause
       %s(:,1:80,:)=0;
       assignin('base', 's',s);
       assignin('base', 'current_angs',current_angs);
       
       %SORT OUT NEGATIVE!!
       [r, cs_iter] = central_slice_astra(s, -pi*(current_angs+angs_shift)/180, R12, pixel_size, [], cs, [], r_dims, options);
      
        %Show preview
       if cs_iter==1
            imager(r, 'name',['Centre_shift = ' num2str(cs(1))],'updatefcn', {@(x) set(gcf, 'Name', ['Centre_shift = ' num2str(cs(x))])});
       elseif cs_iter==2
           imager(r, 'name',['No. iterations = ' num2str(options.iterations(1))],'updatefcn', {@(x) set(gcf, 'Name', ['No. iterations = ' num2str(options.iterations(x))])});
       end
    end


    %Show sinogram
    function sino_preview(~,~)
       
        imager(mod_hdl.prev_sinogram{2}, 'name', 'sinogram');
        assignin('base', 's', mod_hdl.prev_sinogram{2});
        
    end


    function RAmethodchange(~,~)
        val = get(mod_hdl.ringartefact_method, 'Value');
        set(mod_hdl.ringartefact_params, 'String', cell2str(RAmethods{val,2}));       
        
    end


    function load_reconshifts(~,~)
        shifts = get(mod_hdl.recon_Shifts, 'Value');
        switch shifts
            case 3
                %'Get variables from apddata
                g = getappdata(gcf);
                f = fieldnames(g);
                inds = find(cellfun(@(x) ~isempty(x),strfind(f, 'shifts'), 'UniformOutput',1));                
                if ~isempty(inds)
                    [s,ok] = listdlg('PromptString','Select a variable:',...
                    'SelectionMode','single',...
                    'ListString',f(inds));
                    if ok
                        custom_AlignmentShifts = g.(f{inds(s)});
                    end
                end
                
                if isstruct(custom_AlignmentShifts)
                    if strcmpi(custom_AlignmentShifts.mode, 'add on')
                        SD = handles.getSINODATA();
                        shifts = SD.DATA3D_h.shifts;
                        tmpx = shifts(:,1)+spline(custom_AlignmentShifts.xshifts(:,1), custom_AlignmentShifts.xshifts(:,2), [1:size(shifts,1)]');
                        tmpy = shifts(:,2)+spline(custom_AlignmentShifts.yshifts(:,1), custom_AlignmentShifts.yshifts(:,2), [1:size(shifts,1)]');
                        custom_AlignmentShifts = [tmpx tmpy];
                    else
                        
                    end
                    
                end
                
                
            case 4
                %'Get variables from base'
                var = evalin('base', 'who');
                [s,ok] = listdlg('PromptString','Select a variable:',...
                'SelectionMode','single',...
                'ListString',var);
                if ok
                    custom_AlignmentShifts = evalin('base', var{s});
                end
        end
        setappdata(mod_hdl.panel, 'custom_AlignmentShifts', custom_AlignmentShifts);
    end

end

function file_load(handles,mod_hdl)
   
    %Convert distances to m
    switch handles.hdr_short.Units
       case 'm'
           dfactor = 1;
       case 'cm'
           dfactor = 1e-2;
       case 'mm'
           dfactor = 1e-3;
       case 'microns'
           dfactor = 1e-6;
    end
    switch handles.hdr_short.PixelUnits
       case 'm'
           pfactor = 1;
       case 'cm'
           pfactor = 1e-2;
       case 'mm'
           pfactor = 1e-3;
       case 'microns'
           pfactor = 1e-6;
       case 'nm'
           pfactor = 1e-9;
    end 
    
    %Update R1, R2, and Mean Energy
    if isfield(handles.hdr_short, 'R1');        
        set(mod_hdl.recon_R1, 'String', num2str(handles.hdr_short.R1*dfactor));
    else
        %Nominal value
        set(mod_hdl.recon_R1, 'String', 'Inf');
    end
     if isfield(handles.hdr_short, 'R2');        
        set(mod_hdl.recon_R2, 'String', num2str(handles.hdr_short.R2*dfactor));
     else
        %Nominal value
        set(mod_hdl.recon_R2, 'String', '0');
     end
 
     if isfield(handles.hdr_short, 'PixelSize');        
        set(mod_hdl.recon_PixelSize, 'String', num2str(handles.hdr_short.PixelSize*pfactor));
    else
        %Nominal value of 1 micron for microCT
        set(mod_hdl.recon_PixelSize, 'String', '1e-6');
     end
     dims = handles.DATA.dimensions;
     switch handles.DATA.contents(1)
         case 'S'
            set(mod_hdl.recon_dims_w, 'String', num2str(dims(2)));
            set(mod_hdl.recon_dims_h, 'String', num2str(dims(2)));
            set(mod_hdl.previewslice, 'String', num2str(round(dims(3)/2)));    
             
         case 'P'
            set(mod_hdl.recon_dims_w, 'String', num2str(dims(2)));
            set(mod_hdl.recon_dims_h, 'String', num2str(dims(2)));
            set(mod_hdl.previewslice, 'String', num2str(round(dims(1)/2)));    
     end
     
     %Output directories
     curr_dir = fileparts(handles.hdr.File);
     set(mod_hdl.sinogram_dir, 'String', [curr_dir '\sinograms']);
     set(mod_hdl.recon_dir, 'String', [curr_dir '\reconstruction']);
     
     mod_hdl.clear_previewdata();
    
end


%NEED TO PUT ALL handles things in DATA properties
function queued = reconstruct(handles,mod_hdl,queue)
%FUNCTION TO RECONSTRUCT DATA
recon_params.file = handles.DATA.file; 
recon_params.SD = handles.getSINODATA();

%%GEOMETRY===============================
if get(mod_hdl.geometry, 'Value')==1
    recon_params.geometry = 'parallel beam';
else
    recon_params.geometry = 'cone beam';
end
recon_params.pixel_size = eval(get(mod_hdl.recon_PixelSize, 'String'))*[1 1];
recon_params.R12 = [str2num(get(mod_hdl.recon_R1, 'String')) str2num(get(mod_hdl.recon_R2, 'String'))];

%Get angles
angs = get(mod_hdl.recon_Angles, 'String');
if strcmpi(angs, 'in file')
   recon_params.angles = recon_params.SD.angles;
else
   recon_params.angles = eval(angs);    
   if numel(recon_params.angles~=recon_params.SD.dimensions(1)) %error checking
       errordlg('Number of custom angles does not equal the number of projection images')
       return
   end
end

%SORT OUT NEGATIVE
recon_params.angles = -recon_params.angles;

%Get angs_skip
recon_params.angles_skip = eval(get(mod_hdl.recon_AnglesSkip, 'String'));

%Get angle shift
recon_params.angles_shift = eval(get(mod_hdl.recon_AnglesShift, 'String'));


%%PREPROCESSING======================
%Get shifts
shift_sel = get(mod_hdl.recon_Shifts, 'Value');
recon_params.shifts = recon_params.SD.shifts;
custom_AlignmentShifts = getappdata(mod_hdl.panel, 'custom_AlignmentShifts');

switch shift_sel
   case 1       
       recon_params.shifts = [];           
   case 3        
       recon_params.shifts = custom_AlignmentShifts; 
   case 4       
       recon_params.shifts = custom_AlignmentShifts; 
end
recon_params.SD.apply_shifts = 1; %%REMOVE!!!
if ~isempty(recon_params.shifts)
	recon_params.shifts_crop = ceil(max(abs(recon_params.shifts(:,1))));
else
    recon_params.shifts_crop =0;
end

recon_params.do_permute = 1;

%Specify ROI from cropping
recon_params.ROI = recon_params.SD.DATA3D_h.ROI;

%Despeckle filter
recon_params.despeckle = str2double(get(mod_hdl.despeckle, 'String'));

%Ring artefact reduction
recon_params.ring_artefact_method = [];
raind = get(mod_hdl.ringartefact_method,'Value');
[~, RAmethods] = ring_artefact_reduction();
RAmethods = cat(1,{'none', {},[]},RAmethods);
if ~isempty(RAmethods{raind,3})
    %ring artefact reduction
    ra_params = str2cell(strtrim(get(mod_hdl.ringartefact_params, 'String')));   
    recon_params.ring_artefact_method = RAmethods{raind,3}; 
    recon_params.ring_artefact_params = ra_params;
end


%Apply beam hardening correction
recon_params.beamhardening = str2num(get(mod_hdl.beamhardening, 'String'));
recon_params.beamhardening = recon_params.beamhardening(1);


%Pad sinogram
pad_opts_w = str2num(get(mod_hdl.sino_pad_w, 'String'));
pad_opts_v = str2num(get(mod_hdl.sino_pad_v, 'String'));
recon_params.pad_options = [pad_opts_w pad_opts_v];

%Apply phase retrieval
if get(mod_hdl.apply_PR, 'Value');       
    pr_fcn = feval(handles.get_shared_function('Phase_retrieval'));     
    if isempty(recon_params.SD.prefilter_options)
        recon_params.SD.prefilter_options = {@(im,x) pr_fcn(im),[]};
     else
         nsf = size(recon_params.SD.prefilter_options,1);
         recon_params.SD.prefilter_options(nsf,1:2) = {@(im,x) pr_fcn(im),{[]}};              
     end
end

%%ALGORITHM PARAMETERS======================================
recon_params.centre_shift = eval(get(mod_hdl.cshiftrng_edit, 'String')); 
recon_params.output_dims = eval(get(mod_hdl.recon_dims_w, 'String'));
recon_params.output_dims(2) = eval(get(mod_hdl.recon_dims_h, 'String')); 
recon_params.pixel_units = 'm';

%Algorithm
recon_params.options.algorithm = mod_hdl.algorithms{2,get(mod_hdl.algorithm, 'Value')};

%Optional recon parameter
if get(mod_hdl.algorithm, 'Value')>1
    recon_params.options.iterations = str2num(get(mod_hdl.algiter, 'String'));            
end


recon_params.options.applymask = double(get(mod_hdl.applymask, 'Value'))*(floor(recon_params.SD.dimensions(2)/2)+1-abs(recon_params.centre_shift));
recon_params.options.detector_height = recon_params.SD.dimensions(3);
recon_params.options.detector_shiftx = 0;
recon_params.options.detector_shifty = 0;


%Set reconstruction chunk size
glim = str2num(get(mod_hdl.GPUmemory, 'String'))*(1024^2);
srs = (prod(recon_params.SD.dimensions(1:2)+[0 2*pad_opts_w])+prod(recon_params.output_dims))*4;

recon_params.options.chunk_size = floor(glim/srs/2);
if recon_params.options.chunk_size<1
    recon_params.options.chunk = 1;
end

%Set parallel mode
dp = get(mod_hdl.parallelcomp, 'Value');
if dp
   nc = feature('numCores');
   recon_params.SD.parallel_mode = floor(recon_params.SD.dimensions(1)/nc);
   
   %Sinogram memory size
   ss = prod(recon_params.SD.dimensions+[0 2*pad_opts_w 0])*4;
   sslim = str2num(get(mod_hdl.CPUmemory, 'String'))*(1024^3);
   if ss>sslim
      %Need to do chunks       
      cslim = sslim/nc;
      recon_params.SD.parallel_mode = floor(recon_params.SD.dimensions(1)/ceil(ss/cslim));       
   end
   
else
   recon_params.SD.parallel_mode = 0;
end


%Create output folders==============
%curr_dir = fileparts(handles.hdr.File);
%sf = mkdir([curr_dir '\sinograms']);
if ~strcmpi(recon_params.SD.DATA3D_h.contents, 'Sinograms')
sf = get(mod_hdl.sinogram_dir, 'String');
recon_params.sinogram_dir = sf;
sf = mkdir(sf);
if ~sf
    errordlg(['Cannot create folder for sinograms. Check folder name is correct and that you have permissions']);
    return;
end
else
   recon_params.sinogram_dir = fileparts(recon_params.SD.DATA3D_h.file);
end
rf = get(mod_hdl.recon_dir, 'String');
recon_params.reconstruction_dir = rf;
rf = mkdir(rf);
if ~rf
    errordlg(['Cannot create folder for reconstruction. Check folder name is correct and that you have permissions']);
    return;
end


save([recon_params.reconstruction_dir '\recon_params.mat'],'recon_params')
assignin('base', 'recon_params', recon_params)



%RUN===================================
set(handles.fig, 'Pointer', 'watch'); 
pause(0.01)
if queue
    errordlg('This feature is not currently available')
    return;
    
    
else
    TTreconstruction(recon_params);
end


    
end

