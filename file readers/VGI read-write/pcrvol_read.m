function img = pcrvol_read(hdr, img_no, varargin)

%Read pcr files from GE Phoenix system

%Find volume dimensions
sz = [hdr.fields.volumedata.volume_sizex hdr.fields.volumedata.volume_sizey hdr.fields.volumedata.volume_sizez];

%Find datatype
switch hdr.fields.volumedata.format;
    case 10
        datatype = 'float32';
        bitsperelement = 32;
    case 16
        %????
        datatype = 'uint16';
        bitsperelement = 16;
end

%Open file for reading
do_close = 1;
if ~isempty(hdr.FileIdentifier{1})
    %File already open
    fid = hdr.FileIdentifier{1};
    do_close = 0;
else    
    %%pathstr = fileparts(hdr.FileName);
    %%if ~strcmpi(pathstr(end), '\')
    %%%    pathstr = [pathstr '\'];
    %%end
    
    %%[ptmp, f_name ext] = fileparts(hdr.fields.volumedata.vol_file);
    %%[pathstr f_name ext]
    %%fid = fopen([pathstr f_name ext], 'r');
    %%do_close = 1;
    
    fid = fopen([hdr.FileName(1:end-3) 'vol'], 'r');
end    
if fid==-1
    error('PCRError: file cannot be opened');
end    


%Find start of image in raw file
offset = (img_no-1)*sz(1)*sz(2)*bitsperelement/8;
fseek(fid, offset, 'bof');

%Read data
img = fread(fid, sz(1)*sz(2), datatype);

%Reshape image
img = reshape(img, sz(1), sz(2));

if do_close
    fclose(fid);
end    



end