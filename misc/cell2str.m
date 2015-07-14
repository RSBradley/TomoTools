function str = cell2str(cs)

str = [];
for n = 1:numel(cs)    
    str = [str ' ' num2str(cs{n})];    
end



end