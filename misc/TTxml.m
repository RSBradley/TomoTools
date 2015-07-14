function [hdr, hdr_short] = TTxml(file)

% Function to read TTxml file format. The native file format of TomoTools.
% The format provides header information to link to data files (e.g. tiff
% stack).
%
% Written by: Rob Bradley, (c) 2015
%
%
% To do:
% 1. add write function


%Read xml header
hdr = xml_read(file);

%Check if file is a TTxml file
if ~isfield(hdr, 'FileType');
  throw_error;
end
if isempty(strfind(hdr.FileType, 'TTxml'))
    throw_error;
end

%Set read_fcn handle
switch hdr.Format
    case 'tiffstack'    
        %Read stack header info
        [theader, th_short]= tiffstackheader_read(hdr.File,0,0);
        
        %Check stack dimensions
        ddiff = [hdr.ImageWidth hdr.ImageHeight hdr.NoOfImages]-[th_short.ImageWidth th_short.ImageHeight th_short.NoOfImages];
        finds = find(ddiff~=0);
        if ~isempty(finds)
           warning('Size of images does not match that given in xml file. Using actual size');
           for n = 1:numel(finds)
              switch finds(1)
                  case 1
                      warning('Witdh of images does not match that given in xml file. Using actual size');
                      hdr.ImageWidth = th_short.ImageWidth;
                  case 2
                      warning('Height of images does not match that given in xml file. Using actual size');
                      hdr.ImageHeight = th_short.ImageHeight;
                  case 3
                      warning('No. of images does not match that given in xml file. Using actual number');
                      hdr.NoOfImages = th_short.NoOfImages;
              end
               
           end           
        end
        
        %add read function
        hdr.read_fcn = @(x,tmp)  tiffstackimage_read(theader,x,tmp{1},tmp{2});
        
        %add write function - TODO
    otherwise
        errordlg('TTxml format not currently supported');
        return;
end

%Required fields
if isfield(hdr, 'StackContents')
    hdr.FileContents = hdr.StackContents;
end
if isfield(hdr, 'VoxelSize')
    hdr.PixelSize = hdr.VoxelSize;
end

req_fields = {'FileContents', 'ImageWidth', 'ImageHeight', 'NoOfImages', 'DataType', 'PixelSize', 'Units'};
check_req_fields;
if ~isfield(hdr, 'PixelUnits')
    hdr.PixelUnits = hdr.Units;
end


hdr_short = hdr;

    %Error
    function throw_error(missing)
        if nargin<1
            error('File does not conform the the TTxml standard.');
        else
            error(['Missing field: ' missing '.']);
        end
    end
    function check_req_fields
       for nm = 1:numel(req_fields)
            if ~isfield(hdr,req_fields{nm})
                throw_error(req_fields{nm});
            end            
       end
    end


end