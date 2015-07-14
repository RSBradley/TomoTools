function y = intbto2b(x1, x2, dplaces)

%Converts 2 integers of 'b' bits into one integer of 2'b' bits

%n_vals = numel(x1);
%tmp1 = repmat('0', [n_vals dplaces]);
%tmp2 = tmp1;

x1 = dec2bin(x1(:), dplaces);
x2 = dec2bin(x2(:), dplaces);

%tmp1(:,end-size(x1,2)+1:end) = x1;
%tmp2(:,end-size(x2,2)+1:end) = x2;

%y = bin2dec([tmp1 tmp2]);

if dplaces>26

    twos = 2.^(2*dplaces-1:-1:0);    
    twos = repmat(twos, [size(x1,1) 1]);
    v = [x1 x2] - '0';
    y = sum(v .* twos,2);
else
    y = bin2dec([x1 x2]);
end






end