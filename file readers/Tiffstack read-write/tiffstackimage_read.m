function img = tiffstackimage_read(foh, image_no, apply_ref,rotby90,apply_filter,read_fcn)


%Check if header information is supplied
if ischar(foh)
   %foh is a file name
   %read header information
   foh = tiffstackheader_read(foh); 
end

%Check input arguments
if nargin<6
    read_fcn = 'readtif';
end
if ~strcmpi(foh.Imfinfo(1).Compression, 'Uncompressed')    
   read_fcn = 'imread'; 
end
if nargin<3
    apply_ref = 1;
end
if nargin<4
    rotby90 = 0;
end
if nargin<5
    apply_filter = 1;
end
if apply_ref & ~isempty(foh.ReferenceCorrection.mode)
    %Reference corrected images must be single
    foh.DataType = 'single';
end

%Loop over multiple images
if numel(image_no)>1   
   if rotby90
       img = zeros([foh.ImageWidth, foh.ImageHeight, numel(image_no)], foh.DataType); 
   else
       img = zeros([foh.ImageHeight, foh.ImageWidth, numel(image_no)], foh.DataType); %ORIGINAL
   end
   for ni = 1:numel(image_no)      
      img(:,:,ni) =  tiffstackimage_read(foh, image_no(ni), apply_ref,rotby90,apply_filter,read_fcn);
   end   
   return;
end


%Read data
switch read_fcn
    case 'Tiff'
        readimage_tiff;
    case 'fread'
        readimage_fread;
    case 'imread'
        readimage_imread;
    case 'readtif'
        readimage_readtif;
        
end

%2D filtering of images
if apply_filter & ~strcmpi(foh.Filter{1}, 'none');    
    img = foh.Filter{2}(img);    
end


%Reference correction
if apply_ref & ~isempty(foh.ReferenceCorrection.mode)
   switch foh.ReferenceCorrection.mode
       case 'single'
           black_ref = foh.ReferenceCorrection.black_ref.data;
           white_ref = foh.ReferenceCorrection.white_ref.data;
       case  'multi'
            if foh.ReferenceCorrection.black_ref.mode==1
                black_ref = foh.ReferenceCorrection.black_ref.data;               
            else
                black_ref = interp_ref(0);
            end
            if foh.ReferenceCorrection.white_ref.mode==1
                white_ref = foh.ReferenceCorrection.white_ref.data;                
            else
                white_ref = interp_ref(1);
            end
           
   end
   white_ref = single(white_ref);
   black_ref = single(black_ref);  
   img = single(img);
   img = (img-black_ref)./(white_ref-black_ref);
end

%Rotate by 90 degrees
if rotby90
   img = img.';
   img = img(end:-1:1,:);    
end

%readimage;


    function readimage_tiff
        
       t = foh.TiffStruct;
       t.FileName = foh.FileNames{foh.UseInds(image_no)};
       img = t.read();
        
        
        
        
    end

    function readimage_readtif
        
       i = foh.Imfinfo;
       FileName = foh.FileNames{foh.UseInds(image_no)}; 
       tmp = cd;
       cd([matlabroot '\toolbox\matlab\imagesci\private']);
       img = readtif(FileName,1,'Info', i);
       cd(tmp); 
       
        
        
    end

    function readimage_imread
        
       FileName = foh.FileNames{foh.UseInds(image_no)};
       img = imread(FileName);
        
    end



    function readimage_fread
       %Open file
       fid = fopen(foh.FileNames{foh.UseInds(image_no)}, 'r');

       %Preallocate
       img = zeros(foh.ImageHeight, foh.ImageWidth, foh.DataType); 
       n_strips = numel(foh.StripOffsets);
       curr_ind = 1;
       for n = 1:n_strips
           end_ind = curr_ind+foh.PixelsPerStrip(n)-1;
           fseek(fid,  foh.StripOffsets(n), 'bof');
           %tmp = fread(fid, foh.PixelsPerStrip(n), foh.DataType);
           %size(tmp)
           %size(img(curr_ind:end_ind))
           img(curr_ind:end_ind) = fread(fid, foh.PixelsPerStrip(n), foh.DataType);
           curr_ind = end_ind+1;
          % pause
           
       end
        
       fclose(fid);
        
    end

    function i_out = interp_ref(val)

        if val==0           
            name = 'black_ref';            
        else
            name = 'white_ref';
        end
        
        interp_mode = foh.ReferenceCorrection.(name).mode;
        
        if iscell(foh.ReferenceCorrection.(name).images)
            
            
        else
           %find nearest images
           curr_ind = foh.UseInds(image_no);
           c_diff = foh.ReferenceCorrection.(name).images-curr_ind;
           ind_a = find(foh.ReferenceCorrection.(name).images==min(c_diff(c_diff>0))+curr_ind);
           ind_b = find(foh.ReferenceCorrection.(name).images==max(c_diff(c_diff<0))+curr_ind);
           
           %t = foh.TiffStruct;
          
           if interp_mode==2
               if abs(ind_a)<abs(ind_b)
                   i_out = foh.ReferenceCorrection.(name).data{ind_a};
                   %t.FileName = foh.FileNames{ind_a+curr_ind};
                   %i_out = t.read();
               else
                   i_out = foh.ReferenceCorrection.(name).data{ind_b};
                   %t.FileName = foh.FileNames{ind_b+curr_ind};
                   %i_out = t.read();
               end
            
           else
               %t.FileName = foh.FileNames{ind_a+curr_ind};
               %tmp1 = t.read();
               
               %t.FileName = foh.FileNames{ind_b+curr_ind};
               %tmp2 = t.read();
               
               i_out = ( foh.ReferenceCorrection.(name).data{ind_a}+ foh.ReferenceCorrection.(name).data{ind_b})/2;
               %imager(i_out, 'range', [0 3000])
               
           end
           
        end
        
    end
 end 