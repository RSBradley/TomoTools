function [hdr hdr_short]= vgiheader_read(file)


%Open file for reading
fid = fopen(file);

%Create hdr
hdr.File = file;
hdr.FileName = [file(1:end-3) 'vol'];
hdr.FileIdentifier = {[], []};

primary_hdr = [];
secondary_hdr = [];

%Loop through lines
while ~feof(fid)
    txt = fgetl(fid);
    if numel(txt)>0    
        switch txt(1)
            case '{'
             %Primary header information
                primary_hdr = lower(txt(2:end-1));
                hdr.(primary_hdr) = [];
            
             case '['
                %Secondary header
                if isempty(primary_hdr)
                    primary_hdr = 'fields';
                end
                secondary_hdr = lower(txt(2:end-1));
                secondary_hdr = strrep(secondary_hdr, ' ','_');
                hdr.(primary_hdr).(secondary_hdr) = {};
            
            otherwise
                %Read in name and value
                ind = find(txt =='=');
                name = lower(txt(1:ind-1));
            
                %Remove all spaces from name
                sp_inds = isspace(name);
                name = name(~sp_inds);
                name = strrep(name, '-','_');
                name = strrep(name, '|','_');
                val = txt(ind+1:end);
                val_num = str2num(val); %#ok<ST2NM>
                if isempty(val_num)
                    hdr.(primary_hdr).(secondary_hdr).(name) =  strtrim(val);
                else
                    hdr.(primary_hdr).(secondary_hdr).(name) = val_num;
                end 
        end     
    end        
end

%Create short info
try
hdr_short.File = [file(1:end-3) 'vol'];
hdr_short.FileContents = 'Reconstuction images';
sz = hdr.volume1.file1.size;
hdr_short.ImageWidth = sz(2);
hdr_short.ImageHeight = sz(1);
hdr_short.NoOfImages = sz(3);
hdr_short.DataType = [hdr.volume1.file1.datatype num2str(hdr.volume1.file1.bitsperelement)];
if strcmpi(hdr_short.DataType, 'float32')
    hdr_short.DataType = 'single';
end
hdr_short.DataRange = hdr.volume1.file1.datarange;
hdr_short.PixelSize = hdr.volumeprimitive1.geometry.resolution(1);
hdr_short.PixelUnits = hdr.volumeprimitive1.geometry.unit;
hdr_short.Units = hdr.volumeprimitive1.geometry.unit;
hdr_short.read_fcn = @(x, tmp) vgivol_read(hdr, x);
catch
end

end