function uitextsize(uictrl, border)

if nargin<2
    border=5;
end
for n = 1:numel(uictrl)
    epos = get(uictrl(n), 'Extent');
    pos = get(uictrl(n), 'Position');   
    set(uictrl(n), 'Position', [pos(1:2) epos(3) epos(4)-border]);
end


end