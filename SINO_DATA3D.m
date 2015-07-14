classdef SINO_DATA3D < DATA3D
    % 3D data subclass for sinogram creation
    %  
    % Written by: Rob Bradley, (c) 2015
    
    properties (SetObservable = true) 
        
          padding_options = []; %PADDING AFTER SINOGRAM CREATION
          prefilter_options = [];
          output_file_name = [];
          show_waitbar = 1;
          parallel_mode = 0;
%         slice_nos %slice number(s) of current sinogram  
%         sino_ROI %3D region of interest
%        
%         sino_data_range = [0 2.3];
%         sino_hist_nbins = 655335;
%         sino_store_imgs = 0; %flag to store slices in memory. 0 = no, 1 = discard and add, 2 = add.
    end
    properties (SetAccess = private)
          DATA3D_h %handle to DATA3D object
%         sino_read_fcn  = @() (1); %Dummy function 
%         sino_contents = 'Sinogram' % type of file contents (e.g. Projections, Sinograms, or Reconstructed slices)
%         
%         sino_data_type  = 'single' %e.g. uint8, float32        
%         
%         sino_private_imgs %place to store current image as necessary to avoid file reads
%         sino_private_imgs_nos; %slice_no of corresponding private image
    end
%     

%    properties (Dependent = true)                
%         current_imgs %current 2D slice        
%         sino_hist %histogram
%     end   
    
    methods
        
        function obj = SINO_DATA3D(DATA3D_hdl)
            %CONSTRUCTOR: copy information from DATA3D object
            
            hdr = DATA3D_hdl.obj2struct;
            
            %Change dimensions to suit sinogram slicing
            if ~strcmpi(DATA3D_hdl.contents, 'Sinograms')          
                tmp = hdr.NoOfImages;
                hdr.NoOfImages = hdr.ImageHeight;
                hdr.ImageHeight = tmp;
            end
            
            hdr.FileContents = 'Sinograms';
            obj = obj@DATA3D([],hdr); %DUMMY CONSTRUCTOR
            obj.DATA3D_h = DATA3D_hdl;
        
            
            obj.slice_nos = DATA3D_hdl.ROI(1,1):DATA3D_hdl.ROI(2,1):DATA3D_hdl.ROI(3,1);
            obj.ROI = DATA3D_hdl.ROI(:,[3 2 1]);
            
            
        end
        
    end
    
    methods
        function do_disp(obj)
          builtin('disp', 'SINO_DATA3D object of class DATA3D with the following additional fields:')  
          
          st.DATA3D_h = obj.DATA3D_h;
          st.prefilter_options = obj.prefilter_options;
          st.output_file_name = obj.output_file_name;
          st.show_waitbar = obj.show_waitbar;
          
          builtin('disp', st);
            
        end
        function o = export(obj)            
            get_current_imgs(obj);  
            o = [];
        end        
        
        function cimg = get_current_imgs(obj)
            %SINOGRAM SLICES are ROWS in PROJECTION IMAGES
            
                     
            slices = obj.slice_nos;            
            if ~isempty(obj.ROI)
                slices =  slices(slices>=obj.ROI(1,3) & slices<=obj.ROI(3,3));
            end            
            
            if isempty(slices)
                cimg = [];
                return;
            end
            
            %Initialise current image
            n_slices = numel(slices);            
            proj_inds = obj.ROI(1,1):obj.ROI(2,1):obj.ROI(3,1);
            
            %Turn off ff correction and rotby90 during preview read and apply in
            %create_SINO function?
            apply_ff = obj.DATA3D_h.apply_ff;
            rotby90 = obj.DATA3D_h.rotby90;
            obj.DATA3D_h.rotby90 = 0;
            obj.DATA3D_h.apply_ff = obj.DATA3D_h.apply_ff_default;
            rotby90d = obj.DATA3D_h.rotby90_default;
            
            if nargout<1
                create_SINO_DATA3D(obj.DATA3D_h, [], rotby90d , slices, proj_inds,obj.output_file_name, obj.shifts,...
                        [], obj.prefilter_options, obj.show_waitbar,obj.parallel_mode);
                %Reset ff and rotby90
                obj.DATA3D_h.rotby90 = rotby90;
                obj.DATA3D_h.apply_ff = apply_ff;
                return
            end
        
            
            cimg{1} = zeros([numel(proj_inds) ,obj.dimensions(2), n_slices], obj.data_type);            
            cimg{2} = obj.angles(proj_inds);
            
            %Check if slice(s) are already stored in private imgs
            to_store = zeros(n_slices,1);
            for n = 1:numel(slices)
                %test for matching slices
                priv_ind = cellfun(@(x) find(x==slices(n)), obj.private_slice_nos(:,1), 'UniformOutput',0);
                
                %test for matching angles
                priv_ind2 = cellfun(@(x) isequal(x, proj_inds), obj.private_slice_nos(:,2));
                
                %test for matching shifts
                priv_ind3 = cellfun(@(x) isequal(x, obj.shifts), obj.private_slice_nos(:,3));

                %test for matching prefiltering options
                priv_ind4 = cellfun(@(x) isequal(x, obj.prefilter_options), obj.private_slice_nos(:,4));
                
                priv_ind1 = find(~cellfun(@isempty,priv_ind) & priv_ind2 & priv_ind3 & priv_ind4, 1);
                if ~isempty(priv_ind1)
                    %slice exists in memory
                    %priv_ind1
                    %priv_ind{priv_ind1}(1)
                    cimg{1}(:,:,n) = obj.private_imgs{priv_ind1}(:,:,priv_ind{priv_ind1}(1));    
                    
                else
                    %log slices to read                    
                    to_store(n) = 1;
                end                    
            end
            
            %Read remaining slices
            inds = find(to_store);
            
            cimg{1}(:,:,inds) = create_SINO_DATA3D(obj.DATA3D_h, [], rotby90d , slices(inds), proj_inds,obj.output_file_name, obj.shifts,...
                        [], obj.prefilter_options, obj.show_waitbar,obj.parallel_mode);
                 
            
            %Reset ff and rotby90
            obj.DATA3D_h.rotby90 = rotby90;
            obj.DATA3D_h.apply_ff = apply_ff;
            
            %store read slices if necessary - need to restrict for memory?
            switch obj.store_imgs
                case 1
                   %Disgard exisiting
                   obj.private_imgs = cell(1,1);
                   obj.private_imgs{1} = cimg{1};
                   obj.private_slice_nos = {obj.slice_nos, proj_inds, obj.shifts, obj.filter_options};
                case 2
                   %Add
                   obj.private_imgs{numel(obj.private_imgs)+1} = cimg{1}(:,:,to_store>0);
                   obj.private_slice_nos(numel(obj.private_imgs),:) = {obj.slice_nos(to_store>0), proj_inds, obj.proj_shifts, obj.filter_options};
            end           
            
            %Crop to ROI width after reading    
            if ~isempty(obj.ROI)
                 cimg{1} = cimg{1}(:,obj.ROI(1,2):obj.ROI(2,2):obj.ROI(3,2),:);   
            end
            
            %Pad sinogram
            if ~isempty(obj.padding_options)
                cimg{1} = padtovalue(cimg{1}, obj.padding_options(1), obj.padding_options(2));
            end
            
        end
        
        
    
end

end