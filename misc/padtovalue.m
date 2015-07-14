function array_out = padtovalue(array, padsize, value)

%3D handling
if size(array,3)>1
    if numel(padsize)==2
        padsize = [padsize 0];
    end
    array_out = zeros(size(array)+2*padsize);
    for nn = 1:size(array,3)        
        array_out(:,:,nn) = padtovalue(array(:,:,nn), padsize(1:2), value);
    end
    return;    
end


%pad array
initial_size = size(array);
tmp = zeros(initial_size+2*padsize);
tmp(padsize(1)+1:padsize(1)+initial_size(1),padsize(2)+1:padsize(2)+initial_size(2)) = array;
array_out = tmp;
clear tmp

%percentage error tolerance for edge value
perr = 0.01;


%calculate padded values
% along dimension 1
ind =1:padsize(1); 
valdiff = repmat((array_out(padsize(1)+1,padsize(2)+1:initial_size(2)+padsize(2))-value),[padsize(1) 1]);
tmp = log(perr*abs(value-valdiff)./abs(valdiff));
tmp(valdiff==0)=0;
tmp1 = repmat((ind-padsize(1)-1).^2/(padsize(1)^2), [initial_size(2) 1])';

%pad before
array_out(1:padsize(1), padsize(2)+1:initial_size(2)+padsize(2)) =valdiff.*exp(tmp.*tmp1)+value;
valdiff = repmat((array_out(padsize(1)+initial_size(1),padsize(2)+1:initial_size(2)+padsize(2))-value),[padsize(1) 1]);
tmp = log(perr*abs(value-valdiff)./abs(valdiff));
tmp(valdiff==0)=0;
tmp1 = tmp1(end:-1:1,:);

%pad after
array_out(initial_size(1)+padsize(1)+1:end, padsize(2)+1:initial_size(2)+padsize(2)) =valdiff.*exp(tmp.*tmp1)+value;


% along dimension 2
ind =1:padsize(2); 
valdiff = repmat((array_out(:,padsize(2)+1)-value),[1 padsize(2)]);
tmp = log(perr*abs(value-valdiff)./abs(valdiff));
tmp(valdiff==0)=0;
tmp1 = repmat((ind-padsize(2)-1).^2/(padsize(2)^2), [initial_size(1)+2*padsize(1) 1]);


%pad before
array_out(:,1:padsize(2)) =valdiff.*exp(tmp.*tmp1)+value;

valdiff = repmat((array_out(:,padsize(2)+initial_size(2))-value),[1 padsize(2)]);
tmp = log(perr*abs(value-valdiff)./abs(valdiff));
tmp(valdiff==0)=0;
tmp1 = tmp1(:,end:-1:1);

%pad after
array_out(:,padsize(2)+initial_size(2)+1:end) =valdiff.*exp(tmp.*tmp1)+value;


%fill in missing values
%for n = 1:padsize(2)
%    array(1:padsize(1),padsize(2)+initial_size(2)+n) = 0.5*array(1:padsize(1),padsize(2)+initial_size(2)+n-1)+0.5*array(padsize(1)+1,padsize(2)+initial_size(2)+n);
%    
%end


end