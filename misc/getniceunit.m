function [psout, uout] = getniceunit(psin, uin)


mfs = [1 1e-2 1e-3 1e-6 1e-9];

switch uin
    case 'm'
        mf = mfs(1);
    case 'cm'
        mf = mfs(2);
    case 'mm'
        mf = mfs(3);
    case 'microns'
        mf = mfs(4);
    case '\mum'
        mf = mfs(4);
    case 'nm'
        mf = mfs(5);
end

%Convert meters and calculate power of 10
pw = floor(log10(psin*mf));
pws = log10(mfs);

[~, mind] = min(abs(pw-pws));
mind = max(mind);

psout = (psin*mf)/mfs(mind);

switch mind
    case 1
        uout = 'm';
    case 2
        uout = 'cm';
    case 3
        uout = 'mm';
    case 4
        uout = 'microns';
    case 5
        uout = 'nm';
end


end