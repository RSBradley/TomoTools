function hdr = amheader_read(file, load_data_loc)


%Check whether to determine data locations
if nargin<2
    load_data_loc = 0;
end 

buffer_sz = 10*256*1024*1024/32; %values

%Keywords
Keywords = {'define';'Parameter';'Material'};

%Datatypes
Datatypes = {'float', 'int', 'byte', 'ushort'};
data = [];

%Select file if no inputs
if nargin<1
    [filename path]= uigetfile('*.vgi');
    if filename==0
        hdr =[];
        return;
    end
    
    file = [path filename];
end    


%Open file for reading
fid = fopen(file);

%Check file type
File_ID = fgetl(fid);

try
    TF = strcmp(File_ID(1:11), '# AmiraMesh');
    TF1 = strcmp(File_ID(1:7), '# Avizo');

    if ~TF & ~TF1
        error('AMread_error', 'File is not in AmiraMesh format');
    end
catch    
    error('AMread_error', 'File is not in AmiraMesh format');
end    
    
%Create hdr
hdr.File = file;
hdr.FileIdentifier = {[],[]};

if TF1
    k = strfind(File_ID, '3D');
    
    if ~isempty(k)
        hdr.FileType = File_ID(k+4:end);
    
    else
        hdr.FileType = File_ID(9:end);
    end
else

    hdr.FileType = File_ID(13:end);
end

hdr.NoOfVariables = 0;


%Loop through lines
stop=0;
while ~stop
    
    txt = strtrim(fgetl(fid));
    
    parse_txt=0;
    if numel(txt)>0
        parse_txt = 1;
        if strcmp(txt(1), '@')
            %Data section reached
            hdr.DataStart = ftell(fid);
            parse_txt = 0;
            stop = 1;
        end    
    end
    
    if strcmp(txt, '#');
        parse_txt = 0;
    end    
    
    if parse_txt
        
        %Determine line contents
        test = (cellfun(@(x) strfind(txt,x), Keywords, 'UniformOutput', 0));
        ind = find(cellfun(@(x) ~isempty(x), test),'1');       
        
        if isempty(ind)
            ind = 0;
        end
        switch ind
            case 1
                %Variable Definition
                %split txt on spaces
                s = regexp(txt, ' ', 'split');
                
                %Add name to header with dimensions
                %s(3:end)
                hdr.Variables.(s{2}).Dimensions = cellfun(@str2num, s(3:end));
                
                %Add name to keywords
                Keywords = {Keywords{:}, s{2}}; 
                                
            case 2
                
                
                %Parameter Definition
                str_name = 'hdr.Parameters';
                get_bracket_data(str_name);                
                
            case 0
                %do nothing
                
            
            otherwise
                %data related to variable
                %data = get_bracket_data(txt);
                str_name = ['hdr.' Keywords{ind}];
                get_bracket_data(str_name);
                % hdr.Keywords{ind} = get_bracket_data(txt);
                
        end    
            
    end        
end

%Copy info to Variables field
fn = fieldnames(hdr.Variables);

for m = 1:size(fn,1)
    %do_stop = 0;
    strct = ['hdr.' fn{m}];
        
    %change structure to cell list
    expstrct = expand_structure(eval(strct), strct, []);

    %find all items with a Value fieldname
    val_inds = find(cellfun(@(x) ~isempty(x),  (strfind(expstrct(:,1), 'Value'))));

    %Check if dimensions already exist for this variable
    if isfield(hdr.Variables.(fn{m}), 'Dimensions')
        dims = hdr.Variables.(fn{m}).Dimensions;
    else
        dims = [];
    end    
        
        
        
    for k = 1:numel(val_inds)
         
        
        sub_strct = expstrct{val_inds(k),1}(1:end-6);
        %sub_strct = curr_strct(1:end-6);
        
        %fn_strct = curr_strct(str
        
        
        %find all occurences of sub_strct
        sub_inds = find(cellfun(@(x) ~isempty(x),  (strfind(expstrct(:,1), sub_strct))));    
        
        
        %fn_sub = eval(['fieldnames(' sub_strct ');'])
        
        for p = 1:numel(sub_inds)
            
            val = expstrct{sub_inds(p),2};
            
            %Add dimensions defined above
            if strfind(expstrct{sub_inds(p),1}(5:end), 'Dimensions')
               val = [dims val];
            end
            
            switch class(val)
                 case 'cell'                   
                   
                    eval(['hdr.Variables.' expstrct{sub_inds(p),1}(5:end) '= cell2mat(val);']);
                    %hdr.Variables.(fn{m}).(fn_sub{1}).(fn_final{k}) = cell2mat(val); 
                      
                 case 'char'
                        
                     try 
                         if strcmp(val(1), '(')
                          val = val(2:end-1);
                         end
                     catch
                     end    
                     eval(['hdr.Variables.' expstrct{sub_inds(p),1}(5:end) '= val;']);
                          
                 otherwise
                     eval(['hdr.Variables.' expstrct{sub_inds(p),1}(5:end) '= val;']);
            end
            
        end
    end    
end


%Loop over variables to find data regions
fn = fieldnames(hdr.Variables);

%Determine filetype
ft = strfind(hdr.FileType, 'ASCII');
data_start = hdr.DataStart;
hdr.DataLocations = zeros(hdr.NoOfVariables,5);

%Find all variables with data locations
expstrct = expand_structure(hdr.Variables, 'hdr.Variables', []);
net_strct = expstrct(cellfun(@(x) ~isempty(x),  strfind(expstrct(:,1), 'Value')),:);



for ind = 1:hdr.NoOfVariables

    %Strip out current variable
    comp_str = ['@' num2str(ind)];
    
    sub_inds = find(strcmpi(net_strct(:,2), comp_str));
    if isempty(sub_inds)
        break;    
    end
    
    
    %Check if info exists for this variable
    if ~isfield(eval(net_strct{sub_inds,1}(1:end-6)), 'Info')
        eval([net_strct{sub_inds,1}(1:end-6) '.Info = []']);
    end
    
        
    %Store information in data locations
    hdr.DataLocations(ind,1) = sub_inds;
    hdr.DataLocations(ind,2) = 0;
    hdr.DataLocations(ind,3) = data_start;
    
    %Locate variable dimensions
    hdr.DataLocations(ind,4) = prod(eval([net_strct{sub_inds,1}(1:end-6) '.Dimensions;']));
    
    %hdr.DataLocations(ind,4) = prod(hdr.Variables.(fn{q}).Dimensions);
    
    if isempty(ft)
         %BINARY FILE
         %determine if rle encoded
         is_rle = strfind(eval([net_strct{sub_inds,1}(1:end-6) '.Info']), 'HxByteRLE');
         is_zip = strfind(eval([net_strct{sub_inds,1}(1:end-6) '.Info']), 'HxZip');

         if is_rle
             %uint8 format supported only
             %Number of bytes taken by data
             [tok remain] = strtok(eval([net_strct{sub_inds,1}(1:end-6) '.Info']), ',');
              hdr.DataLocations(ind,5) = str2num(remain(2:end));
              
         
         elseif is_zip
                 [tok remain] = strtok(eval([net_strct{sub_inds,1}(1:end-6) '.Info']), ',');
                  hdr.DataLocations(ind,5) = str2num(remain(2:end));
         
         else
            %Normal binary
            switch eval([net_strct{sub_inds,1}(1:end-6) '.Datatype'])
               case 'byte'
                  n_bytes = 1; 
                   
               case 'short'
                   n_bytes = 2;
                   
               case 'ushort'
                   n_bytes = 2;    
                   
                case 'int'
                   n_bytes = 4;   
                   
               case 'float'
                   n_bytes = 4; 
            end
            
            hdr.DataLocations(ind,4) =  prod(eval([net_strct{sub_inds,1}(1:end-6) '.Dimensions']))*n_bytes;
         end
         
         if load_data_loc
             
            fseek(fid, data_start+hdr.DataLocations(ind,4), 'bof');
             
         end
    else
        %ASCII file        
        if load_data_loc
           %Determine length of data region
           nvals = prod(eval([net_strct{sub_inds,1}(1:end-6) '.Dimensions']));
           
           loop_n = floor(nvals/buffer_sz);
           
           for k = 1:loop_n
              tmp = fscanf(fid, '%u\n',buffer_sz);               
           end
           
           rem_sz = nvals-buffer_sz*loop_n;
           %tmp = fread(fid,rem_sz,'%uint8\n');
           tmp = fscanf(fid,'%s\n',rem_sz); 
           
            
           hdr.DataLocations(ind,4) = ftell(fid);
           
        end     
    end    
      
    %Find data regions
    if load_data_loc
    
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
    
    

end 


fclose(fid);



 function get_bracket_data(struct_name)
     
     txt = strtrim(txt);
     if ~strfind(txt, '{');
         eval(['hdr' struct_name '=[];']);
         return;
     end    
     
     if ~numel(txt)>1
        eval(['hdr' struct_name '=[];']);
        return;    
     end 
     
     
     if strfind(txt, '}')
        
         %'Single' 
        %Single line data 
        lim1 = strfind(txt, '{');
        lim2 = strfind(txt, '}');
        
        try
            tmp = strtrim([txt(lim1+1:lim2-1) txt(lim2+1:end)]);
        catch
            tmp = strtrim(txt(lim1+1:lim2-1));
         
        end  
        
        %MAYBE NEED TO REPLACE MULTIPLE BLANKS WITH 1
        
        t = regexp(tmp, ' ', 'split');
        %txt(lim1+1:lim2-1)
        %t
        %Check if 1st value in t denotes datatype
        test = strncmp(t{1}, Datatypes,3);
        %test
        %sum(test)
        n_name = 1;
        
        if sum(test)
            n_name = 2;
            %t{n_name}
            %s
            %struct_name = [struct_name '.' t{n_name}];
            eval([struct_name '.' t{n_name} '.Datatype =  Datatypes(find(test,1));']);
            %data_out.(t{2}).(t{n_name}).Datatype = Datatypes(find(test,1));
            
            lim1 = strfind(txt, '[');
            lim2 = strfind(txt, ']');
            
            eval([struct_name '.' t{n_name} '.Dimensions = str2num(txt(lim1:lim2));']);
            %data_out.(t{1}).(t{n_name}).Dimensions = str2num(txt_in(lim1:lim2));
            
        end
        
        
        if ~isempty(strfind(txt, '"')) 
            %string data
             lims = strfind(txt, '"');
             try
             eval([struct_name '.' t{n_name} '.Value = txt(lims(1)+1:lims(2)-1);']);
             catch
             end
             %data_out.(t{2}).(t{n_name}).Value = txt(lims(1):lims(2));
        elseif ~isempty(strfind(txt, '@')) 
            
             lims = strfind(txt, '@');
             
             %find end limit of number
             still_no = 1;
             n_extra = 0;
             while still_no
                n_extra = n_extra+1;
                
                if lims(1)+n_extra>numel(txt)
                    still_no=0;
                    %n_extra = n_extra+1;
                
                elseif isempty(str2num(txt(lims(1)+n_extra)));
                   still_no=0; 
                end    
                 
             end    
             n_extra = n_extra-1;
            
             
             hdr.NoOfVariables = max([hdr.NoOfVariables str2num(txt(lims(1)+1:lims(1)+n_extra))]);
             
             
             try
                 eval([struct_name '.' t{n_name} '.Value = txt(lims(1):lims(1)+n_extra);']);
                 eval([struct_name '.' t{n_name} '.Info = txt(lims(1)+n_extra+2:end-1);']);
             catch
                 
             end   
            
        else    
             %numerical data
             %[struct_name '.' t{n_name} '.Value = cellfun(@str2num, t(n_name+1:end))']
             %struct_name
             %[struct_name '.' t{n_name} '.Value = cellfun(@str2num, t(n_name+1:end));']
             try
             eval([struct_name '.' t{n_name} '.Value = cellfun(@str2num, t(n_name+1:end));']);
             catch
             end
             %data_out.(t{2}).(t{n_name}).Value = cellfun(@str2num, t(n_name+1:end));
                    
        end  
         
     else    
        %Multi line data
        %'Multi'
        
        br_end = 0;
        while ~br_end
            txt = fgetl(fid);
            try
                txt = strtrim(txt);
            catch
                 txt = '}';
            end
            
            try
                br_test = strcmp(txt(1), '}');
            catch
                br_test = 1;
            end  
            
            
            if br_test
                %end of bracketed data section detected
                br_end = 1;
                
            else
                
                %variable detected - add to data structure
                
                %Remove end comma as necessary
                if strcmp(txt(end), ',');
                    txt = txt(1:end-1);
                end    
                
                %split txt on spaces
                s = regexp(txt, ' ', 'split');
                
                
                if strfind(txt, '{')
                     
                    struct_name1 = [struct_name '.' s{1}];
                    %struct_name1
                    get_bracket_data(struct_name1);
                else
                     
                    txt = ['{' txt '}'];
                    get_bracket_data(struct_name);
                end    
                    %data within data
                %data_out = txt_in;
                    %Add name to data
                %if strfind(txt, '{')
                    %data within data'
                    
                %elseif ~isempty(strfind(txt, '"')) 
                    %string data
                %    lims = strfind(txt, '"');
                %    data.(s{2}) = txt(lims(1):lims(2));
                %else
                    %numerical data
                %    data.(s{2}) = cellfun(@str2num, s(3:end));
                    
                %end    
            end    
                
                
                
              %data  
                
            
            
        end
     end

 end


    function  rle_datalocations
        
        
       
        
        
    end   


end