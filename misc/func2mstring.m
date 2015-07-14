function fnstr = func2mstring(fnhandle, varargin)


if ischar(fnhandle)
    fnstr = [fnhandle '('];    
else
   fnhstr = func2str(fnhandle);
    if ~strcmpi(fnhstr(1),'@');
        fnhstr = ['@' fnhstr];
    end    
    fnstr = ['feval(' fnhstr ','];
    startstr = [];     
end

startstr = [];

for n = 1:nargin-1
    
    if isempty(varargin{n})
        fnstr = [fnstr '[]'];
    
    elseif ischar(varargin{n})
       if strcmpi(varargin{n}(1), '*')
           fnstr = [fnstr inputname(n+1)];
       elseif strcmpi(varargin{n}(1), '@')
           fnstr = [fnstr inputname(n+1)];
           if isempty(startstr)
               startstr = ['@(' inputname(n+1)];
           else
               startstr = [startstr ',' inputname(n+1)];
           end
       elseif strcmpi(varargin{n}(1), '#')
           fnstr = [fnstr varargin{n}(2:end)];
       else
           fnstr = [fnstr '''' varargin{n} ''''];
       end
    elseif isnumeric(varargin{n})
        if numel(varargin{n})>1
           fnstr = [fnstr '[' num2str(varargin{n}, '%g ') ']'];
        else    
            fnstr = [fnstr num2str(varargin{n})];
        end
        
    elseif iscell(varargin{n})    
        
       fnstr = [fnstr cell2str(varargin{n})];      
        
    else
       continue;
    end
    if n<nargin-1
      fnstr = [fnstr ',']; 
    end    
end

fnstr = [fnstr ');']; 

if ~isempty(startstr)
    fnstr = [startstr ') ' fnstr ]; 
end

end