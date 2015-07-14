function [header header_short]= txmheader_read8(file)


% Reads header information from Xradia files (*.txrm, *.xrm, *.txm')
%
%       hdr = txmheader_read8(file)
%
% where
%       hdr = structure of header data (including number of images etc)
%      file = full path name of the Xradia file
%
% Written by: Rob Bradley, (c) 2015


%Initialise header
header.File = file;
header.FileIdentifier = {'Open'};
header.DataLocations = [];
header_short = [];

warning off

%Create description of file contents based on file type
pt_ind = findstr(file, '.');
file_type = file(pt_ind(end)+1:end);
switch file_type
    case 'txrm'
        header.FileContents = 'Projection images';
    case 'xrm'
        header.FileContents = 'Projection image';
    case 'txm'
        header.FileContents = 'Reconstruction images';
end        

%Get header data names and properties            
[float_props fmt_fns aqmodekey] = txmheader_info8;

%Loop through header structure and read some data
curr_names = freadss1(file, {''});
expand_storage(curr_names, '');

%Create short info
header_short.File = header.File;
header_short.FileContents = header.FileContents;
shnames = {'Voltage', 'Current', 'OpticalMagnification', 'PixelSize', 'ImageWidth', 'ImageHeight', 'NoOfImages', 'DataType'}; 
%fnames = fieldnames(header.DataLocations);

for k = 1:numel(shnames)
    %ind = find(strcmpi(shnames{i}, fnames));
    
    %try
        %shnames{k}
        %header.DataLocations
        fpath = strrep(header.DataLocations.(shnames{k}){1}, '\', '.');
        
        eval(['header_short.' shnames{k} '= header.' fpath '.' shnames{k} ';']);
    %catch
    %    header_short.(shnames{i}) = [];
    %end   
%header_short.Current = header.Current;
%header_short.OpticalMagnification = header.OpticalMagnification;
%header_short.PixelSize = header.PixelSize;
%header_short.ImageWidth = header.ImageWidth;
%header_short.ImageHeight = header.ImageHeight;
%header_short.NoOfImages = header.NoOfImages;
%header_short.DataType = header.DataType;
end

%Update data type to matlab classes
switch header_short.DataType
      case 3
         header_short.DataType = 'uint8';
      case 5
         header_short.DataType = 'uint16';
      case 10
         header_short.DataType = 'single';
end

%Set defaults for ff and rotby90
header_short.ApplyRef = 0;
header_short.RotBy90 = 1;

%Units
header_short.PixelUnits = 'microns';
header_short.Units = 'mm';

%load reference correction if necessary
if strcmpi(header.FileContents(1), 'P')
    header_short.ApplyRef = 1;  
     try
        tmp = txmimage_read8(header,[],0,0);         
        tmp{1} = 1./single(tmp{1});
        header.ReferenceData.Image = tmp;
      catch
          %No reference data
          header_short.ApplyRef = 0;
      end
      header_short.Angles = txmdata_read8(header,'Angles');
      header_short.R1 = txmdata_read8(header,'ImageInfo\StoRADistance');
      header_short.R1 = abs(header_short.R1(1));
      header_short.R2 = txmdata_read8(header,'ImageInfo\DtoRADistance');
      header_short.R2 = abs(header_short.R2(1));
      try
        %Shofts not applicable for averaging mode  
        header_short.Shifts = [txmdata_read8(header, 'X_Shifts'), txmdata_read8(header, 'Y_Shifts')]; 
      catch
         header_short.Shifts = []; 
      end
      %Overwrite function - disable rot90 and flat field
      header_short.write_fcn = @(im, nim) txmimage_write8(header, nim, im, 0,0);
end

%create read function
header_short.read_fcn = @(x, tmp) txmimage_read8(header, x, tmp{1}, tmp{2});

%create header export function
header_short.hdr2xml_fcn = @(x) txmhdr2xml8(header, 'full', x);

try
    fpath = strrep(header.DataLocations.GlobalMin, '\', '.');
    d1 = header.(fpath).GlobalMin;
    fpath = strrep(header.DataLocations.GlobalMax, '\', '.');
    d2 = header.(fpath).GlobalMax;
    header_short.DataRange = [d1 d2];
catch
    header_short.DataRange = [];
end 
header_short.OutputOrder = -1;

warning on


    function expand_storage(names, root)

%if nargin<3
   
%    expstrct = {[],[]};

%end
    %expstruct
    if iscell(names)
        names  = names{1};
    end
    if iscell(root)
        root = root{1};
    end
    
    for i=1:length(names)
        %names{i}
        is_storage = strcmpi(names{i}(1), '\');
        if is_storage
            curr_path = [root names{i}];
            if strcmpi(curr_path(1), '\');
                curr_path = curr_path(2:end);
            end   
            sub_names = freadss1(file, {curr_path});
            expand_storage(sub_names, {curr_path});           
        else
            
            name_ind = find(strcmpi(names{i}, float_props(:,1)));
                        
            if isempty(name_ind)
              if numel(root)>0
                        %tmp = freadss11(file, {[root '\' names{i}]}, fmt);
                        %tmp = tmp{1};
                        modifiedStr = modify_path(root);
                        %modifiedStr = strrep(root, '\', '.')
                        modifiedname = modify_name(names{i});
                        
                        %pause
                        %['header.' modifiedStr '.' modifiedname '=' '''Obtain using txmdata_read'';']
                        eval(['header.' modifiedStr '.' modifiedname '=' '''Obtain using txmdata_read'';']);
                        nc = 1;
                        if isfield(header.DataLocations, modifiedname)
                            nc = size(header.DataLocations.(modifiedname),1)+1;                           
                        end                            
                        header.DataLocations.(modifiedname){nc, 1} = root;
                        header.DataLocations.(modifiedname){nc, 2} = names{i};
                        %expstrct.(root).(names{i}) = freadss11(file, {[root '\' names{i}]}, fmt)
                    
              else
                       %expstruct.(names{i}) = freadss11(file, {[root '\' names{i}]}, fmt);
                        modifiedname = modify_name(names{i});
                        header.(modifiedname) = 'Obtain using txmdata_read';
                        
                        nc = 1;
                        if isfield(header.DataLocations, modifiedname)
                            nc = size(header.DataLocations.(modifiedname),1)+1;                            
                        end
                        header.DataLocations.(modifiedname){nc,1} = '';
                        header.DataLocations.(modifiedname){nc,2} = names{i};
              end 
            else
                load_data = isempty(float_props{name_ind,4});
                
                if load_data
                    fmt = regexp(float_props(name_ind,2), '=','split');
                    fmt = fmt{1}(1);  
                    if numel(root)>0
                        
                        tmp = freadss1(file, {[root '\' names{i}]}, fmt);
                        tmp = tmp{1};
                        modifiedStr = modify_path(root);
                        %modifiedStr = strrep(root, '\', '.');
                        modifiedname = modify_name(names{i});
                        %pause
                        eval(['header.' modifiedStr '.' modifiedname '=tmp;']);
                        
                        nc = 1;
                        if isfield(header.DataLocations, modifiedname)
                            nc = size(header.DataLocations.(modifiedname),1)+1;                           
                        end                            
                        header.DataLocations.(modifiedname){nc, 1} = root;
                        header.DataLocations.(modifiedname){nc, 2} = names{i};
                        %expstrct.(root).(names{i}) = freadss11(file, {[root '\' names{i}]}, fmt)
                    
                    else
                        %numel(root)
                        %pause
                        modifiedname = modify_name(names{i});
                        
                        header.(names{i}) = freadss1(file, names(i), fmt);
                        
                        
                        nc = 1;
                        if isfield(header.DataLocations, modifiedname)
                            nc = size(header.DataLocations.(modifiedname),1)+1;                            
                        end
                        header.DataLocations.(modifiedname){nc,1} = '';
                        header.DataLocations.(modifiedname){nc,2} = names{i};
                    end    
                        %names{i}
                    %pause
                else
                    if numel(root)>0
                        %tmp = freadss11(file, {[root '\' names{i}]}, fmt);
                        %tmp = tmp{1};
                        modifiedStr = modify_path(root);
                        %modifiedStr = strrep(root, '\', '.');
                        %modifiedname = strrep(names{i}, '-', '_');
                        modifiedname = modify_name(names{i});
                        %pause
                        
                        
                       nc = 1;
                        if isfield(header.DataLocations, modifiedname)
                            nc = size(header.DataLocations.(modifiedname),1)+1;                           
                        end                            
                        header.DataLocations.(modifiedname){nc, 1} = root;
                        header.DataLocations.(modifiedname){nc, 2} = names{i};
                        
                        if strfind(float_props{name_ind,2}, 'char');
                            tmp = txmdata_read8(header, [modifiedStr '\' modifiedname]);
                            eval(['header.' modifiedStr '.' modifiedname '= tmp;']);                           
                        else
                            eval(['header.' modifiedStr '.' modifiedname '=' '''Obtain using txmdata_read'';']);
                        end
                        %expstrct.(root).(names{i}) = freadss11(file, {[root '\' names{i}]}, fmt)
                    
                    else
                        %expstruct.(names{i}) = freadss11(file, {[root '\' names{i}]}, fmt);
                        modifiedname = modify_name(names{i});
                        %modifiedname = strrep(names{i}, '-', '_');
                        header.(modifiedname) = 'Obtain using txmdata_read';
                        
                        
                        nc = 1;
                        if isfield(header.DataLocations, modifiedname)
                            nc = size(header.DataLocations.(modifiedname),1)+1;                            
                        end
                        header.DataLocations.(modifiedname){nc,1} = '';
                        header.DataLocations.(modifiedname){nc,2} = names{i};
                    end 
                    
                    
                end
            end
        end


    end
 
    end



    function mn = modify_name(name)

        mn = regexprep(name, '[. \\ \s -]', '_');
        if double(mn(1))<65
            mn = ['fn' mn];
        end
    
        
    end


    function mp = modify_path(cp)

        mp = regexprep(cp, '[. \s -]', '_');
        mp = strrep(mp, '\', '.');
        mp = strrep(mp, ' ', '');
    end    
end
