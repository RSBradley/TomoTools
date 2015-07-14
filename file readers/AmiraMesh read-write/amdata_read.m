function data = amdata_read(hdr, n_variable)


%Read header if necessary
if ischar(hdr)
    
    hdr = amheader_read(hdr);
end

%Open file for reading
if isempty(hdr.FileIdentifier{1})
    
   fid = fopen(hdr.File, 'r'); 
else
    fid = hdr.FileIdentifier{1};
end    


%Check if to load full data
if nargin>1

    try
        data_region_len = hdr.DataLocations(n_variable,2);
        if data_region_len==0 & n_variable>1
            %Data_region has not been found for variable - load all
            %variables
            n_start = 1;
            n_end = size(hdr.DataLocations,1);
            
        else
           n_start = n_variable;
           n_end = n_variable;
        end    
    catch
       error('AMDATA_READ:var_not_found','AMDATA_READ: variable does not exist.');
    end 
    
else
    n_start = 1;
    n_end = size(hdr.DataLocations,1);
end            
 
%Determine file type
files_supported = {'ASCII', 'BINARY', 'BYTE-RLE', 'ZIP'};
ft = isempty(strfind(hdr.FileType, 'ASCII'))+1;

%Loop over variables to read data
%Determine location in hdr structure of each variable
expstrct = expand_structure(hdr.Variables, 'hdr.Variables', []);
val_inds = find(cellfun(@(x) ~isempty(x),  (strfind(expstrct(:,1), 'Value'))));
data = [];

for m = n_start:n_end

    
    %Find current variable information
    sub_strct = expstrct{val_inds(m),1}(1:end-6);
    
    %Move to start of data
    if hdr.DataLocations(m,3)>0
        %Use Data Locations if exist
        data_start = hdr.DataLocations(m,3);
    end    
    fseek(fid, data_start, 'bof');
   
    %Initialize data
    %f_ind = hdr.DataLocations(m,1:2);
    %fn_sub = fieldnames(hdr.Variables.(fn{f_ind(1)}));
    
    switch eval([sub_strct '.Datatype'])
        %hdr.Variables.(fn{f_ind(1)}).(fn_sub{f_ind(2)}).Datatype
        case 'byte'           
           bin_str = 'uint8';        
        case 'short'
           bin_str = 'int16';
                   
        case 'ushort'
           bin_str = 'uint16';    
                   
        case 'int'
           bin_str = 'int32';   
                   
        case 'float32'
           bin_str = 'single';
           
        case 'float'
           bin_str = 'single';   
    end
        
    %Use subsasgn to preallocate data variable
    substr = regexp(sub_strct(15:end), '\.', 'split');
    for ns = 1:numel(substr)
        S(ns).type = '.';
        S(ns).subs = substr{ns};
        
    end    
    
    sz = eval([sub_strct '.Dimensions']);
    if numel(sz)<2
        sz(2) = 1;
    end    
    data = subsasgn(data, S, zeros(sz, bin_str));
    
    
    %Read data
    is_rle = strfind(eval([sub_strct '.Info']), 'HxByteRLE');
    is_zip = strfind(eval([sub_strct '.Info']), 'HxZip');
    datatype = files_supported{sum([ft is_rle 2*is_zip])};
    
    
    
    switch datatype
        case 'ASCII'            
            read_ascii;
        case 'BINARY'            
            read_binary;
        case 'BYTE-RLE'            
            read_rle;
        case 'ZIP'
            read_zip;
    end        
    
    
    %Find start of next data_location
    tmp = fgetl(fid);
    if ~ischar(tmp);
        %EOF reached
        tmp = '@';
    end
    at_loc = strfind(tmp, '@');
    at_found = ~isempty(at_loc);
    t = 0;
    while ~at_found && t<10
         %Prob slow loop
         t = t+1;
         tmp = fgetl(fid);
         if ~ischar(tmp);
             %EOF reached
             tmp = '@';
         end    
         at_loc = strfind(tmp, '@');
         at_found = ~isempty(at_loc);            
    end
        
    data_start = ftell(fid);
    

end 
 
fclose(fid);

    
    function read_ascii

        %n_elem = prod(eval([sub_strct '.Dimensions']));
        %sub_strct
        S_final = S;
        ns1 = numel(S);
        S_final(ns1+1).type = '()';
        S_final(ns1+1).subs = {':'};
        tmp = fscanf(fid, '%f', eval([sub_strct '.Dimensions(end:-1:1)']));
        eval(['size(data.' sub_strct(15:end) ')'])
        tmp
        feof(fid)
        %S_final.type
        %S_final.subs
        data = subsasgn(data, S_final, tmp');
        %data.(sub_strct(15:end))(:) = fscanf(fid, '%f\n', n_elem);

    end

    function read_binary

        n_elem = prod(eval([sub_strct '.Dimensions']));
        S_final = S;
        ns1 = numel(S);
        S_final(ns1+1).type = '()';
        S_final(ns1+1).subs = {':'};
        data = subsasgn(data, S_final, fread(fid, n_elem, bin_str));
        %data.(sub_strct(15:end))(:) = fread(fid, n_elem, bin_str);

    end

    function read_rle

        %Only 8-bit rle supported
        tmp = fread(fid, hdr.DataLocations(m,5), '*uint8');
        
        %size(tmp)
        %pause
        S_final = S;
        ns1 = numel(S);
        S_final(ns1+1).type = '()';
        S_final(ns1+1).subs = {':'};
        %'RLE'
        data = subsasgn(data, S_final, rle_decode2(tmp, eval([sub_strct '.Dimensions']))); % CHANGED rle_decode to rle_decode2
        %data.(sub_strct(15:end))(:) = rle_decode(tmp, eval([sub_strct '.Dimensions']));

    end

    function read_zip

        %Start of data region
        pos = ftell(fid);
        
        %Open file stream with java for decoding
        fileInStream = java.io.FileInputStream(java.io.File(hdr.File));
        fileInStream.skip(pos);

        %Load unzipper
        jg = java.util.zip.InflaterInputStream(fileInStream);
        
        %Create output streem
        os = java.io.ByteArrayOutputStream;
        
        %Create stream copier
        isc = com.mathworks.mlwidgets.io.InterruptibleStreamCopier.getInterruptibleStreamCopier;
        
        %Do decoding
        isc.copyStream(jg,os);
        Q=typecast(os.toByteArray,'uint8');
        
        %Convert data
        S_final = S;
        ns1 = numel(S);
        S_final(ns1+1).type = '()';
        S_final(ns1+1).subs = {':'};
        data = subsasgn(data, S_final, typecast(Q, bin_str));
        %data.(sub_strct(15:end))(:) = typecast(Q, bin_str);
        
        
    end



end