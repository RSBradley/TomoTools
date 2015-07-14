function hdr = amheader_create(file_name, data_size, data_type, voxel_size, encoding)


%Create header suitable for 1 variable in matrix form
hdr.File = file_name;
    
%Default file type
if nargin<5
    encoding = 'binary';
end  

switch encoding
    case 'binary'      
        hdr.FileType= 'BINARY-LITTLE-ENDIAN 2.1';
        info_str = [];
    case 'ascii'
        hdr.FileType= '3D ASCII 2.0';
        info_str = [];
    case 'rle'
        hdr.FileType= 'BINARY-LITTLE-ENDIAN 2.1';
        info_str = 'HxByteRLE,????????????';

        if strcmpi(data_type, 'uint8')
           error('AMHEADER_CREATE:data_type', 'Data type must be uint8 for RLE encoding'); 
        end
    case 'zip'
        hdr.FileType= 'BINARY-LITTLE-ENDIAN 2.1';
        info_str = 'HxZIP,????????????';
end

%Number of variables
hdr.NoOfVariables = 1;
    
%Assume uniform coordinate data
hdr.Variables.Lattice.Dimensions = data_size;
hdr.Variables.Lattice.Data.Value = '@1';
hdr.Variables.Lattice.Data.Info = info_str;
   
%Determine data type
switch data_type
     case 'uint8'           
        hdr.Variables.Lattice.Data.Datatype = 'byte';        
     case 'int16'
        hdr.Variables.Lattice.Data.Datatype = 'short';
                  
     case 'uint16'
        hdr.Variables.Lattice.Data.Datatype = 'ushort';   
                   
     case 'int32'
        hdr.Variables.Lattice.Data.Datatype = 'int';   
                   
     case 'single'
        hdr.Variables.Lattice.Data.Datatype = 'float';
        
     case 'double'
        hdr.Variables.Lattice.Data.Datatype = 'float64';   
end
    
    
%Determine parameters
%Content
str_tmp = num2str(data_size, '%ux');
hdr.Parameters.Content.Value = [strrep(str_tmp(1:end-1), ' ','') ' ' hdr.Variables.Lattice.Data.Datatype ', uniform coordinates'];
    
%Coordinate type
hdr.Parameters.CoordType.Value = 'uniform'; 
    
%Bounding Box
tmp = [zeros(1, numel(data_size)); (data_size-1).*voxel_size];
hdr.Parameters.BoundingBox.Value = tmp(:)';
    


end