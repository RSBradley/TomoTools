function xmlcell = xmltxtparse(xmltxt, structname, xmlstruct)

k = strfind(xmltxt, '<');
k1 = strfind(xmltxt, '>');


xmlcell = cell(numel(k),3);
currname = structname;
m = 1;
c = 1;
while m < numel(k)
    if strcmpi(xmltxt(k(m)+1), '/')
        %ending
        dp = strfind(currname, '.');
        if ~isempty(dp)
            currname = currname(1:dp(end)-1);
        end
        m = m+1
        %pause
    elseif strcmpi(xmltxt(k(m)+1), '!') | strcmpi(xmltxt(k(m)+1), '?')        
        m = m+1
    else
        %start
        k(m)
        k1(m)
        C = strsplit(xmltxt(k(m)+1:k1(m)-1),' ');
        currname = [currname '.' C{1}]
        currvalue = xmltxt(k1(m)+1:k(m+1)-1)
        xmlcell{c,1} = currname;
        if numel(C)>1
            xmlcell{c,2} = [C{2:end}];
        end
        xmlcell{c,3} = currvalue;
        c = c+1;
        m = m+1; 
        if strcmpi(xmltxt(k1(m)-1), '/')
            dp = strfind(currname, '.');
            if ~isempty(dp)
                currname = currname(1:dp(end)-1);
            end
        end
    end    
    
    %xmlcell(1:c,:)
    %pause
    
end

xmlcell = xmlcell(1:c,:);



end