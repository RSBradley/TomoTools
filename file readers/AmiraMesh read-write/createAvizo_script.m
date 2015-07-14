function createAvizo_script(filename, data_input, command_list, options)


%create default options
if nargin<4
    options.removeall=1;
    options.quit =0;
    options.saveall = 1;
end


%Working directory and file name
[path nm ext] = fileparts(data_input)


%command list = cell array i.e. {Module: name, options}
n_commands = size(command_list,1);


%Open script file for writing
fid = fopen(filename, 'w');
fprintf(fid, '# Avizo project created by Matlab function "createAvizo_script"\n\n');
fprintf(fid, '# Avizo\n');
if options.removeall    
    fprintf(fid, 'remove -all\n\n');
end

%Measure start time
fprintf(fid, 'set st [clock seconds]\n\n');

%write load data line
fprintf(fid, 'set hideNewModules 0\n\n');

data_name = ['"' nm '"'];
fprintf(fid, ['[ load ' strrep(data_input, '\', '/') '] setLabel ' data_name '\n']);
fprintf(fid, [data_name ' fire\n\n']);


%write out commands
result_name = data_name;
for n  = 1:n_commands
    
   switch command_list{1,1}
       case 'Module: Autoskeleton'
           fprintf(fid, 'create HxExtAutoSkeleton "Auto Skeleton"\n');
           fprintf(fid, ['"Auto Skeleton" data connect ' result_name '\n']);
           fprintf(fid, '"Auto Skeleton" fire\n');
           fprintf(fid, '"Auto Skeleton" fire\n');  
    
           
           %options for autoskeleton [spatialview threshold smoothing coeff1 smoothing coef2
           % number of interations]
           if command_list{1,2}(2)>0
               fprintf(fid, ['"Auto Skeleton" Threshold setValue ' num2str(command_list{1,2}(2)) '\n']);          
           end           
           
           if command_list{1,2}(3)>0
               fprintf(fid, '"Auto Skeleton" Options setValue 0 1\n'); 
               fprintf(fid, ['"Auto Skeleton" coefficients setValue 0 ' num2str(command_list{1,2}(3)) '\n']);
               fprintf(fid, ['"Auto Skeleton" coefficients setValue 1 ' num2str(command_list{1,2}(4)) '\n']);
               fprintf(fid, ['"Auto Skeleton" numberOfIterations setValue 0 ' num2str(command_list{1,2}(5)) '\n']);
           else
                 
               fprintf(fid, '"Auto Skeleton" Options setValue 0 0\n'); 
           end
           
           if command_list{1,2}(1)
                fprintf(fid, '"Auto Skeleton" Options setValue 1 1\n');
           else
                fprintf(fid, '"Auto Skeleton" Options setValue 1 0\n');
           end
           
           %Run
           fprintf(fid, '"Auto Skeleton" fire\n');
           fprintf(fid, '"Auto Skeleton" select\n');
           fprintf(fid, '"Auto Skeleton" doIt snap\n');
           fprintf(fid, '"Auto Skeleton" compute\n');
    
           result_name = [result_name(1:end-1) '.SptGraph"'];
           
           if n==n_commands | options.saveall
              save_str = strrep([path '\' result_name(2:end-1) '.am'], '\', '/');
              fprintf(fid, [ result_name ' save "Avizo 6 ascii SpatialGraph" "' save_str '"\n']);
               
           end
           
           
   end
    
end



%Measure end time
fprintf(fid, '\nset et [clock seconds]\n');
fprintf(fid, 'set dt [expr $et-$st]\n');

%Write out log file
[lf_path lf_nm] = fileparts(filename);
fprintf(fid, ['set fid [open "' strrep(lf_path, '\','/') '/' lf_nm '_log.txt" "w"]\n']);
fprintf(fid, 'puts -nonewline $fid "Done in "\n');
fprintf(fid, 'puts -nonewline $fid $dt\n');
fprintf(fid, 'puts -nonewline $fid " seconds."\n');
fprintf(fid, 'close $fid\n\n');

if options.quit
    fprintf(fid, 'quit\n');
end


fclose(fid);




end