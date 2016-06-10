function [hdr hdr_short]= vglheader_read(file)


hdr.File = file;
hdr.FileName = [file(1:end-3) 'vol'];
hdr.FileIdentifier = {[], []};
hdr.FileContents = 'Reconstuction images';

info = {'Dimensions', 'GridSize.*vector4>', 'numeric';...
        'DataType', 'SampleDataType.*typeinfo>', 'char';...
        'PixelSize', 'SamplingDistance" >\s*<vector3>', 'numeric';...
        'PixelUnits', 'Length.*abbreviation=', 'char';...
        'DataRange', 'DataMappingRawRange.*float>', 'numeric'};
        

    
%gunzip file and load into a variable
fileInStream = java.io.FileInputStream(java.io.File(file));
gzipInStream = java.util.zip.GZIPInputStream( fileInStream );

import com.mathworks.mlwidgets.io.*
streamCopier = InterruptibleStreamCopier.getInterruptibleStreamCopier;

xmltmp = java.io.ByteArrayOutputStream;
streamCopier.copyStream(gzipInStream,xmltmp);
xmltmp = char(xmltmp);
xmltmp = regexprep(xmltmp, '[ ]+', ' ');

%Hack to extract relevent info
k = strfind(xmltmp, '<');
k1 = strfind(xmltmp, '>');
for n = 1:size(info,1)
    ind= regexpi(xmltmp, info{n,2});
    if numel(ind)>1
        ind = ind(end);
    end
    if strcmpi(info{n,2}(end), '>')
        curr_k = max(k(k<ind));
        curr_k1 = min(k1(k1>curr_k));
        item = strsplit(xmltmp(curr_k+1:ind));
        i_inds = strfind(xmltmp, ['</' item{1} '>']);
        curr_i = min(i_inds(i_inds>curr_k));
        valstr = strtrim(xmltmp(curr_k1+1:curr_i-1));
        valstr = strtrim(valstr);
        fs = strtrim(strsplit(regexprep(valstr, '<.*?>', ''), ' ', 'CollapseDelimiters',true));
  
    else
        curr_k1 = min(k1(k1>ind));
        tmp =  xmltmp(ind:curr_k1);
        ind = strfind(tmp, info{n,2}(end-3:end));
        tmp = strsplit(tmp(ind+4:end),' ');
        fs = tmp{1};
        
    end
    fs = strrep(fs, '"','');
    if strcmpi(info{n,3}, 'numeric')
       fs = cellfun(@str2num, fs);
    end
    if iscell(fs)
        fs = cell2mat(fs);
    end
    hdr.(info{n,1}) = fs;
    
    
    
end
hdr.DataType = lower(hdr.DataType);

%Create vgi header entries
[ph fn ex] = fileparts(hdr.FileName);
hdr.volume1.file1.name = [fn ex];
hdr.volume1.file1.fileformat = 'raw';
switch hdr.DataType
    case 'float'
        hdr.volume1.file1.bitsperelement = 32;
        hdr.BitDepth = 32;
    otherwise
        dg = regexp(hdr.DataType, '\d*', 'match');
        hdr.volume1.file1.bitsperelement = str2num(dg{1});
        hdr.BitDepth = str2num(dg{1});
end
hdr.volume1.file1.size = hdr.Dimensions(1:3);


%Create short header
hdr_short.File = [file(1:end-3) 'vol'];
hdr_short.FileContents = 'Reconstuction images';
hdr_short.ImageWidth = hdr.Dimensions(2);
hdr_short.ImageHeight = hdr.Dimensions(1);
hdr_short.NoOfImages = hdr.Dimensions(3);
hdr_short.DataType = hdr.DataType;
if strcmpi(hdr_short.DataType, 'float')
    hdr_short.DataType = 'single';
    hdr_short.DataRange = hdr.DataRange;
else
    hdr_short.DataRange = [eval([hdr_short.DataType '(0);']) eval([hdr_short.DataType '(inf);'])];
end

hdr_short.PixelSize = hdr.PixelSize;
hdr_short.PixelUnits = hdr.PixelUnits;
hdr_short.Units = hdr.PixelUnits;
hdr_short.read_fcn = @(x, tmp) vgivol_read(hdr, x);




end