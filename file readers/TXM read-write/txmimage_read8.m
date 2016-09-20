function img = txmimage_read8(foh, image_no, apply_ff, rotby90)

% Reads images from Xradia files (*.xrm, *.txm, *.txrm). Update to use
% mex file for improvement in speed
%
%      img = txmimage_read(foh, image_no, apply_ff)
%
% where
%       img = image data (2D matrix)
%       foh = a file name of a header structure obtained using the matlab function
%             txmheader_read4
%  image_no = the number of the image to be read (e.g. 2 for 2nd image in file).
%             entering an empty vector will return the flat field image. 
%  apply_ff = 0 (do not) or 1 (do) apply flat field correction. If not
%             specified, flat field correction will be applied by default.
%             A warning is given if the flat field cannot be found.
%   rotby90 = 0 (do not) or 1 (do) rotate img by 90 degrees. If not
%            specified, image will be rotated by default.
%
% Written by: Rob Bradley, (c) 2015

%Check if header information is supplied
if ischar(foh)
   %foh is a file name
   %read header information
   foh = txmheader_read8(foh); 
end

%Check if to apply flat field (white) reference. No flat field for
%reconstruction images
if nargin <3
    if ~strcmpi(strtok(foh.FileContents, ' '), 'Reconstruction') && ~isempty(image_no) && isfield(foh, 'ReferenceData')
        apply_ff = 1;
        
    else
        apply_ff = 0;
        
    end    
    rotby90 = 1;
end


%Check if flat field exists
if apply_ff & ~isfield(foh, 'ReferenceData')
    warning('TXMIMAGE_READ:noflatfield','Cannot apply flat field correction as it cannot be found.');
    apply_ff=0;
end    




%Determine image size
img_size = [foh.ImageInfo.ImageWidth foh.ImageInfo.ImageHeight];
if nargin<2
    image_no  = 1:double(foh.ImageInfo.NoOfImages);
end
nimgs = numel(image_no);
img = [];
if nimgs>1
    for k = 1:nimgs
       if isempty(img)
           
            img = repmat(txmimage_read8(foh, image_no(k), apply_ff, rotby90), [1 1 nimgs]);
        
       else
           img(:,:,k) = txmimage_read8(foh, image_no(k), apply_ff, rotby90);
       end
    end
    return;
    
end

%Images in the txm file are located by the Image# entry in the txm header
img_name = ['Image' num2str(image_no)];
if ~isfield(foh.DataLocations, img_name)
    %Error if there is no header entry for requested image
    %i.e. image does not exist
    error([img_name ' does not exist.']);
    return;
end    



imgdata_no = floor((image_no-1)/100)+1;
struct_name = ['ImageData' num2str(imgdata_no)];    

%Determine data type
datatype = foh.ImageInfo.DataType;

if isempty(image_no) %LOAD REFERENCE DATA  
    apply_ff = 0;
    %rotby90 = 0;
   if isfield(foh, 'MultiReferenceData')

        %Multi reference correction
        datatype = foh.MultiReferenceData.DataType;
        struct_name = 'MultiReferenceData';
        net_img = 0;
        mean_counts = zeros(1,foh.MultiReferenceData.TotalRefImages);
        for nr = 1:foh.MultiReferenceData.TotalRefImages
            img_name = ['Image' num2str(nr)];
            readimage;
            net_img = net_img+img;
            mean_counts(nr) = mean(double(img(:)));                
        end

        %Average reference image
        img = double(net_img)/double(foh.MultiReferenceData.TotalRefImages); 
        norm_factors = mean(mean_counts)./mean_counts;


        %Interpolate norm factors
        xdata = double(foh.MultiReferenceData.RefInterval).*[0:double(foh.MultiReferenceData.TotalRefImages)-1];
        norm_factors = interp1(xdata, norm_factors, 1:double(foh.ImageInfo.NoOfImages), 'linear', 'extrap');

   else
       img = NaN;
   end
   if isnan(img)
        %Single reference correction    
        img_name = 'Image';   
        datatype = foh.ReferenceData.DataType;

        struct_name = 'ReferenceData';
        readimage; 
        norm_factors = ones(1,foh.ImageInfo.NoOfImages);
        
   end    
   
   %PUT INTO CELL STRUCTURE SUITABLE FO MULTIREFERENCE AND SINGLE REFERENCE
   %CORRECTION
   img = {img, norm_factors};
   
else
    %Read image
    readimage;
end


%Read and apply flatfield correction
if apply_ff
    img_tmp = img;
    if ischar(foh.ReferenceData.Image)
        %need to load reference data from file
        
        if isfield(foh, 'MultiReferenceData')
            
            %Multi reference correction
            datatype = foh.MultiReferenceData.DataType;
            struct_name = 'MultiReferenceData';
            net_img = 0;
            mean_counts = zeros(1,foh.MultiReferenceData.TotalRefImages);
            for nr = 1:foh.MultiReferenceData.TotalRefImages
                img_name = ['Image' num2str(nr)];
                readimage;
                net_img = net_img+img;
                mean_counts(nr) = mean(double(img(:)));                
            end
            
            %Average reference image
            img = double(net_img)/double(foh.MultiReferenceData.TotalRefImages); 
            norm_factors = mean(mean_counts)./mean_counts;
            
            
            %Interpolate norm factors
            xdata = double(foh.MultiReferenceData.RefInterval).*[0:double(foh.MultiReferenceData.TotalRefImages)-1];
            norm_factors = interp1(xdata, norm_factors, 1:double(foh.ImageInfo.NoOfImages), 'linear', 'extrap');
            
            %Current norm factor            
            NF = single(norm_factors(image_no));
        else
            img = NaN;
        end
          
        if isnan(img)
            %Single reference correction               
            img_name = 'Image';   
            datatype = foh.ReferenceData.DataType;

            struct_name = 'ReferenceData';
            readimage; 
            
            NF = single(1);
        end    
        
          img = single(1./img); %CONVERT TO MULTIPLICATIVE SCALING
    else
        %Load reference data from header
        img = foh.ReferenceData.Image{1};
        norm_factors = foh.ReferenceData.Image{2};
        NF = norm_factors(image_no);
    end
    
    %Apply reference correction
    if apply_ff>1
       img = NF*single(img_tmp); %Apply counts normalisation only 
    else
        img = NF.*single(img_tmp).*img;
    end
    %img = NF*single(double(img_tmp)./double(img));
end

%Rotate by 90 degrees
if rotby90
    if iscell(img)
        img{1} = img{1}.';
        img{1} = img{1}(end:-1:1,:);        
    else
        img = img.';
        img = img(end:-1:1,:);
    end
    %img = rot90(img);
    %img = img(end:-1:1,:);
end
%Close file if necessary
%if isempty(foh.FileIdentifier{1})
%    fclose(fid);
%end

    function readimage
    %function to read image data from file
    %uses freadss function
    %Check datatype    
    
    switch datatype
      case 3
         data_type = {'uint8'};
      case 5
         data_type = {'uint16'};
      case 10
         data_type = {'single'};
    end
    
    tmp = freadss1(foh.File, {[struct_name '\' img_name]}, data_type);
    
    %reshape image data
    %img(:) = tmp{:};
    if numel(tmp{1})==prod(img_size)
        img = zeros(img_size, data_type{1});
        img(:) = cell2mat(tmp);
    else
       img = NaN; 
    end
    
        
    
    end






end