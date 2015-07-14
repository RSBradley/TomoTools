classdef DATA3D < handle
    %3D data class for tomography data
    %Handles projections, sinograms and reconstructed slices
    %
    % Written by: Rob Bradley, (c) 2015
    %
    %
    %To do:
    %1. enable write function
    
    properties (SetObservable = true)        
        slice_nos %slice number(s) of current image  
        ROI %3D region of interest
        current_voxel %current voxel 
        data_range %data range for display and scaling
        hist_nbins %number of histogram bins
        store_imgs = 0; %flag to store slices in memory. 0 = no, 1 = discard and add, 2 = add.
        apply_ff = [];
        rotby90 = [];
        rotation = [];
        apply_rotation = [];
        shifts = [];
        apply_shifts = [];
        output_order = [];
        units = [];
        pixel_units =[];
        ROIread = [];
    end
    properties (SetAccess = private)
        file %file name
        read_fcn %function handle to read image data from 
        write_fcn %function handle to over write data
        hdr2xml_fcn %function handle to write header info to xml
        
        contents % type of file contents (e.g. Projections, Sinograms, or Reconstructed slices)
        data_type %e.g. uint8, float32
        dimensions  % data dimensions obtained from header_short
        
        pixel_size %pixel/voxel size
        
        apply_ff_default = [];
        rotby90_default = [];
        ROIread_default = [];
        
        %Optional properties
        angles = [] %for projections and sinograms
        R1 = [] %source to sample distance (P+S)
        R2 = [] %sample to detector distance (P+S)        
                
        private_imgs %place to store current image as necessary to avoid file reads
        private_slice_nos = {[], [],[],[]}; %slice_no of corresponding private image
    end
    properties (Dependent = true)
                
        current_imgs %current 2D slice
        current_voxel_value %current value of voxel
        hist %histogram
        reference_img %flat field correction
        
    end   
    
    methods
        
        
        function v = subsref(obj, S)
            %CLASS SUBSREF
            if numel(S)>1
                 v = builtin('subsref', obj, S);  % as per documentation                  
            else
              switch S.type
                  case '()'
                      %Calculate ROI from indexing
                      if numel(S.subs)<3
                         error('indexing must be of the form (x1:dx:x2, y1:dy:y2, z1:dz:z2)'); 
                      end                    
                      
                      roi_x = sub2roi(S.subs{1}, 1);
                      roi_y = sub2roi(S.subs{2}, 2);
                      roi_z = sub2roi(S.subs{3}, 3);
                      
                      ROIorig = obj.ROI;
                      SLICEorig = obj.slice_nos;
                      
                      %Temporarily set ROI
                      obj.ROI = [roi_x', roi_y', roi_z']; 
                      obj.slice_nos = roi_z(1):roi_z(2):roi_z(3);                      
                      
                      %Read data
                      v = obj.current_imgs;
                      
                      %Reset ROI
                      obj.ROI = ROIorig ; 
                      obj.slice_nos = SLICEorig;  
                  case '{}'
                      error('{} indexing not supported');
                  case '.'
                      v = builtin('subsref', obj, S);  % as per documentation
              end
            end
        
          
            %Nested function to convert indexing string to ROI
            function roi = sub2roi(sub_str, dim)
                  
                  if strcmpi(sub_str,':')
                    %All rows, colums, slices
                    switch dim
                        case 1
                            roi = [1 1 obj.dimensions(1)];
                        case 2
                            roi = [1 1 obj.dimensions(2)];
                        case 3
                            roi = [1 1 obj.dimensions(3)];
                    end
                  elseif isempty(sub_str)
                      %Keep existing ROI
                      roi = obj.ROI(:,dim)';
                  elseif numel(sub_str)==1
                    %Single row/col/slice
                    roi = (sub_str)*[1 1 1];
                    roi(2) = 1;
                  else
                    %Multiple rows, must be contiguous region
                    ds = unique(diff(sub_str));
                    if numel(ds)>1
                        error('indexing must refer to a contigous region of the form (x1:dx:x2, y1:dy:y2, z1:dz:z2)');                         
                    else
                        roi = [sub_str(1) ds sub_str(end)];                         
                    end
                  end
            end
        end
        
        function ind = end(obj,k,n)
            %IMPLEMENT END METHOD FOR SUBSREF
           szd = obj.dimensions;
           if k < n
              ind = szd(k);
           else
              ind = prod(szd(k:end));
           end
        end
        
        function disp(obj)
           do_disp(obj);            
        end
        
        
        function do_disp(obj)
            
           %Display basic fields
           st.file = obj.file;%file name
           req_names = {'read_fcn', 'write_fcn', 'contents', 'data_type', 'dimensions', 'pixel_size', 'ROI', 'data_range'...
                        'hist_nbins', 'store_imgs'};
           for nreq = 1:numel(req_names)               
              st.(req_names{nreq}) = obj.(req_names{nreq});                
           end
           
           
           %Optional properties
           opt_names = {'angles', 'R1', 'R2', 'apply_ff', 'rotby90', 'shifts', 'apply_shifts',...
                        'output_order', 'units', 'pixel_units'};           
           for nopt = 1:numel(opt_names)
              if ~isempty(obj.(opt_names{nopt}))                 
                  st.(opt_names{nopt})=obj.(opt_names{nopt});                  
              end             
           end
         
           builtin('disp', 'DATA3D object with the following fields:');
           builtin('disp', st);
            
            
        end
        
        
        function obj = DATA3D(file_name, header)
            %CONSTRUCTOR: copy information from header structure
            if isempty(header)
                return;
            end            
            
            obj.file = file_name; %Set file name in obj
            obj.read_fcn = header.read_fcn; %Set read function
            
            %Optional write function
            if isfield(header, 'write_fcn')
                obj.write_fcn = header.write_fcn; %Set write function                
            else
                obj.write_fcn = [];
            end
            
            %Optional write function
            if isfield(header, 'hdr2xml_fcn')
                obj.hdr2xml_fcn = header.hdr2xml_fcn; %Set write function                
            else
                obj.hdr2xml_fcn = [];
            end
            
            %Optional output order
            if isfield(header, 'OutputOrder')
                obj.output_order = header.OutputOrder; 
            end
            
            %Optional units
            if isfield(header, 'PixelUnits')
                obj.pixel_units = header.PixelUnits; 
            end
            if isfield(header, 'Units')
                obj.units = header.Units; 
            end
            
            %Set dimensions 
            obj.dimensions = double([header.ImageHeight,header.ImageWidth,header.NoOfImages]); 
            
            %Set contents and data type
            obj.contents = header.FileContents;
            obj.data_type = header.DataType;
       
            %Initialise # of histogram bins & data range
            switch obj.data_type
                case 'uint8'
                    obj.hist_nbins = 256;
                    obj.data_range = [0 255];
                case 'uint16'
                    obj.hist_nbins = 65535;
                    obj.data_range = [0 65535];
                    
                otherwise
                    obj.hist_nbins = 65535;
            end
            
            if isfield(header, 'DataRange')
                obj.data_range = double(header.DataRange);
            end
           
            
           switch lower(obj.contents(1))
               case 'p'
                   %Default data range for projections
                   %obj.data_range = [0 1.2]; %greater than 1 for phase contrast
                   obj.data_type = 'single'; %over ride data type for projection images
               case 's'
                   %Default data range for sinograms
                   obj.data_range = [-log(1.2) -log(0.01)]; %to 1% transmission 
                   obj.data_type = 'single'; %over ride data type for projection images
            end
            
            
            %Set optional properties
            if isfield(header, 'R1')
                obj.R1 = double(header.R1);
            end
            if isfield(header, 'R2')
                obj.R2 = double(header.R2);
            end
            if isfield(header, 'Angles')
                obj.angles = double(header.Angles);
            end
            if isfield(header, 'PixelSize')
                obj.pixel_size = double(header.PixelSize);
            end
            if isfield(header, 'Shifts')
               obj.shifts = double(header.Shifts); 
               obj.apply_shifts = 0;
            end
            if isfield(header, 'Rotation')
               obj.rotation = double(header.Rotation); 
               obj.apply_rotation = 0;
            end
            
            obj.apply_ff_default = 0;
            if isfield(header, 'ApplyRef')
                obj.apply_ff_default = header.ApplyRef;
                obj.apply_ff = header.ApplyRef;
                if obj.apply_ff_default
                    %Update data range - greater than 1 for phase contrast
                    obj.data_range = [0 1.2];
                end
            end
            obj.rotby90_default = 0;
            if isfield(header, 'RotBy90')
                obj.rotby90_default = header.RotBy90;
                obj.rotby90 = header.RotBy90;
            end
            
            obj.ROIread_default = 0;
            if isfield(header, 'ROIread')
                obj.ROIread_default = header.ROIread;
                obj.ROIread = header.ROIread;
            else
                obj.ROIread_default = 0;
                obj.ROIread = 0;
            end
                        
            %Set defaults
            obj.slice_nos = []; %initialise slice
            obj.current_voxel = [];
            obj.ROI = [1 1 1;1 1 1;obj.dimensions]; %initialise ROI        
            
        end
        
        function refimg = get.reference_img(obj)
        
            if obj.apply_ff_default ==0
                %Not flat field
                refimg = [];
            else
              
                %refimg = obj.read_fcn([], [0, 0]);
                obj.rotby90
                refimg = obj.read_fcn([], {obj.apply_ff, obj.rotby90});
            end
            if iscell(refimg)
                refimg = refimg{1};
            end
            
        end
        
        
        function cimg = get.current_imgs(obj)
            cimg = get_current_imgs(obj); %TRICK SO THAT get_current_imgs can be overloaded in subclasses             
        end
        
        
        
        function cimg = get_current_imgs(obj)
            %READ COMPLETE SLICE THEN CROP
            slices = obj.slice_nos;
            if ~isempty(obj.ROI)
                slices =  slices(slices>=obj.ROI(1,3) & slices<=obj.ROI(3,3));
            end
            
            if isempty(slices)
                cimg = [];
                return;
            end
            
            %READ with ROIread if possible
            if obj.ROIread && obj.ROIread_default                
            cimg = obj.read_fcn(obj.ROI([1 3],:), {obj.apply_ff, obj.rotby90}); 
            else
            %Initialise current image
            n_slices = numel(slices);
            
            do_rot = 1;
            if isempty(obj.rotby90_default)
                do_rot = 0;
            elseif obj.rotby90==0
               do_rot =  0;
            end
            
            if do_rot% | obj.rotby90==obj.rotby90_default
                cimg = zeros([obj.dimensions(1:2),n_slices], obj.data_type);
            else
                cimg = zeros([obj.dimensions([2 1]),n_slices], obj.data_type);
            end
            %Check if slice(s) are already stored in private imgs
            to_store = zeros(n_slices,1);
            %from_mem = zeros(n_slices,2);
            for n = 1:numel(slices)
                priv_ind = cellfun(@(x) find(x==slices(n)), obj.private_slice_nos, 'UniformOutput',0);
                priv_ind1 = find(~cellfun(@isempty,priv_ind), 1);
                if ~isempty(priv_ind1)
                    %slice exists in memory
                    %from_mem(n,1) = [priv_ind1 priv_ind{priv_ind1}(1)];
                    cimg(:,:,n) = obj.private_imgs{priv_ind1}(:,:,priv_ind{priv_ind1}(1));    
                    
                else
                    %read slice - could be improved to read chuck of
                    %slices?                    
                    %cimg(:,:,n) = obj.read_fcn(slices(n));
                    to_store(n) = 1;
                end                    
            end
            
            load_inds = find(to_store>0);
            if ~isempty(load_inds) 
                cimg(:,:,load_inds) = obj.read_fcn(slices(load_inds), {obj.apply_ff, obj.rotby90});
            end
            
            
            %store read slices if necessary - need to restrict for memory?
            switch obj.store_imgs
                case 1
                   %Disgard exisiting
                   obj.private_imgs = cell(1,1);
                   obj.private_imgs{1} = cimg;
                   obj.private_slice_nos = {obj.slice_nos};
                case 2
                   %Add
                   obj.private_imgs{numel(obj.private_imgs)+1} = cimg(:,:,to_store>0);
                   obj.private_slice_nos{numel(obj.private_imgs)} = obj.slice_nos(to_store>0);
            end           
            
            %Crop to ROI after reading - this could be including in the
            %read function in future   
            
            if ~isempty(obj.ROI)
               if do_rot
                    oROI = obj.ROI;
               else
                    oROI = obj.ROI(:,[2 1 3]);                
               end
               cimg = cimg(oROI(1,1):oROI(2,1):oROI(3,1),oROI(1,2):oROI(2,2):oROI(3,2),:);   
            end
            end
            
            %Apply rotation or shifts
            if obj.apply_rotation
                    T = obj.rotation(:,:,slices(n));
                    T(3,1) = obj.shifts(slices(n),1);
                    T(3,2) = obj.shifts(slices(n),2);
                    tf = affine2d(T);
                    cimg(:,:,n) = imwarp(cimg(:,:,n),imref2d(size(cimg(:,:,n))),tf, 'OutputView', imref2d(size(cimg(:,:,n))));  
            elseif obj.apply_shifts & ~isempty(obj.shifts)
               y_in = repmat([1:size(cimg,1)]', [1 size(cimg,2)]);
               x_in = repmat(1:size(cimg,2), [size(y_in,1) 1]);
               for n = 1:numel(slices)                   
                    y = y_in+obj.shifts(slices(n),2);
                    x = x_in-obj.shifts(slices(n),1);
                    cimg(:,:,n) = interp2(x_in, y_in, cimg(:,:,n), x, y, 'linear', 0);  
               end 
            end
            
            
            %Check if necessary to convert to 32 bit for projections only
            if strcmpi(obj.contents(1), 'p')
                cl = class(cimg);
                if strfind(cl, 'uint')
                    cimg = single(cimg)/single(eval([cl '(inf);']));                    
                end
            end
            
        end
        
        function val = get.apply_ff(obj)           
            if obj.apply_ff_default==0
                val = [];
            else
               val = obj.apply_ff; 
            end
            if val>1
                val = 1;
            end
            obj.apply_ff = val;
        end
        
        function val = get.rotby90(obj)           
            if obj.rotby90_default==0
                val = [];
            else
                val = obj.rotby90;
            end
            if val>1
                val = 1;
            end
            obj.rotby90 = val;
        end
        
        
        function chist = get.hist(obj)
            %CALCULATE HISTOGRAM
            
            %get current ROI data
            cimg = obj.current_imgs;
            
            %if data range is not set
            if isempty(obj.data_range)
                data_rng = [min(cimg(:)) max(cimg(:))];
                    
            else
                data_rng = obj.data_range;
            end
            dx = (data_rng(2)-data_rng(1))/obj.hist_nbins;
            xvalues = data_rng(1):dx:data_rng(2);
            chist = [xvalues',hist(cimg(:), xvalues)'];
            
        end
        
        
        function header = obj2struct(obj)
            %Convert obj back to header - reverse of constructor
            header.read_fcn = obj.read_fcn; %Set read function            
            header.write_fcn = obj.write_fcn;
            header.ImageHeight = obj.dimensions(1);
            header.ImageWidth = obj.dimensions(2);
            header.NoOfImages = obj.dimensions(3);
                        
            header.FileContents = obj.contents;
            header.DataType = obj.data_type;
       
            header.R1 = obj.R1;
            header.R2 = obj.R2;
            header.Angles = obj.angles;
            header.PixelSize = obj.pixel_size;
            header.Shifts = obj.shifts;
            header.DataRange = obj.data_range;

            
            
        end
    end
    
end

