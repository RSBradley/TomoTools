function hdr = xtekctdata_read(file)

% Written by Rob S Bradley (c) 2014

%Open file for reading
fid = fopen(file, 'r');

%1st line is title
tmp = fgetl(fid);

%2nd line is summary info
tmp = str2num(fgetl(fid));

hdr.NoOfProjections = tmp(1);
hdr.FramesPerProjection = tmp(2);
hdr.ExposureTime = tmp(3);

%Get data
tmp = regexp(fgetl(fid), '\s', 'split');
hdr.ProjectionInfo{1} = tmp;
tmp = textscan(fid, '%f %f %f');
hdr.ProjectionInfo{2} = cell2mat(tmp);

fclose(fid);

end