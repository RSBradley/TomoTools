function s = create_SINO_DATA3D(PDATA, img_ff, rotby90, slices, proj_inds, sfname, shifts, pad_opt, filt_opts, show_wb, parallel_mode)

% FUNCTION to generate sinogram(s) from projection data incorporating
% the following pre-processing steps:
%
%   1. Cropping of projection images
%   2. Application of dither shifts (x and y)
%   3. Padding of projection images
%   4. Filtering of projection images
%
%   NB. PADDING OF SINOGRAMS TO BE DONE AFTER SINOGRAM CREATION
%  % Written by: Rob Bradley, (c) 2015

warning off

%% RETURN an image if PDATA is a sinogram
if strcmpi(PDATA.contents, 'Sinograms')
   s = PDATA(:,:,slices);
   return;
end


%% PARSE INPUTS AND SET DEFAULTS
%Output file name
if nargout<1 & isempty(sfname)
    sfname = '';
end

%PARSE OPTIONAL INPUTS
%Pad options
if nargin<8
    pad_opt = [0 1];
end


%Apply dither shifts
PDS = PDATA.apply_shifts;
if nargin<7 | isempty(shifts)
    do_shifts = 0;
    yshifts = [];
    xshifts = [];
else
    yshifts = shifts(:,2);
    xshifts = shifts(:,1);
    do_shifts = 1;
    PDATA.apply_shifts = 0; %Turn of projection data shifts
end    

%Padding options
if nargin<8
    filt_opts = [];
end


%Filter on loading projections
if nargin<9
    pad_opt = [];
end

if isempty(filt_opts)
    do_filt = 0;
    n_filt = 0;
else
    do_filt = 1;
    n_filt = size(filt_opts,1);
end

%Show waitbar
if nargin<10
    show_wb = 1;
end

%parallel computing mode
if nargin<11
    parallel_mode = 24;
end


%% CALCULATE PRELIMINARY VALUE
%Calculate dimensions of sinogram
img_width = PDATA.dimensions(2);
img_height = PDATA.dimensions(1);

if isempty(pad_opt)
    pad_opt = [0 1];
end
if pad_opt(1)>0
    do_pad = 1;
    img_width = img_width+2*pad_opt(1);
else
    do_pad = 0;    
end

%Rotate ff as necessary
if ~isempty(img_ff) & rotby90
    img_ff = img_ff.';
    img_ff = img_ff(end:-1:1,:);
end

% SET SLICES/ROWS TO BUILD SINOGRAMS FROM
%slices = ROI(1,1):ROI(2,1):ROI(3,1);
n_spaces = num2str(numel(num2str(max(slices)))+1);
s_fmt_str = ['%0' n_spaces 'i'];

%SET IMAGES/ANGLES TO USE
m = proj_inds;
n_angles = numel(m);


% Set values used for cropping sinogram before interpolation - speed up
if numel(slices)<img_height
   do_crop =1; 
   if do_shifts
        ymax = max(yshifts(:));
        ymin = min(yshifts(:));
        
        ycrop_rng(1) = floor(max(min(slices(:))+ymin,1)); %changed from 1 to ROI(1,1)
        ycrop_rng(2) = ceil(min(max(slices(:))+ymax,img_height)); %changed from img_height to ROI(1,1)
   else
       ycrop_rng(1) = max(min(slices(:)),1);%changed from 1 to ROI(1,1)
       ycrop_rng(2) = min(max(slices(:)),img_height);%changed from img_height to ROI(3,1)
   end
else
    do_crop = 0;
    ycrop_rng = [1 img_height];% %changed from [1 img_height] to ROI([1 3],1)
end
if ycrop_rng(1)==ycrop_rng(2)
    ycrop_rng(1) = ycrop_rng(1)-1;
    ycrop_rng(2) = ycrop_rng(2)+1;
end

%Set variables used for interpolation if apply shifts
n_slices = numel(slices);
if numel(slices)>1
    slices1 = repmat(slices(:), [1 img_width]);
    xorig = repmat(1:img_width, [size(slices1,1) 1]);
else
    slices1 = repmat([slices(:)-1:slices(:)+1]', [1 img_width]);
    xorig = repmat(1:img_width, [size(slices1,1) 1]);    
    ycrop_rng(1) = ycrop_rng(1)-1;
end
y_in = repmat([ycrop_rng(1):ycrop_rng(2)]', [1 img_width]);
x_in = repmat(1:img_width, [size(y_in,1) 1]);



%% Initialise sinogram tiffs 
t_handles = [];
if ~isempty(sfname)
    tagstruct.ImageLength = n_angles;
    tagstruct.ImageWidth = img_width;
    tagstruct.Photometric = 1;
    tagstruct.RowsPerStrip = 1;
    tagstruct.BitsPerSample = 32;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.SampleFormat = 3;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'CREATE_SINOGRAM';

    t_handles = cell(n_slices);

    if ~isempty(sfname)    
        for pp = 1:n_slices
        s_ind = sprintf(s_fmt_str, slices(pp));
        t_handles{pp} = Tiff([sfname s_ind '.tif'],'w');  
        t_handles{pp}.setTag(tagstruct);
        end
    
    end
end

%% INITIALISE OUTPUT VARIABLE
if nargout==1
    s = zeros(n_angles, img_width, n_slices, 'single');
    stmp = cell(n_angles,1);
else
    s = [];
end

%% CREATE SINOGRAMS
switch parallel_mode
    case 0
        seq_calc;
    otherwise
        if isempty(sfname)
            full_parallel_calc; %parallel processing to memory
        else            
            parallel_calc(parallel_mode); %write to tiff in chunks
        end
end

%Tidy up
%Close tiff files
if ~isempty(sfname)
   for pp = 1:n_slices         
        t_handles{pp}.close();        
   end 
end

%Reset shifts
PDATA.apply_shifts = PDS;



%% Write out sinogram info to be loaded as DATA3D obj
if ~isempty(sfname)
    sinogram.FileType = 'TTxml v1.0';
    sinogram.Format = 'tiffstack';
    sinogram.File = sfname;
    sinogram.SourceFile = PDATA.file;
    sinogram.FileContents = 'Sinograms';
    sinogram.DataType = 'float32';
    sinogram.ImageHeight = n_angles;
    sinogram.ImageWidth = img_width;
    sinogram.NoOfImages = n_slices;
    sinogram.PixelSize = PDATA.pixel_size;
    sinogram.PixelUnits = PDATA.pixel_units;    
    sinogram.Angles = PDATA.angles(m);    
    sinogram.R1 = PDATA.R1;
    sinogram.R2 = PDATA.R2;
    sinogram.Shifts = shifts;
    sinogram.Units = PDATA.units;
    sl_pos = strfind(sfname, '\');
    xml_write([sfname(1:sl_pos(end)-1) '\sinogram_info.xml'], sinogram);
end

%%
    function full_parallel_calc
       %Suitable when not outputting to disk 
       if show_wb            
%             wb = com.mathworks.mlwidgets.dialog.ProgressBarDialog.createProgressBar('Creating sinograms...', []);
%             wb.setValue(0);
%             wb.setSpinnerVisible(false);
%             wb.setCircularProgressBar(true);
%             wb.setCancelButtonVisible(false);
%             wb.setVisible(true); 
%             wb.setProgressStatusLabel('Creating sinogram(s)...')
              options.Title = 'create_SINO_DATA3D';
              options.InfoString  = 'Creating sinogram(s)...';
              wb = TTwaitbar('busy', options);
              pause(1);
       end

        %q=1:numel(m);
        counter = 0;        
        
        parfor n=1:numel(m)
           %Loop over angles
           counter = counter+1;
           curr_i = m(n);
           %q = q+1;  %Update counter  

           fprintf(1, ['Processing angle ' sprintf('%4.0f', curr_i) '...']);

           tic;

          
           if PDATA.ROIread
                %Crop for faster reading
                img = ones(img_width, img_height);
                img(:,ycrop_rng(1):ycrop_rng(2)) = PDATA(ycrop_rng(1):ycrop_rng(2),:,curr_i);
           else
                 %Read projection, no cropping
                 img = PDATA(:,:,curr_i);
           end
           if ~isempty(img_ff)
              img = single(img)./img_ff; 
           end

           java.lang.Thread.sleep(0.5);  

           %Pad projection image to left and right
           if do_pad
                img = padtovalue(img, [0 pad_opt(1)],pad_opt(2));
           end

           %Apply filter(s)
           if do_filt
               for pf = 1:n_filt
                   %filt_opts
                   %img = fh(img, []);
                   %filt_opts{pf,2:end}{:}
                   
                   %%WARNINGS HERE!!
                   img = filt_opts{pf,1}(img, filt_opts{pf,2:end}{:});
                   
                   %img = filt_opts{pf,1}(img, []);
               end
           end

           %Determine shifts
           if do_shifts
               %APPLY SHIFTS
                y = slices1+yshifts(curr_i);
                x = xorig-xshifts(curr_i);

                %Circular padding
                %x(x<1) = x(x<1)+img_width-1;
                %x(x>img_width) = x(x>img_width)-img_width+1;

                %Crop before interpolation to improve speed
                if do_crop
                    %crop then rotate
                    if rotby90

                        img_crop = img(:,size(img,2)-[ycrop_rng(1):ycrop_rng(2)]+1).';                
                        s_slice = interp2(x_in, y_in, img_crop, x, y, 'linear', pad_opt(2));
                    else
                        s_slice = interp2(x_in, y_in, img(ycrop_rng(1):ycrop_rng(2),:), x, y, 'linear', pad_opt(2));  
                    end
                else
                    %No cropping
                    if rotby90
                       img = img.';
                       img = img(end:-1:1,:);
                    end
                    s_slice = interp2(x_in, y_in, img, x, y, 'linear', pad_opt(2));             
                end

                yrng_final = slices-min(y(:))+1+yshifts(curr_i);


           else
               %NO SHIFTS - only crop
               if rotby90
                   s_slice = img(:,size(img,2)-[ycrop_rng(1):ycrop_rng(2)]+1).';
               else
                   s_slice = img(ycrop_rng(1):ycrop_rng(2),:);
               end
               yrng_final = slices-ycrop_rng(1)+1;
           end

           yrng_final = round(yrng_final);

           %CONVERT FROM PROJECTION DATA TO SINOGRAM
           s_slice = single(real(-log(s_slice)));

           %Update output as necessary
           stmp{n} = zeros(1, img_width, n_slices, 'single');
           stmp{n}(:) = s_slice(yrng_final,:)';           

           
           t = toc;
           fprintf(1, ['Done in ' num2str(t) 's.\n']);           

        end
        
        %Aggregate output from pool       
        for ns = 1:numel(stmp)             
             s(ns,:,:) = stmp{ns}(1,:,:);
        end

        %TIDY UP
        warning on
        if show_wb
            close(wb);
        end
    end

%%
       function seq_calc
        q=1:numel(m);
        if show_wb
            options.Title = 'SINO_DATA3D';
            options.InfoString = 'Creating sinogram(s)...';
            wb = TTwaitbar(0, options);
        end
           

        
        for n = 1:numel(m)
            %Loop over angles 
            fprintf(1, ['Processing angle ' sprintf('%4.0f', m(n))  '...']);
            tic;
            
            %Read projection, no cropping 
            if PDATA.ROIread
                %Crop for faster reading
                img = zeros(img_width, img_height);
                img(:,ycrop_rng(1):ycrop_rng(2)) = PDATA(ycrop_rng(1):ycrop_rng(2),:,m(n));
            else
                img = PDATA(:,:,m(n));
            end
             if ~isempty(img_ff)
                 img = single(img)./img_ff; 
             end

              %Pad projection image to left and right
               if do_pad
                    img = padtovalue(img, [0 pad_opt(1)],pad_opt(2));
               end

               %Apply filter(s)
               if do_filt
                   for pf = 1:n_filt
                       img = filt_opts{pf,1}(img, filt_opts{pf,2:end}{:});
                   end
               end

               %Determine shifts
               if do_shifts
                   %APPLY SHIFTS
                    y = slices1+yshifts(m(n));
                    x = xorig-xshifts(m(n));

                    %Circular padding
                    %x(x<1) = x(x<1)+img_width-1;
                    %x(x>img_width) = x(x>img_width)-img_width+1;

                    %Crop before interpolation to improve speed
                    if do_crop
                        %crop then rotate
                        if rotby90

                            img_crop = img(:,size(img,2)-[ycrop_rng(1):ycrop_rng(2)]+1).';                
                            s_slice = interp2(x_in, y_in, img_crop, x, y, 'linear', pad_opt(2));
                        else
                            s_slice = interp2(x_in, y_in, img(ycrop_rng(1):ycrop_rng(2),:), x, y, 'linear', pad_opt(2));  
                        end
                    else
                        %No cropping
                        if rotby90
                           img = img.';
                           img = img(end:-1:1,:);
                        end
                        s_slice = interp2(x_in, y_in, img, x, y, 'linear', pad_opt(2));             
                    end

                    yrng_final = slices-min(y(:))+1+yshifts(m(n));


               else
                   %NO SHIFTS - only crop
                   if rotby90
                       s_slice = img(:,size(img,2)-[ycrop_rng(1):ycrop_rng(2)]+1).';
                   else
                       s_slice = img(ycrop_rng(1):ycrop_rng(2),:);
                   end
                   yrng_final = slices-ycrop_rng(1)+1;
               end

               yrng_final = round(yrng_final);

               %CONVERT FROM PROJECTION DATA TO SINOGRAM
               s_slice = single(real(-log(s_slice)));

               %Update output as necessary  
               if ~isempty(s)       
                    s(q(n),:,:) = s_slice(yrng_final,:)';
               end
                
               %Write data to tiff files as necessary
                if ~isempty(sfname)
                for p = 1:n_slices
                    %Write stips        
                    t_handles{p}.writeEncodedStrip(qc, s_slice(yrng_final(p), :));         
                end 
                end
               t = toc;
               fprintf(1, ['Done in ' num2str(t) 's.\n']); 
               if show_wb
                    TTwaitbar(q(n)/n_angles,wb);
               end
                 
        end          
            
                       
            
            
            
        end
        
        
        function parallel_calc(nchunks)
       
        if show_wb
            options.Title = 'SINO_DATA3D';
            options.InfoString = 'Creating sinogram(s)...';
            wb = TTwaitbar(0, options);
        end
           

        %Outer loop over chunks
        chunks = 1:nchunks:numel(m);
        if chunks(end)~=numel(m)
            chunks(end+1) = numel(m)+1;
        else
            chunks(end) = numel(m)+1;
        end
        for no = 1:numel(chunks)-1
            q = chunks(no):chunks(no+1)-1;
            
            fprintf(1, ['Processing angles ' sprintf('%4.0f', m(q(1))) ' to ' sprintf('%4.0f', m(q(end))) '...']);
            tic;
            curr_is = m(q);
            stmp = cell(numel(q),1);
            parfor ni=1:numel(q)
                
               %Loop over angles               
               curr_i = curr_is(ni);

               %Read projection, no cropping   
               img = PDATA(:,:,curr_i);

               if ~isempty(img_ff)
                  img = single(img)./img_ff; 
               end

               java.lang.Thread.sleep(0.5);  

               %Pad projection image to left and right
               if do_pad
                    img = padtovalue(img, [0 pad_opt(1)],pad_opt(2));
               end

               %Apply filter(s)
               if do_filt
                   for pf = 1:n_filt
                       img = filt_opts{pf,1}(img, filt_opts{pf,2:end}{:});
                   end
               end

               %Determine shifts
               if do_shifts
                   %APPLY SHIFTS
                    y = slices1+yshifts(curr_i);
                    x = xorig-xshifts(curr_i);

                    %Circular padding
                    %x(x<1) = x(x<1)+img_width-1;
                    %x(x>img_width) = x(x>img_width)-img_width+1;

                    %Crop before interpolation to improve speed
                    if do_crop
                        %crop then rotate
                        if rotby90

                            img_crop = img(:,size(img,2)-[ycrop_rng(1):ycrop_rng(2)]+1).';                
                            s_slice = interp2(x_in, y_in, img_crop, x, y, 'linear', pad_opt(2));
                        else
                            s_slice = interp2(x_in, y_in, img(ycrop_rng(1):ycrop_rng(2),:), x, y, 'linear', pad_opt(2));  
                        end
                    else
                        %No cropping
                        if rotby90
                           img = img.';
                           img = img(end:-1:1,:);
                        end
                        s_slice = interp2(x_in, y_in, img, x, y, 'linear', pad_opt(2));             
                    end

                    yrng_final = slices-min(y(:))+1+yshifts(curr_i);


               else
                   %NO SHIFTS - only crop
                   if rotby90
                       s_slice = img(:,size(img,2)-[ycrop_rng(1):ycrop_rng(2)]+1).';
                   else
                       s_slice = img(ycrop_rng(1):ycrop_rng(2),:);
                   end
                   yrng_final = slices-ycrop_rng(1)+1;
               end

               yrng_final = round(yrng_final);

               %CONVERT FROM PROJECTION DATA TO SINOGRAM
               s_slice = single(real(-log(s_slice)));

               %Update output as necessary               
               stmp{ni} = zeros(1, img_width, n_slices, 'single');
               stmp{ni}(:) = s_slice(yrng_final,:)';
            end          
            
            
            %Aggregate output from pool
            %for ns = 1:numel(stmp)        
            %    s(ns,:,:) = stmp{ns}(:);             
            %end
            
            %Write data to tiff files as necessary
            
            
            if ~isempty(sfname)
                for po = 1:n_slices
                    %Write strips
                    count = 0;
                   
                    for pi = q
                        count = count+1;                        
                        t_handles{po}.writeEncodedStrip(pi, stmp{count}(1,:, po));   
                    end
               end 
            end
            t = toc;
            fprintf(1, ['Done in ' num2str(t) 's.\n']);    
            TTwaitbar(no/(numel(chunks)-1), wb);    
        end
        

        %% TIDY UP
        warning on
        if show_wb
            close(wb);
        end
    end



 

end