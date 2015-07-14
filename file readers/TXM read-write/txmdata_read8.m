function data = txmdata_read8(foh, data_name, datatype, fmt)

% Reads data from Xradia files (*.xrm, *.txm, *.txrm).
%
%       data = txmdata_read3(foh, data_name)
%
% where
%       data = required data returned in a matrix or cell
%        foh = an Xradia file name or a header structure obtained using the matlab function
%              txmheader_read4.
%  data_name = name of data to be returned. This must be a field name in the
%              header structure. e.g. ImageInfo\Voltage or Voltage
%
% Written by: Rob Bradley, (c) 2015

%Check if header information is supplied

if ischar(foh)
   %foh is a file name
   %read header information
   header = txmheader_read8(foh); 
else
   header = foh;
end

%Check if full path is given for data name
sl_pos = strfind(data_name, '\');
if ~isempty(sl_pos)
    tmp = data_name;
    data_name = tmp(min(numel(data_name), sl_pos+1:end));
    data_path = tmp(1:sl_pos-1);
else
    data_path = [];
end    

%Check data_name is a fieldname in the header
if ~isfield(header.DataLocations, data_name)
    %Error if there is no header entry for requested image
    %i.e. image does not exist
    error([data_name ' does not exist.']);
    %return;
end    

%Determine data type
[info fmt_fns] = txmheader_info8(data_name);
if nargin<3
    %[info fmt_fns] = txmheader_info(data_name);
    %data_info = txmheader_info(data_name);
    datatype = info{2};
    fmt = info{4};
    %fmt_fns = fmt_fns_tmp;
end
tmp = regexp(datatype, '=', 'split');
datatype = tmp(1);

if isempty(data_path)
   data_path = header.DataLocations.(data_name){1};  
   data_name = header.DataLocations.(data_name){2};
end    
%%Check if file is already open
%if isempty(foh.FileIdentifier{1})
    
    %Open file for reading
%    fid = fopen(foh.File, 'r');
%else
%    fid = foh.FileIdentifier{1};
%end

%Read image
readdata;

%Close file if necessary
%if isempty(foh.FileIdentifier{1})
%    fclose(fid);
%end

formatdata;



    function readdata
        %function to read data from file
        if isempty(data_path)
            data = freadss1(header.File, {data_name}, datatype);
        else
            data = freadss1(header.File, {[data_path '\' data_name]}, datatype);            
        end
        data = data{1};        
    end
    
    function formatdata

    %Reformat data using info from txmheader_info
    %try
        %[info fmt_fns] = txmheader_info(data_name);
        %data = data{1};
        if ~isempty(fmt)
            %Formatting data is available
            %In this function header variable in header not hdr, so alter format
            %fmt_var = regexprep(info{4}(:,2), 'header', 'foh');
            %fmt_fn = cellfun(@eval,info{4}(:,1), 'UniformOutput', 0);
            
            %apply formatting
            n_fmts = size(fmt, 1);
            for n = 1:n_fmts
                %fmt{n,2:end}{:}
                %fmt{n,1}
                data = feval(fmt_fns.(fmt{n,1}), data, fmt{n,2}{:});
            end
        end    
    %catch
    %    warning(['No formatting for ' data_name ' was found']);
    %end

        %Formatting functions
     %   function data_out = resize(dims_str)
        
     %       data_dims = eval(dims_str);
     %       data_out = reshape(data(1:prod(data_dims)), data_dims);
        
     %   end
        
     %   function data_out = strextract(expr)
            
     %       data_out = regexp(data, expr, 'match');  
     %   end
    end
    
end