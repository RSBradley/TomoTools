function hdr = amdata_write(hdr, data, VoxelSize)


%Check if header exists
if ischar(hdr)
    %Assume data is a matrix
    hdr = amheader_create(hdr, size(data), class(data), VoxelSize, 'binary');
    tmp = data;
    data = [];
    data.Data = tmp;    
end


%Write data
%Open file
fid = fopen(hdr.File, 'w');

%Write file type
fprintf(fid, ['# AmiraMesh ' hdr.FileType '\n\n']);


%Write variable dimensions
fn = fieldnames(hdr.Variables);
n_names = size(fn,1);

for m = 1:n_names   
   fprintf(fid, ['define ' fn{m} ' ' sprintf('%u ',hdr.Variables.(fn{m}).Dimensions) '\n']);    
end

fprintf(fid, '\n\n');

%Write out parameters
param_str = 'Parameters {\n|ip|\n}';
n_blanks = 4;
curr_obj = hdr.Parameters;
depth = 0;
output_str = get_format_str(curr_obj, param_str,depth, 0);
fprintf(fid, output_str);


%Write out variable info
fprintf(fid, '\n\n');
for m = 1:n_names
    fn_sub = fieldnames(hdr.Variables.(fn{m}));
    
    for k = 1:size(fn_sub,1)
        
        obj = hdr.Variables.(fn{m}).(fn_sub{k});        
        if isstruct(obj)
           
            if isfield(obj, 'Dimensions') && ~isempty(obj.Dimensions)
                if numel(obj.Dimensions)>1
                    Dim_str = ['[' num2str(obj.Dimensions(end)) ']'];
                else
                    Dim_str = [];
                end
            else
                Dim_str = [];
            end
            
           str = [fn{m} ' { ' obj.Datatype Dim_str ' ' fn_sub{k} ' } ' obj.Value];
           obj
           if ~isempty(obj.Info)
               tmp = [str '(' obj.Info ')']; 
               str = tmp;
           end    
           fprintf(fid, [str '\n']);
        end
    end
end


%Write out data
ft = strfind(hdr.FileType, 'ASCII');
for m = 1:n_names
    fn_sub = fieldnames(hdr.Variables.(fn{m}));
    
    for k = 1:size(fn_sub,1)
        
        obj = hdr.Variables.(fn{m}).(fn_sub{k});
        if isstruct(obj)
           fprintf(fid, ['\n\n' obj.Value '\n']);
           write_data(fn_sub{k}, obj.Datatype, obj.Info);
        end
    end
end


fclose(fid);


    function write_data(name, data_type, encoding)
       
        if ft
           %ASCII encoding
           %Determine format
           switch data_type
                case 'byte'           
                    format_str = '%hu';        
                case 'short'
                    format_str = '%hi';
                  
                case 'ushort'
                    format_str = '%hu';   
                   
                case 'int'
                    format_str = '%u ';
                   
                case 'float32'
                    format_str = '%tu';
                    
                case 'float'
                    format_str = '%5.15E ';
        
                case 'float64'
                    format_str = '%bu';
           end
            %Write data
            format_str = [repmat(format_str, [1 size(data.(name),2)]) '\n'];
            fprintf(fid, format_str, data.(name)');
            
        else
            %BINARY format 
            is_rle = strfind(encoding, 'HxByteRLE');
            is_zip = strfind(encoding, 'HxZip');
            
            switch data_type
                  case 'byte'           
                     bin_str = 'uint8';        
                  case 'short'
                     bin_str = 'int16';                   
                  case 'ushort'
                     bin_str = 'uint16';                   
                  case 'int'
                    bin_str = 'int32';                   
                  case 'float'
                    bin_str = 'single';
                  case 'float64'
                    bin_str = 'double';
            end
            
            
            if is_rle
                %Currently not supported
            elseif is_zip
                %Currently not supported
            else
                %No encoding
                fwrite(fid, data.(name), bin_str); 
            end
            
        end    
        
        
        
        
        
    end   






    function param_str = get_format_str(curr_obj, param_str,depth, islast)

        
        fn_param = fieldnames(curr_obj);
        
        n_child = size(fn_param,1);
                
        for n = 1:n_child
            curr_depth = depth+1;
    
            %Determine if current object contains substructures
            if ~isstruct(curr_obj.(fn_param{n})) || strcmpi(fn_param{n}, 'Value')
                %No sub structures
                val = curr_obj.(fn_param{n});
                if isnumeric(val);
                    val = strtrim(sprintf('%g ',val));
                else
                    tmp = ['"' val '"'];
                    val = tmp;
                end    
                
                if strcmpi(fn_param{n}, 'Value')
                    nm_str = '';
                    blnk_str = '';
                else
                    
                   nm_str = fn_param{n};
                   blnk_str = repmat(' ',1,curr_depth*n_blanks);
                end    
                
                %Find insertion point
                %n
                %param_str
                ip = strfind(param_str, '|ip|');
                ip = ip(1);
                
                if ~islast
                    %Do comma & keep insertion point 
                    curr_str = [blnk_str nm_str '' val ',\n|ip|'];                   
                else
                    %Omit comma
                    curr_str = [blnk_str nm_str '' val ''];
                end   
                
                %Length of new string
                str_len = length(param_str)+length(curr_str)-4;
                
                %Insert new string
                output_str = repmat(' ', 1, str_len);
                output_str(1:ip-1) = param_str(1:ip-1);
                output_str(ip:ip+length(curr_str)-1) = curr_str;
                output_str(ip+length(curr_str):end) = param_str(ip+4:end);
                
                param_str = output_str;
                
            else
                %Insert open brackets
                %param_str
                ip = strfind(param_str, '|ip|');
                ip = ip(1);
                blnk_str = repmat(' ',1,curr_depth*n_blanks);
                
                ch_fn = fieldnames(curr_obj.(fn_param{n}));
                
                if size(ch_fn,1)==1 && strcmpi(ch_fn{1}, 'Value')
                    
                    curr_str = [blnk_str fn_param{n} ' |ip|'];
                
                else
                    if islast || n==n_child
                        curr_str = [blnk_str fn_param{n} ' {\n|ip|\n' blnk_str '}'];                        
                    else
                        curr_str = [blnk_str fn_param{n} ' {\n|ip|\n' blnk_str '}\n|ip|'];
                    end   
                end
                
                %Length of new string
                str_len = length(param_str)+length(curr_str)-4;
                
                %Insert new string
                output_str = repmat(' ', 1, str_len);
                output_str(1:ip-1) = param_str(1:ip-1);
                
                output_str(ip:ip+length(curr_str)-1) = curr_str;  
                output_str(ip+length(curr_str):end) = param_str(ip+4:end);
                
                param_str = output_str;
                               
                %Recursive call to this function
                curr_obj_new = curr_obj.(fn_param{n});
                param_str = get_format_str(curr_obj_new, param_str,curr_depth, n==n_child);
                
            end
            
            
        end    
    end




end
