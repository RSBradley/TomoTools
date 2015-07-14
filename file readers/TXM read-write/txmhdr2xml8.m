function txmhdr2xml8(hdr, mode, dir_loc)

% TXMHDR2XML writes out header information for Xradia files to xml
%       txmhdr2xml(hdr)
%       txmhdr2xml(hdr, mode)
%       txmhdr2xml(hdr, mode, dir_loc)
%    where
%       hdr = TXM header obtained by txmheader_read# function
%       mode = 'short', or 'long','full' (default is 'short')
%       dir_loc = output directory (default is directory of TXM file)
%
%    (c) Robert S Bradley 2015


%Check inputs---------------------------------------------
if nargin<2
    mode = 'short';
end

if nargin<3
   dir_loc =  fileparts(hdr.File);
end   


%Create shortened hdr------------------------------------
TXMHeader_short = hdr;

%Loop over fieldnames to remove:
%DataLocatoins
TXMHeader_short = rmfield(TXMHeader_short, 'DataLocations');

%ConfigureBackup
if isfield(TXMHeader_short, 'ConfigureBackup');    
    TXMHeader_short = rmfield(TXMHeader_short, 'ConfigureBackup');
end

%ImageData - directory of images
fntmp = fieldnames(TXMHeader_short);
rem_inds = find(~cellfun(@isempty,(strfind(fntmp, 'ImageData')), 'UniformOutput',1));
for m = 1:numel(rem_inds)
    TXMHeader_short = rmfield(TXMHeader_short, fntmp{rem_inds(m)});
end

info = [{'File', [], [], []};txmheader_info8];

%Process fieldnames
TXMHeader_short = process_fieldnames(TXMHeader_short,[]);

%assignin('base', 'TXMHeader_short',TXMHeader_short)
%pause

%Write out shortened header
xml_write([dir_loc '\TXM_ShortInfo.xml'], TXMHeader_short);
%TXMHeader_short


%Write out full information if required------------------------
if strcmpi(mode, 'longtest');

    inds = find(ind2_longinfo);
    
    for m = 1:numel(inds)
    
        TXMHeader = [];
        TXMHeader.File = hdr.File;
        
        %Find information with txmdata_read function if necessary
        if info_inhdr(inds(m))
            TXMHeader.(fn{inds(m)}) = hdr.(fn{inds(m)}); 
        else
            TXMHeader.(fn{inds(m)}) = txmdata_read8(hdr, fn{inds(m)});
        end
        
        %Write out long information in seperate xml files
        xml_write([dir_loc '\TXM_' fn{inds(m)} '.xml'], TXMHeader);
    end
    
end    


    function hdr_in = process_fieldnames(hdr_in, fn)
        
            if isempty(fn)
                fn = fieldnames(hdr_in);
            end
            for n = 1:size(fn,1)                
                if isstruct(hdr_in.(fn{n}))
                    
                    hdr_in.(fn{n}) = process_fieldnames(hdr_in.(fn{n}), fieldnames(hdr_in.(fn{n})));
                    
                else
                    
                if iscell(hdr_in.(fn{n}))
                    if ~isempty(hdr_in.(fn{n}))
                    if isnumeric(hdr_in.(fn{n}){1}) 
                        if numel(hdr_in.(fn{n}){1})>50                            
                            hdr_in.(fn{n}) = [num2str(hdr_in.(fn{n}){1}(1:min(numel(hdr_in.(fn{n}){1}),50))) '...Obtain using txmdata_read'];                           
                        else
                            hdr_in.(fn{n}) = 'Obtain using txmdata_read';
                        end
                    else
                        hdr_in.(fn{n}) = 'Obtain using txmdata_read';
                    end
                    end
                end

                info_exists = find(strcmp(fn(n), info(:,1)));

                if ~isempty(info_exists)
                    if ischar(hdr_in.(fn{n}))            
                        info_inhdr(n) = isempty(strfind(hdr_in.(fn{n}), 'Obtain using txmdata_read'));
                        info_inhdr(n) = 1;
                    else
                        info_inhdr(n) = 1;
                    end   
                    ind2_info(n) = info_exists;
                    %hdr_in.(fn{n})
                    %class(hdr_in.(fn{n}))
                    %info{ind2_info(n),4}(:)
                    if ~isempty(info{ind2_info(n),4})
                        info_long = strfind(info{ind2_info(n),4}(:,1), 'resize');
                        info_long = [];
                    else
                        info_long = [];
                    end
                    if ~isempty(info_long) || ~info_inhdr(n)
                        hdr_in = rmfield(hdr_in, fn{n});
                        ind2_longinfo(n) = info_exists;
                    end    
                else
                    hdr_in = rmfield(hdr_in, fn{n});

                end

                end
            end
        
        
        
        
        
        
        
        
    end


end