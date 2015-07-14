function cs = str2cell(str)

cs = strsplit(str,' ');
for n = 1:numel(cs)    
    tmp = str2num(cs{n});
    if ~isempty(tmp)
        cs{n} = tmp;
    end
end

end