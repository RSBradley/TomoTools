function mod_hdl = PhaseRetrieval_addin(handles)

% Panel addin for Phase Retrieval
% Written by: Rob S. Bradley (c) 2015


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

imageJPath = handles.defaults.imageJ_path;

%% PANEL NAME==========================================================
mod_hdl.name = 'Phase retrieval';
mod_hdl.version = '1.0';
mod_hdl.target = 'P';

%% PHASE RETRIEVAL Panel=================================================
mod_hdl.panel = uipanel('Parent', handles.action_panel, 'Units', 'normalized', 'Position', subpanel_pos, 'Title', 'Phase retrieval', 'visible', 'off');
set(handle(mod_hdl.panel), 'BorderType', 'line',  'HighlightColor', handles.defaults.border_colour, 'BorderWidth', handles.defaults.border_width, 'Units', 'pixels');  

subpanel_sz = get(mod_hdl.panel, 'Position');
pos = [margin subpanel_sz(4)-central_pos-button_sz(2)/2 3*button_sz(1) button_sz(2)];

%select algorithm
mod_hdl.pr_algorithm_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'Select algorithm:', 'units', 'pixels', 'Position', [pos(1) pos(2)-margin/3 edit_sz(1) pos(4)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.pr_algorithm = uicontrol('Style', 'popupmenu', 'Parent', mod_hdl.panel, 'String', 'Select algorithm:','BackgroundColor', [1 1 1],....
                  'Position', [pos(1)+12*margin pos(2) menu_sz_ratio(1)*button_sz(1) menu_sz_ratio(2)*button_sz(2)],....
                  'String', {'TIE-HOM';'PAD'}, 'Tag', 'Local');

              
%Output file type
vert_pos = pos(2)-4*margin; 
mod_hdl.output_ft_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'Ouput file type:', 'units', 'pixels', 'Position', [pos(1) vert_pos-margin/3 edit_sz(1) pos(4)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.output_ft = uicontrol('Style', 'popupmenu', 'Parent', mod_hdl.panel, 'BackgroundColor', [1 1 1],....
                  'Position', [pos(1)+12*margin vert_pos edit_sz(1) menu_sz_ratio(2)*button_sz(2)],....
                  'String', {'tiff'}, 'Tag', 'Local');              
              
              
%Enter db ratio             
vert_pos = vert_pos-4*margin;              
mod_hdl.pr_dbratio_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'delta/beta ratio:', 'units', 'pixels', 'Position', [pos(1) vert_pos-margin/3 edit_sz(1) edit_sz(2)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.pr_dbratio = uicontrol('Style', 'edit', 'Parent', mod_hdl.panel, 'BackgroundColor', [1 1 1],....
                  'Position', [pos(1)+12*margin vert_pos 1.5*button_sz(1) edit_sz(2)],'HorizontalAlignment', 'Left',....
                  'String', '500', 'Tag', 'Local');

%Enter keV
vert_pos = vert_pos-4*margin;              
mod_hdl.pr_energy_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'Energy (keV):', 'units', 'pixels', 'Position', [pos(1) vert_pos-margin/3 edit_sz(1) edit_sz(2)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.pr_energy = uicontrol('Style', 'edit', 'Parent', mod_hdl.panel, 'BackgroundColor', [1 1 1],....
                  'Position', [pos(1)+12*margin vert_pos 1.5*button_sz(1) edit_sz(2)],'HorizontalAlignment', 'Left',....
                  'String', '25', 'Tag', 'Local');
              
%Enter R1
col = get(mod_hdl.panel, 'BackgroundColor');
vert_pos = vert_pos-4*margin;              
mod_hdl.pr_R1_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'R1 (m):', 'units', 'pixels', 'Position', [pos(1) vert_pos-margin/3 edit_sz(1) edit_sz(2)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.pr_R1 = uicontrol('Style', 'edit', 'Parent', mod_hdl.panel, 'BackgroundColor', 1.02*col,....
                  'Position', [pos(1)+12*margin vert_pos 1.5*button_sz(1) edit_sz(2)],'HorizontalAlignment', 'Left',....
                  'String', '', 'Tag', 'Local');
              
%Enter R2
vert_pos = vert_pos-4*margin;              
mod_hdl.pr_R2_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'R2 (m):', 'units', 'pixels', 'Position', [pos(1) vert_pos-margin/3 edit_sz(1) edit_sz(2)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.pr_R2 = uicontrol('Style', 'edit', 'Parent', mod_hdl.panel, 'BackgroundColor',  1.02*col,....
                  'Position', [pos(1)+12*margin vert_pos 1.5*button_sz(1) edit_sz(2)],'HorizontalAlignment', 'Left',....
                  'String', '', 'Tag', 'Local');
              
%Enter pixel size
vert_pos = vert_pos-4*margin;              
mod_hdl.pr_pixsize_label = uicontrol('Style', 'text', 'Parent', mod_hdl.panel, 'String', 'Pixel size (m):', 'units', 'pixels', 'Position', [pos(1) vert_pos edit_sz(1) edit_sz(2)],...
                                        'HorizontalAlignment', 'Left');
mod_hdl.pr_pixsize = uicontrol('Style', 'edit', 'Parent', mod_hdl.panel, 'BackgroundColor',  1.02*col,....
                  'Position', [pos(1)+12*margin vert_pos 1.5*button_sz(1) edit_sz(2)],'HorizontalAlignment', 'Left',....
                  'String', '', 'Tag', 'Local');              
              

%Preview button
vert_pos = vert_pos-6*margin; 
mod_hdl.pr_previewbtn = uicontrol('Style', 'pushbutton', 'Parent', mod_hdl.panel, 'String', 'Preview', 'Position',[pos(1)+12*margin vert_pos 1.5*button_sz(1) button_sz(2)],...
                                    'Callback', @phase_retrieval_preview);
pos = get(mod_hdl.pr_previewbtn, 'Position');                                

%Preview options
mod_hdl.pr_previewopt = uibuttongroup('Units', 'pixels', 'Parent',mod_hdl.panel ,'Position',[pos(1) pos(2)-5*margin 1.5*pos(3) pos(4)], 'BorderType', 'none');
mod_hdl.pr_previewopt1 = uicontrol('Style', 'Radio', 'Parent', mod_hdl.pr_previewopt, 'String', 'Matlab', 'Units', 'normalized', 'Position', [0 0 1 1]);
mod_hdl.pr_previewopt2 = uicontrol('Style', 'Radio', 'Parent', mod_hdl.pr_previewopt, 'String', 'ImageJ', 'Units', 'normalized', 'Position', [0.55 0 1 1]);

%% RUN FUNCTION ========================================================            
mod_hdl.run_function = @(h,q) phase_retrieval(h, mod_hdl, q);     
mod_hdl.load_function = @(h) file_load(h, mod_hdl);  % function to run on file load
handles.add_shared_function('Phase_retrieval', @(~) get_algorithm(mod_hdl));

%% FUNCTION FOR PHASE RETRIEVAL PREVIEW

    function phase_retrieval_preview(~,~,~)
                
       %Convert inputs to values
       dbratio  = str2num(get(mod_hdl.pr_dbratio, 'String'))';
       energy  = str2num(get(mod_hdl.pr_energy, 'String'));
       R1  = str2num(get(mod_hdl.pr_R1, 'String'));
       R2  = str2num(get(mod_hdl.pr_R2, 'String'));
       pixsize  = str2num(get(mod_hdl.pr_pixsize, 'String'));

       dbratio(:,2)=1;

        %Get algorithm to use
        alg = get(mod_hdl.pr_algorithm, 'Value');
        switch alg
            case 1
                %TIE-HOM
                img_pr = tie_hom(handles.current_imgh(), energy, R1, R2,pixsize, dbratio, 1);

            case 2
                %PAD
                img_pr = pd_phaseretrieval(handles.current_imgh(), energy, R1, R2,pixsize, dbratio, 0.8,1);

        end       

        %Get program for preview
        preview_prog = get(get(mod_hdl.pr_previewopt, 'SelectedObject'), 'String');

        switch preview_prog
            case 'Matlab'

                line_profile_tool(img_pr);

            case 'ImageJ'

                %write out float tiffs
                tagstruct.ImageLength = size(img_pr,1);
                tagstruct.ImageWidth = size(img_pr,2);
                tagstruct.Photometric = 1;
                tagstruct.Compression = 1;
                tagstruct.Software = 'TomoTools:phase_retrieval';
                tagstruct.PlanarConfiguration = 1;

                tagstruct.BitsPerSample = 32;
                tagstruct.SampleFormat = 3;
                tagstruct.SamplesPerPixel = 1;        
                %tagstruct.Orientation = 5;
                sz = size(img_pr);
                if numel(sz)<3
                    sz(3) = 1;
                end

                outputdir = cd; %fileparts(handles.DATA.file_name);
                if strcmpi(outputdir(end), '\')                    
                    outputdir = outputdir(1:end-1);
                end   
                %Write out imageJ stack file
                outputfn_stack = [outputdir '\pr_stack.txt'];
                fidij = fopen(outputfn_stack, 'w');


                for k = 1:sz(3)

                    outputfn = [outputdir '\pr_' num2str(dbratio(k,1)) '.tiff'];                     

                    %Open tiff file for writing
                    tiff_file = Tiff(outputfn, 'w');
                    tiff_file.setTag('Orientation', tiff_file.Orientation.BottomRight);
                    tiff_file.setTag(tagstruct);

                    %tiff_file.getTag('Orientation')
                    %Write image
                    tiff_file.write(single(img_pr(:,:,k)));
                    tiff_file.close();

                    %Write to filename to stack file
                    outputfn = strrep(outputfn, '\', '\\');
                    %imageJ_str = [imageJ_str sprintf([outputfn '\n'])];

                    %fwrite(fidij, [outputfn char(10)]);
                    fprintf(fidij, [outputfn '\n']);
                end 


                fclose(fidij);

                %Open imageJ
                outputfn_stack = strrep(outputfn_stack, '\', '\\');
                load_str = ['run("Stack From List...", "open=[' outputfn_stack ']")'];

                %Write load string
                outputfn = [outputdir '\imageJ_loadstack.txt'];

                fid = fopen(outputfn, 'w');
                fwrite(fid, load_str);
                fclose(fid);

                status = 1;
                outputfn = strrep(outputfn, '\\', '\');

                for k = 1:numel(imageJPath)
                    %[imageJ_path{k} ' "' outputfn '"']
                    status = dos(['"' imageJPath{k} '" -macro "' outputfn '"']);
                    if ~status
                        break;                        
                    end
                end

                if status
                   warndlg('ImageJ could not be found on this computer');
                end    


        end  
    end

end

%% INTERNAL FUNCTIONS
function algorithm = get_algorithm(mod_hdl)
    dbratio  = str2num(get(mod_hdl.pr_dbratio, 'String'))';
    if numel(dbratio)>1        
        warndlg('Using first dbratio value');
        dbratio = dbratio(1);  
    end
    dbratio(:,2)=1;
    energy  = str2num(get(mod_hdl.pr_energy, 'String'));
    R1  = str2num(get(mod_hdl.pr_R1, 'String'));
    R2  = str2num(get(mod_hdl.pr_R2, 'String'));
    pixsize  = str2num(get(mod_hdl.pr_pixsize, 'String')); 
    
    
    %Get algorithm to use
    alg = get(mod_hdl.pr_algorithm, 'Value');

    switch alg
        case 1
            %TIE-HOM: [img_obj_plane img_thickness] = tie_hom(img_in, E, R1, R2,pix_size, RI, bg_val)
            algorithm = @(im) tie_hom(im,energy, R1, R2, pixsize,dbratio,1,0);            
        case 2
            %PAD
            %[img_obj_plane img_thickness] = pd_phaseretrieval(img_in, E, R1, R2, pix_size, RI, threshold, bg_val)
            algorithm = @(im) pd_phaseretrieval(im,energy, R1, R2, pixsize,dbratio,0.8,1,0);            
    end       


end



function queued = phase_retrieval(handles,mod_hdl,queue)
        
       
        %Get information
        output_ft_str = get(mod_hdl.output_ft, 'String');
        output_ft = get(mod_hdl.output_ft, 'Value');
        switch output_ft_str{output_ft}
            case 'overwrite'
                write_fn = 'overwrite';                
                outputfn = [];
                options.do_stack = 0;
                output_datatype = '';
            case 'tiff'
                write_fn = 'tiff';                
                options.do_stack = 1;
                output_datatype = 'float32';
                output_fn_start = fileparts(handles.DATA.file);
                
        end
        
        dbratio  = str2num(get(mod_hdl.pr_dbratio, 'String'))';
        if numel(dbratio)>1
            if options.do_stack
                %More than one value for dbratio
                button = questdlg('dbratio has more than one value, use all of first?','Phase retrieval', 'All', 'First', 'First');
            
                switch button
                    case 'First'
                        dbratio = dbratio(1);                
                end
            else
                warndlg('Using first dbratio value');
                dbratio = dbratio(1);    
            end
            
        end
        dbratio(:,2)=1;
        energy  = str2num(get(mod_hdl.pr_energy, 'String'));
        R1  = str2num(get(mod_hdl.pr_R1, 'String'));
        R2  = str2num(get(mod_hdl.pr_R2, 'String'));
        pixsize  = str2num(get(mod_hdl.pr_pixsize, 'String'));    
       
        %Get algorithm to use
        alg = get(mod_hdl.pr_algorithm, 'Value');
        
        switch alg
            case 1
                %TIE-HOM: [img_obj_plane img_thickness] = tie_hom(img_in, E, R1, R2,pix_size, RI, bg_val)
                algorithm = @(im,dbratio) tie_hom(im,energy, R1, R2, pixsize,dbratio,1);
                algorithm_str = ['@(im) ' func2mstring(@tie_hom,'#im', energy, R1, R2, pixsize,'#dbratio',1)];
            case 2
                %PAD
                %[img_obj_plane img_thickness] = pd_phaseretrieval(img_in, E, R1, R2, pix_size, RI, threshold, bg_val)
                algorithm = @(im,dbratio) pd_phaseretrieval(im,energy, R1, R2, pixsize,dbratio,0.8,1);
                algorithm_str = ['@(im) ' func2mstring(@pd_phaseretrieval,'#im', energy, R1, R2, pixsize,'#dbratio',0.8,1)];
        end       
        
        
        %Determine slice range
        Fcrop = round(str2num(get(handles.cropfirst_box, 'String')));
        LSTcrop = round(str2num(get(handles.croplast_box, 'String')));        
    
        ROI = handles.DATA.ROI;
        handles.DATA.ROI = [1 1 Fcrop; 1 1 1; handles.DATA.dimensions(1) handles.DATA.dimensions(2) LSTcrop];        
        DR = handles.DATA.data_range;
        
        if queue
            %Add job(s) to queue
            
            for q = 1:size(dbratio,1) 
                %options.filter_function = @(im) algorithm(im,dbratio(q,:));
                queued.function = mod_hdl.name;
                queued.version = mod_hdl.version;
                queued.filename = handles.DATA.file;
                queued.filetype = handles.filetype;
                queued.mstring = ['DATA.ROI = ' mat2str(handles.DATA.ROI) sprintf(';\n')];        
                queued.mstring = [queued.mstring 'DATA.data_range = ' mat2str(handles.DATA.data_range) sprintf(';\n')];

                %ADD options
                fno = fieldnames(options);
                for nf = 1:numel(fno)  
                    queued.mstring = [queued.mstring 'options.' fno{nf} ' = ' mat2str(options.(fno{nf})) sprintf(';\n')];
                end
                queued.mstring = [queued.mstring 'dbratio = '  mat2str(dbratio(q,:)) sprintf(';\n')];
                queued.mstring = [queued.mstring 'options.filter_function = '  algorithm_str sprintf('\n')];
               
                if options.do_stack
                    outputfn = [output_fn_start 'pr_' num2str(round(dbratio(q,1))) '_proj'];
                end
                queued.mstring = [queued.mstring func2mstring('DATA3D_export', '#DATA', write_fn, outputfn, output_datatype, '#options')];

                handles.add2queue(queued);
            end                           
                  
        else
            %Run export  
            for q = 1:size(dbratio,1) 
                if options.do_stack
                    outputfn = [output_fn_start 'pr_' num2str(round(dbratio(q,1))) '_proj'];
                end
                options.filter_function = @(im) algorithm(im,dbratio(q,:));
                DATA3D_export(handles.DATA, write_fn, outputfn, output_datatype, options);
            end
        end
        
        
        handles.DATA.ROI = ROI;
        handles.DATA.data_range = DR;
   
        
        
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
        set(mod_hdl.pr_R1, 'String', num2str(handles.hdr_short.R1*dfactor));
    else
        %Nominal value
        set(mod_hdl.pr_R1, 'String', 'Inf');
    end
     if isfield(handles.hdr_short, 'R2');        
        set(mod_hdl.pr_R2, 'String', num2str(handles.hdr_short.R2*dfactor));
     else
        %Nominal value
        set(mod_hdl.pr_R2, 'String', '0');
     end
     if isfield(handles.hdr_short, 'Energy');        
        set(mod_hdl.pr_energy, 'String', num2str(handles.hdr_short.Energy));
     elseif isfield(handles.hdr_short, 'Voltage');  
        %Mean energy ~1/3 of Voltage value. NB voltage is in kV
        set(mod_hdl.pr_energy, 'String', num2str(handles.hdr_short.Voltage/3));
     else
         %Nominal value
         set(mod_hdl.pr_energy, 'String', '25');
     end
     if isfield(handles.hdr_short, 'PixelSize');        
        set(mod_hdl.pr_pixsize, 'String', num2str(handles.hdr_short.PixelSize*pfactor));
    else
        %Nominal value of 1 micron for microCT
        set(mod_hdl.pr_pixsize, 'String', '1e-6');
     end
     if ~isempty(handles.DATA.write_fcn)
         set(mod_hdl.output_ft, 'String', {'overwrite', 'tiff'});
     else
         set(mod_hdl.output_ft, 'String', {'tiff'});
     end
    
end


