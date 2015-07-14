function colorbutton(button, c1, c2, mode)

%Get button size
pos = get(button, 'Position');

h = floor(pos(4)-4);
w = floor(pos(3)-4);

if nargin<4
    mode = 'gradient';    
end
c = zeros(h*2,1,3);
switch mode
    case 'gradient'
    c = zeros(h*2,1,3);
    c(:) = [c1(1):(c2(1)-c1(1))/(2*h-1):c2(1);c1(2):(c2(2)-c1(2))/(2*h-1):c2(2);c1(3):(c2(3)-c1(3))/(2*h-1):c2(3)]';
    c = c(1:h,:,:); 
    c = repmat(c, [1,w,1]);

    mpt = floor(h/2);
    c(mpt:end,:,3) = c(mpt:end,:,3)+0.5*(c2(3)-c1(3));
    c(mpt,:,:) = 0.75*(c(1,:,:))+0.25*ones(1,1,1);
    
    case 'edge'
    c = zeros(h+4,w+4,3);    
    c(:,:,1) = c(:,:,1)+c2(1);
    c(:,:,2) = c(:,:,2)+c2(2);
    c(:,:,3) = c(:,:,3)+c2(3);
   
    c(:,1:4,1) = c1(1);
    c(:,1:4,2) = c1(2);
    c(:,1:4,3) = c1(3);
    
    c(:,end:-1:end-4,1) = c1(1);
    c(:,end:-1:end-4,2) = c1(2);
    c(:,end:-1:end-4,3) = c1(3);    
    c(end:-1:end-4,:,1) = c1(1);
    c(end:-1:end-4,:,2) = c1(2);
    c(end:-1:end-4,:,3) = c1(3);    
    c(1:4,:,1) = c1(1);
    c(1:4,:,2) = c1(2);
    c(1:4,:,3) = c1(3);    
    
    set(button ,'ForegroundColor', 0.5*c1);
end

set(button, 'CData', c);

end