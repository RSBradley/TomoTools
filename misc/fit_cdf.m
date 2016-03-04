function [cdf_adj xparams] = fit_cdf(cdf1, cdf2)

options = optimset('TolFun',1e-8);

x = cdf1(:,1);
x2 = cdf2(:,1);

%Optimise offset first, then scaling
p0 = lsqnonlin(@scale_cdf,0, [],[],options);

%Optimise all parameters
p0 = [0 1 p0];
xparams = lsqnonlin(@scale_cdf,p0, [],[],options);

xi = (x.^2)*xparams(1)+x*xparams(2)+xparams(3);
        
cdf_adj = interp1(x2, cdf2, xi, 'spline', NaN);
%figure;plot(cdf1)
%hold on
%plot(cdf_adj, '-r')
%pause

    function err = scale_cdf(p)
        
       if numel(p)==1
          p = [0 1 p]; 
       end
       xi = (x.^2)*p(1)+x*p(2)+p(3);
        
       cdf2_adj = interp1(x2, cdf2(:,2), xi, 'spline', NaN);
       
       inds = find(~isnan(cdf2_adj));
       cdf2_adj(isnan(cdf2_adj))=cdf1(isnan(cdf2_adj),2);
       
       err = 10000*(cdf1(:,2)-cdf2_adj)/numel(inds);
       
       
        
    end
        








end