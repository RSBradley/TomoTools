function txmimage_write8(foh, img_no, data, isref, rotby90)

% Write image to Xradia files (*.xrm, *.txm, *.txrm).
%
%       txmimage_write9(foh, img_no, data, isref)
%
% where
%       data = required data returned in a matrix or cell
%        foh = an Xradia file name or a header structure obtained using the matlab function
%              txmheader_read.
%   image_no = integer specifying the image number to write to.
%      isref = overwrite to reference image (1) or non-reference image (0).
%
% Written by: Rob Bradley, (c) 2015

%Check if header information is supplied
if ischar(foh)
   %foh is a file name
   %read header information
   header = txmheader_read8(foh); 
else
   header = foh;
end

if nargin<4
    isref = 0;
end

if nargin<5
    rotby90 = 1;
end

if isempty(img_no)
    isref = 1;
    img_no = 0;
end

%Create full path
if isref 
    if img_no==0
        fp = 'ReferenceData\Image';
    else
        fp = ['ReferenceData\Image' num2str(img_no)];
    end
else
    if img_no>header.ImageInfo.NoOfImages
        error('TXMimage_write: image does not exist.');
    end
    fp = ['ImageData' num2str(floor((img_no-1)/100)+1) '\Image' num2str(img_no)];
end

  

%Check dimensions match
sz = size(data);
if  sz(1)~=header.ImageInfo.ImageHeight || sz(2)~=header.ImageInfo.ImageWidth
    error('TXMimage_write: image data is the wrong size.');
end


%Determine data type
if isref
    dt = header.ReferenceData.DataType;
else
    dt = header.ImageInfo.DataType;
end
    
switch dt
    case 3
         data = uint8(data);        
      case 5
         data = uint16(data);        
      case 10
          data = single(data);         
end

if rotby90
    data = data.';
    data = data(:,end:-1:1);
end


%Write data
writedata;

    function writedata
        %function to write image data to file        
        fwritess(foh.File, {fp}, {data});
    end
    
    
end