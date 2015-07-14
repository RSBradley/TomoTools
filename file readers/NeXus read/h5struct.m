function s = h5struct(file)

%Converts a hdf5 format file into a structure
%
% (c) Robert S Bradley 2015


%Create structure with targets
info = h5info(file);
cg = info;
s = [];
load_dataset(cg, ['s' regexprep(info.Name, '/','')]);

%Loop through to read small data (<3D)
read_data(s, 's');

    function load_dataset(cg,path)
        
        %Read data in current group
        if isfield(cg, 'Datasets')
           nd = numel(cg.Datasets);
           for n = 1:nd
               %Get attributes
               nm = cg.Datasets(n).Name;
               if isfield(cg.Datasets(n), 'Attributes')
                   na = numel(cg.Datasets(n).Attributes);
                   for m = 1:na
                       if isfield(cg.Datasets(n).Attributes(m), 'Value')
                          anm =  cg.Datasets(n).Attributes(m).Name;
                          val = cg.Datasets(n).Attributes(m).Value;
                          
                          tmp = [path '.' regexprep(nm,'/','\.') '.' regexprep(anm,'/','\.') '=val;'];
                          tmp = regexprep(tmp, '\.\.', '\.');
                          
                          eval(tmp); 
                       end 
                   end    
               end
               
           end
           if nd==0 & isfield(cg, 'Attributes')
               na = numel(cg.Attributes);
               for m = 1:na
                   if isfield(cg.Attributes(m), 'Value')
                      anm = cg.Attributes(m).Name;
                      anm =  regexprep(anm,'/','\.');
                      if ~strcmpi(path(end), '.') & ~strcmpi(anm(1), '.')
                         anm = ['.' anm]; 
                      end
                      val = cg.Attributes(m).Value;
                      eval([path anm '=val;']); 
                   end 
               end
            end
                   
        end
        if isfield(cg, 'Links')
            
           nl = numel(cg.Links);
           for n = 1:nl
               nm = cg.Links(n).Name;
               %Get Link value
               if isfield(cg.Links(n), 'Value')
                   val = cg.Links(n).Value;
                   tmp = regexprep(nm,'/','\.');
                   if ~strcmpi(path(end),'.') & ~strcmpi(tmp(1), '.')
                      tmp = ['.' tmp]; 
                   end
                   eval([path tmp '=val;']); 
               end
               
           end
        end
        
        if isfield(cg, 'Groups')
           %Process sub-groups 
           ng = numel(cg.Groups);
           
           for n = 1:ng
              load_dataset(cg.Groups(n), ['s' regexprep(cg.Groups(n).Name, '/', '\.')]);               
           end
            
            
        end
        

    end


    function read_data(cg, path)
        
       if isstruct(cg) 
       fn = fieldnames(cg);
       for n = 1:numel(fn)
           if isstruct(cg.(fn{n}))
               read_data(cg.(fn{n}), [path '.' fn{n}]);
               
           elseif iscell(cg.(fn{n})) & numel(cg.(fn{n}))==1
               cinfo = h5info(file, cg.(fn{n}){1}); 
               if isfield(cinfo, 'Dataspace')
                   if numel(cinfo.Dataspace.Size)<3
                      t =  cg.(fn{n}){1};
                      eval([path '.' fn{n} '= [];']);
                      eval([path '.' fn{n} '.target = t;']);
                      eval([path '.' fn{n} '.value = h5read(file, t);']);
                      
                   end
               end
           end
           
       end
       end 
        
    end



end