function [img_out img_pmap] = remove_extreme_pixels1(img, filter_sz, n_sigmas, mode)

%img = image data
%filter_sz = size of filter used to estimate correct pixel value
%n_sigmas = number of standard deviations from the mean extreme pixels are


if nargin<4
    mode = 'global';
end

o_class = class(img);
img = double(img);

img_mean1 = mean(img(:));
img_std1 = std(img(:));
img_limits1 = img_mean1 + n_sigmas*img_std1*[-1 1];
h = fspecial('average', filter_sz);
h(floor(size(h,1)/2)+1, floor(size(h,1)/2)+1) = 0;
if strcmpi(mode, 'local')

    %h = fspecial('average', filter_sz);
    img_map = img-imfilter(img,h, 'symmetric')+100;
    img_mean = mean(img_map(:));
    img_std = std(img_map(:));
else
    img_map = img;
    img_mean = img_mean1;
    img_std = img_std1;
end    

%imager(img_map)
%Find extreme values
%img_mean = mean(img_map(:));
%img_std = std(img_map(:));
img_limits = img_mean + n_sigmas*img_std*[-1 1];

if img_limits(1)<0
    img_limits(1)=0;
end

inds = find(img_map<=img_limits(1) | img_map>=img_limits(2));

prob_map = exp(-((img_map-img_mean)./(2*img_std)).^2);

tmp = imfilter(img.*prob_map,h, 'symmetric')./imfilter(prob_map,h, 'symmetric');

%size(rows)
%n_sigmas
img_out = img;

img_out(inds) = tmp(inds);
switch o_class
    case 'single'
        img_out = single(img_out);
    case 'uint16'
        img_out = uint16(img_out);
    case 'uint8'
        img_out = uint8(img_out);
end
        

%img_sz = size(img);
if nargout>1
    img_pmap = zeros(size(img));
    img_pmap(inds) = 1;
end



%if isempty(rows)
%    return
%end    

%Create filter
%m = 0;
%for c = 2-filter_sz(2):filter_sz(2)-2
%    for r = 2-filter_sz(1):filter_sz(2)-2
%       m = m+1;
%       filter(m,1) = r;
%       filter(m,2) = c; 
%    end
%end

% %filter
% for n = 1:max(size(rows))
% 
%     img_rows = rem(filter(:,1) + rows(n), img_sz(1));
%     img_rows(img_rows<1) = img_rows(img_rows<1)+img_sz(1);
%    
%     img_cols = rem(filter(:,2) + cols(n), img_sz(2));
%     img_cols(img_cols<1) = img_cols(img_cols<1)+img_sz(2);  
% 
%     img_data = img_out(img_rows, img_cols);
%     
%     img_out(rows(n), cols(n)) = mean(img_data(img_data>img_limits1(1) & img_data<img_limits1(2)));
%     
%     if nargout>1
%         img_pmap(rows(n), cols(n)) = 1;
%     end
% end
% 

end