function [header header_short] = xtekct_read(file)

%Reads information from *.xtekct files and the associated *.ctprofile.xml
%and _ctdata.txt files
%
% Written by Rob S Bradley (c) 2014

%Open file for reading
fid = fopen(file, 'r');
header.File = file;


%Loop over lines
eof = 0;
 
while ~eof

    str = fgetl(fid);
    
    if isempty(str)
        %Skip
        
    elseif strcmpi(str(1), '[')
         
        %Generate new sub header
        sub_hdr = str(2:end-1);        
    
    else
        
        %Separate name from value
        [name val] = strtok(str, '=');
        
        if numel(val)<2
            val = '';
            s = [];
        else
            val = val(2:end);
            
            %Test if value is a number or a string
            s = regexp(val(1), '\d', 'once');
        end
        
             
        if ~isempty(s)
           %Numerical value
           header.(sub_hdr).(name) = str2num(val);
           
        else
           %Text value
           header.(sub_hdr).(name) = val; 
        end    
    end    

    %test for eof 
    eof = feof(fid);
    
end

%Close fid
fclose(fid);


%Try loading associated CT profile if it exists
[d n] = fileparts(file);
try
    pro_file = [d '\' n '.ctprofile.xml'];
    header.CTProfile = xml_read(pro_file);
catch
end    
    
%Try loading associated ct angles
try
    ctdata_file = [d '\_ctdata.txt'];
    header.CTData = xtekctdata_read(ctdata_file);
catch
end  


%Create short header
header_short = [];


end