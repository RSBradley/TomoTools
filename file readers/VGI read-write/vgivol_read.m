function img = xtekvol_read(hdr, img_no, varargin)

%Check file format is raw
if ~strcmpi(hdr.volume1.file1.fileformat, 'raw');
    error('XtekError: file is not in raw format');
end

%Find volume dimensions
sz = hdr.volume1.file1.size;

%Find datatype
switch hdr.volume1.file1.bitsperelement;
    case 32
        datatype = 'float32';
    case 16
        datatype = 'uint16';
end

%Open file for reading
if ~isempty(hdr.FileIdentifier{1})
    %File already open
    fid = hdr.FileIdentifier{1};
    do_close = 0;
else    
    pathstr = fileparts(hdr.FileName);
    if ~strcmpi(pathstr(end), '\')
        pathstr = [pathstr '\'];
    end
    fid = fopen([pathstr hdr.volume1.file1.name], 'r');
    do_close = 1;
end    
if fid==-1
    error('XtekError: file cannot be opened');
end    


%Find start of image in raw file
offset = (img_no-1)*sz(1)*sz(2)*hdr.volume1.file1.bitsperelement/8;
fseek(fid, offset, 'bof');

%Read data
img = fread(fid, sz(1)*sz(2), datatype);

%Reshape image
img = reshape(img, sz(1), sz(2));

if do_close
    fclose(fid);
end    



end