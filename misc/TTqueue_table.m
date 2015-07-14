function inds = TTqueue_table(queue)

%Create figure
f = figure('Name', 'TomoTools queue',...  % Title figure
       'NumberTitle', 'off',... % Do not show figure number
       'MenuBar', 'none', 'CloseRequestFcn', @find_selected);
   
pos = get(f,'Position');
pos(3:4)  = [460, 360];
set(f, 'Position', pos);
   
%Create data
colnames = {[]};
inds = [];
try
    tmp = fieldnames(queue{1});
catch
    return
end    
colnames(2:numel(tmp)+1) = tmp;
data=cell(numel(queue),6);
for n = 1:numel(queue)
   data{n,1} = true; 
   for m = 2:numel(colnames)
      data{n,m} = queue{n}.(colnames{m});      
   end
   data{n,6} = regexprep(data{n,6}, '\n', ' ');
end
columneditable = false(1,numel(colnames));
columneditable(1) = true;
column_width = num2cell([25 80 60 200 60 500]);
   
htable = uitable('Parent', f, 'Units', 'normalized',...
                 'Position', [0.025 0.025 0.95 0.95],...
                 'Data',  data,... 
                 'ColumnName', colnames,...
                 'ColumnWidth', column_width,...
                 'ColumnEditable', columneditable);   

             
             
inds = []; 
uiwait(f);

    function find_selected(~,~)
       
        
        data = get(htable, 'Data');
        inds = cell2mat(data(:,1));
        %inds = cell2mat(data{:,1});
        delete(f);
        
        
        
    end   



end