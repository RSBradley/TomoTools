function [hdr, hdr_short] = vivheader_read(file)

%Paxscan viv file format

%Open file for reading
fid = fopen(file, 'r');

%Create hdr
hdr.File = file;
hdr.FileIdentifier ={[],[]};
hdr.Header_Size = fread(fid,1,'*uint32');
hdr.Version = fread(fid, 12, '*char')';
hdr.ImageWidth = fread(fid, 1, 'uint32');
hdr.ImageHeight = fread(fid, 1, 'uint32');
hdr.Format = fread(fid, 1, 'uint32');
hdr.NoOfImages = fread(fid, 1, 'uint32');

%unknown values
fread(fid, 16, 'uint8');
fread(fid, 1, 'uint32'); %0
fread(fid, 1, 'uint32'); %1
fread(fid, 1, 'uint32'); %65535 maximum pixel value?
fread(fid, 1, 'uint32'); %0
hdr.DateTime = fread(fid, 20, '*char');

fseek(fid,1112, 'bof'); %skip values
hdr.ReceptorSerialNo = fread(fid, 36, '*char')';
%fread(fid, 36, '*char'); %Not available


%Create short header
hdr_short.File = file;
hdr_short.FileContents = 'Projections';

hdr_short.Voltage = [];
hdr_short.Current = [];
hdr_short.ExposureTime = [];


hdr_short.Units = 'cm';
hdr_short.PixelUnits = 'microns';
hdr_short.R1 = [];
hdr_short.R2 = [];
hdr_short.PixelSize = [];


%Data is in column,row,format  - switch!
hdr_short.ImageWidth = hdr.ImageHeight;
hdr_short.ImageHeight = hdr.ImageWidth;
hdr_short.NoOfImages = hdr.NoOfImages;
hdr_short.RotBy90 = 0;       
hdr_short.Angles = [];

%Data Type
switch hdr.Format
    case 2
        hdr_short.DataType ='uint16';
        
end
hdr_short.DataRange = [0 eval([hdr_short.DataType '(Inf);'])];

%Reference correction - done already
hdr_short.ApplyRef = 1;


%Add read function
hdr_short.read_fcn = @(x,tmp)  vivimage_read(hdr,x,tmp{1},tmp{2});