function expstrct = expand_structure(struct, root, expstrct)

%if nargin<3
   
%    expstrct = {[],[]};

%end

names = fieldnames(struct);
for i=1:length(names)
        
    value = struct.(names{i});
    if isstruct(value)
       expstrct = expand_structure(value, [root '.' names{i}], expstrct);
    else
       sz = size(expstrct,1);
       expstrct{sz+1,1} = [root '.' names{i}];
       expstrct{sz+1,2} = value;
            
        
       %disp([root '.' names{i} ': ' num2str(value)]);
   end
end


end
 
