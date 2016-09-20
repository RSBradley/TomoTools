function tv = TV(img, cp)

%If normalize then find TV in matching ROI by avoiding pixels at edges for
%reconstruction circle

nimgs = size(img,3);
if nargin<2
    do_norm = 0;
    m = 1:nimgs;
else
    do_norm = 1;
    if abs(cp(end))<abs(cp(1))        
       m = 1:nimgs;
    else        
        
        m =nimgs:-1:1;
    end
end


tv  = zeros(nimgs,1);
inds = [];

for n = m
     
    gu = grad(imfilter(img(:,:,n), fspecial('gaussian', [5 5],1)));   
    if do_norm
        if isempty(inds)
           %inds = find(gu(:,:,1)~=0);
           %inds = ;
           mask = zeros(size(img(:,:,1)));
           mask(find(img(:,:,n)~=0)) = 1;
           mask = imerode(mask,strel('disk',3));
           inds = find(mask);
           %imager(mask)
        end
       gu = gu(:,:,1).^2+gu(:,:,2).^2;
       tv(n) = sum(gu(inds));      
    else
        tv(n) = sum(gu(:).^2);
    end
end

% mask = zeros(size(img,1),size(img,2));
% mask(inds) = 1;
% imager(mask);
end