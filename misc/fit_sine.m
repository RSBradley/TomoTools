function [params sinefit] = fit_sine(angles, data)


options = optimset('TolFun',1e-25, 'Display', 'off');

beta0 = [10 0 0];

params = lsqnonlin(@sin_fit,beta0,[-1e6 -1e6 -1e6],[1e6 1e6 1e6], options);
sinefit = sin_fit(params)+data;

    function diffs = sin_fit(beta)
        
        y = beta(1)*sind(angles+beta(2))+beta(3);
        diffs = y-data;       
        
        
    end




end
