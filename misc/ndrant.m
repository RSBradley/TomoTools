function [ND cpts] = ndrant(I, fh, n)


ND = zeros(n,n);
cpts = zeros(n,n,2);
if iscell(fh)
    nout = fh{2}-1;
    tmp = ['[' repmat('~,',[1 nout]) 'b]=fh{1}(data);'];
end


m = ceil(size(I)/n);

for k = 1:n
    krng = [(k-1)*m(1)+1 min(size(I,1),k*m(1))];
    for j = 1:n        
        jrng = [(j-1)*m(2)+1 min(size(I,2),j*m(2))];
        
        
        
        
        data = I(krng(1):krng(2),jrng(1):jrng(2));
        
        cpts(k,j,1) = 0.5*(krng(1)+krng(2));
        cpts(k,j,2) = 0.5*(jrng(1)+jrng(2));
        %imager(data)
        %[a b] = min(data(:))
        %pause
        if iscell(fh)
           eval(tmp);
           ND(k,j) = b;
            
        else
            ND(k,j) = fh(data);
        end
        
        
    end
    
    
end




end