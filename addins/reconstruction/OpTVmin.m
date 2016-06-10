function [R, L] = OpTVmin(Op, s, Lambda,iter, L)


%Define forward and back projection functions
FP = @(x) (3.14159/2.0/Op.proj_size(1))*Op*x;
BP = @(x) (3.14159/2.0/Op.proj_size(1))*Op'*x;

%Calculate L using power method
if nargin<5    
    x = zeros(Op.vol_size, 'single');
    x(:) = BP(s(:));
    for k = 1:10
       dv = div(grad(x));
       x(:) = BP(FP(x(:)))-dv(:);
       L2 = sqrt(dot(x(:),x(:)));
       x = x/L2;
    end
    L = sqrt(L2);
end

%Initialise convergence parameters
tau = 1/L;
sigma = 1/L;
theta = 1;

%Initialise variables
u = zeros(Op.vol_size, 'single');
ubar = u;
q = 0*grad(ubar);
p = zeros(Op.proj_size, 'single');

% % %Calculate reconstruction mask
% % output_size = Op.vol_size;
% % if ndims(output_size)<3
% %     output_size(3) = 1;
% % end
% % s_size = Op.proj_size(2);
% % [Y, X] = meshgrid(-output_size(2)/2:output_size(2)/2-1, -output_size(1)/2:output_size(1)/2-1); 
% % minR = floor(s_size/2+1);          
% % mask = repmat(single((X.^2 + Y.^2 < minR^2)), [1 1 output_size(3)]); 
% % 
% % output_size = size(q);
% % [Y, X] = meshgrid(-output_size(2)/2:output_size(2)/2-1, -output_size(1)/2:output_size(1)/2-1);
% % minR = floor(max(output_size)/2-1);
% % maskq = repmat(single((X.^2 + Y.^2 < minR^2)), [1 1 output_size(3)]); 


for n = 1:iter
    
    %Update p
    p(:) = (p(:)+sigma*FP(ubar(:))-sigma*s(:))/(1+sigma);
    
    %Calculate TV
    gu = grad(double(ubar));
    
    %Update q
     q = q+sigma*gu;

% %     qmag = repmat(max(Lambda,sqrt(q(:,:,1).^2+q(:,:,2).^2)), [1 1 size(q,3)]);
% %     q = Lambda*q./qmag;
    
% %     qmag = sqrt(q(:,:,1).^2+q(:,:,2).^2);
% %     sz = size(q,3);    
% %     for m = 1:sz
% %         qtmp = q(:,:,m);
% %         qtmp(qmag>Lambda) = Lambda*qtmp(qmag>Lambda)./qmag(qmag>Lambda);
% %         q(:,:,m) = qtmp;
% %     end

    %qmag = sqrt(q(:,:,1).^2+q(:,:,2).^2);
    qmag = max(Lambda,sqrt(q(:,:,1).^2+q(:,:,2).^2));
    for m = 1:size(q,3)
        q(:,:,m) = Lambda*q(:,:,m)./qmag;
    end

    
    
    %Update u
    u_old = u;
    dv = div(q);  
    u(:) = u(:)-tau*(BP(p(:)))+tau*dv(:);
    
    %Impose mask
    %u = u.*mask+(1-mask)*mean(u(:));
    %u_old = u_old.*mask+(1-mask)*mean(u_old(:));
    
    %Update ubar
    ubar = u +theta*(u-u_old);  
 
    %Calculate energy 
    %g = abs(grad(ubar));
    %egy = 0.5*sumsqr((FP(ubar(:))-s(:)))+Lambda*sum(g(:))
    
    
end
R = ubar;
%R = ubar.*mask;


% %     function g = grad(x)
% %         
% %        g = zeros([size(x) 2]);
% %        g(2:end,:,1) = diff(x,1,1);
% %        g(:,2:end,2) = diff(x,1,2);  
% %         
% %         
% %     end
% % 
% %     function d = div(x)     
% %        g1 = grad(x(:,:,1));
% %        g2 = grad(x(:,:,2));
% %        d = g1(:,:,1)+g2(:,:,2);      
% %     end



end