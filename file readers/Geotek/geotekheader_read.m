function [header, header_short] = geotekheader_read(file)

fid = fopen(file, 'r');

%Check 1st 2 lines correspond to geotek format
tf1 =  strcmpi(fgetl(fid), 'Image Info');
tmp = fgetl(fid);
tf2 = strcmpi(tmp(1),'-');

if ~tf1 || ~tf2
    error('File is not in Geotek format.');    
end

header.File = file;
header_short.File = file;
header_short.FileContents = 'Projections';

%Short header data to copy
shnames = {'Core_ID', 'Section_Number', 'Section_Length', 'Core_depth';...
           'Core_ID', 'Section_Number', 'Section_Length', 'Core_depth'}; 

%loop over lines
tmp = fgetl(fid);
while ischar(tmp)
   tmp1 = regexp(tmp, '=', 'split');
   tmp2 = regexp(tmp1{1}, '(', 'split');
   LHS = regexprep(strtrim(tmp2{1}),' ', '_');
   LHS = regexprep(LHS,'-', '_');
   
   if numel(tmp1)>1
   header.(LHS) = tmp1{2};
   
   %find match
   sh_ind = find(strcmpi(LHS, shnames(1,:)));
   if ~isempty(sh_ind)
      header_short.(shnames{2,sh_ind}) = tmp1{2};
   end   
   end
   tmp = fgetl(fid);
end


%X-ray settings
header_short.Voltage = str2num(regexprep('X_ray_Voltage', '[a-z]',''));
header_short.Current = str2num(regexprep('X_ray_Current', '[a-z]',''));

%Exposure time
tmp = regexp(header.Detector_Mode, ' [1-10]* fps', 'match');
tmp1 = str2num(tmp{1}(1:end-3));
header_short.ExposureTime = 1/tmp1;

%Distances
%default units are cm
header_short.Units = 'cm';
header_short.PixelUnits = 'microns';
tmp = regexp(header.Source_Object_Distance, '[a-z]*', 'split');
header_short.R1 = str2num(tmp{1});

tmp = regexp(header.Source_Detector_Distance, '[a-z]*', 'split');
header_short.R2 = str2num(tmp{1})-header_short.R1;

header_short.PixelSize = 10000/str2num(header.Pixels_Per_CM);


%Find images
pth = fileparts(file);
[theader, th_short]= tiffstackheader_read([pth '\*.tif'],0,0);
header_short.ImageWidth = th_short.ImageWidth;
header_short.ImageHeight = th_short.ImageHeight;
header_short.NoOfImages = th_short.NoOfImages;
       
%Angles
ang_int = regexp(header.Angle_interval, '[a-z]', 'split');
ang_start = regexp(header.Start_angle, '[a-z]', 'split');

header_short.Angles = str2num(ang_start{1})+[1:header_short.NoOfImages]*str2num(ang_int{1});

%Data Type
header_short.DataType =th_short.DataType;
if isfield(th_short, 'DataRange')
       header_short.DataRange = th_short.DataRange;
else
    header_short.DataRange = [];
end

%Reference correction - done already
header_short.ApplyRef = 1;


%Add read function
header_short.read_fcn = @(x,tmp)  tiffstackimage_read(theader,x,tmp{1},tmp{2});

end