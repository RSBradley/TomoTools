function img = vivimage_read(hdr,img_no,varargin)

%Data is in column,row,format

%Find volume dimensions
sz = double([hdr.ImageWidth hdr.ImageHeight hdr.NoOfImages]);

%offset to pixel values
hoffset = double(hdr.Header_Size);

%Find datatype
switch hdr.Format;
    case 2
        datatype = '*uint16';  
        bitsperpixel=16;
end

%Open file for reading
if ~isempty(hdr.FileIdentifier{1})
    %File already open
    fid = hdr.FileIdentifier{1};
    do_close = 0;
else    
    fid = fopen(hdr.File, 'r');
    do_close = 1;
end    
if fid==-1
    error('VIVError: file cannot be opened');
end    

%Read images
if numel(img_no)>1
    img = zeros(sz(1),sz(2),numel(img_no), datatype(2:end));
    for n = 1:numel(img_no)
       img(:,:,n) =  readimage(img_no(n));
    end
    
else
    img = readimage(img_no);
end

    
if do_close
    fclose(fid);
end    


    function img_o = readimage(imgn)

        %Find start of image in raw file        
        offset = (imgn-1)*sz(1)*sz(2)*bitsperpixel/8 + hoffset;  
        fseek(fid, offset, 'bof');

        %Read data
        img_o = fread(fid, sz(1)*sz(2), datatype);

        %Reshape image
        img_o = reshape(img_o, sz(1), sz(2));
    end

end

