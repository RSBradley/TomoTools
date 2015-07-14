function TomoToolsqueue_mfile(queue, tmp_file, multiple_fls, pathdeffile)


defaults = TomoTools_defaults;
queue_size = numel(queue);

if multiple_fls
    %TO BE UPDATED OR REMOVED IN FUTURE RELEASE
    dot_ind = find(tmp_file=='.');
    base_nm = tmp_file(1:dot_ind(end)-1);
    ext_nm = tmp_file(dot_ind(end):end);
    
    for n = 1:queue_size
        queue_str = [];        
        
        queue_str = [queue_str '%%' num2str(n) '. ' queue{n}.function ' ' queue{n}.version ' ================================\n'];   
    
        %Specify file
        queue_str = [queue_str 'file = ''' regexprep(queue{n}.filename, '\\', '\\\\') ''';\n'];
    
        %Load method
        loadmethod = func2mstring(defaults.loadmethods{(queue{n}.filetype),1}, '#file');
        queue_str = [queue_str '[~, hdr_short] = ' loadmethod '\n'];
        queue_str = [queue_str 'DATA = DATA3D(file,hdr_short);\n'];
    
        %Load data if am file
        %if queue{n}.filetype==3
        %
        %    queue_str = [queue_str 'data = loadmethods{' num2str(queue{n}.filetype) ',2}(hdr,1);\n'...
        %                 'data = expand_structure(data, ''data'', []);\ndata = data{2};\n'];
        %    
        %end    
        %Function to evaluate
        queue_str = [queue_str regexprep(queue{n}.mstring, '\\', '\\\\') '\n\n'];

        
        %Open m file for writing
        file_nm = [base_nm '_' num2str(n) ext_nm];
        fid = fopen(file_nm ,'w');


        %Write opening strings
        %fprintf(fid, ['loadmethods = ' loadmethods ';\n']);        
        fprintf(fid, '%s', sprintf(queue_str));
        fprintf(fid, '%s\n','clear all;');
        fprintf(fid, '%s\n','delete([mfilename(''fullpath'') ''.m'']);');
        
        fclose(fid);
        

    end
    
    
    
else
    %Write code to single file
    if ~isempty(pathdeffile)
       pdef = regexprep(fileparts(pathdeffile), '\\', '\\\\'); 
       %pathdeffile = regexprep(pathdeffile, '\\', '\\\\');
       queue_str = ['addpath(''' pdef ''');\n'];
       queue_str = [queue_str 'matlabpath(pathdef)\n'];
    else
        queue_str = [];
    end
    
    p = regexprep(fileparts(mfilename('fullpath')), '\\', '\\\\');
    queue_str = [queue_str 'addpath(genpath(''' p '''));\n'];
    
    queue_str = [queue_str 'error_str = [];\n\n'];
    for n = 1:queue_size
    
        queue_str = [queue_str '%%' num2str(n) '. ' queue{n}.function ' ' queue{n}.version ' ================================\n'];     
    
        %encapsulate in try catch end
        queue_str = [queue_str 'try\n'];
        
        %Specify file
        queue_str = [queue_str 'file = ''' regexprep(queue{n}.filename, '\\', '\\\\') ''';\n'];
    
        %Load method
        loadmethod = func2mstring(defaults.loadmethods{(queue{n}.filetype),1}, '#file');
        queue_str = [queue_str '[~,hdr_short] = ' loadmethod '\n'];
        queue_str = [queue_str 'DATA = DATA3D(file,hdr_short);\n'];
    
        
        %Function to evaluate
        queue_str = [queue_str regexprep(queue{n}.mstring, '\\', '\\\\') '\n'];


        %catch errors
        queue_str = [queue_str 'catch ERR\n'];
        queue_str = [queue_str 'error_str = [error_str ''' num2str(n) '. ' queue{n}.function ' ' queue{n}.version ' ================================\\n''];\n'];
        queue_str = [queue_str 'error_str = [error_str ''file = '' regexprep(file, ''\\'', ''\\\\'') ''\\n''];\n'];
        queue_str = [queue_str 'error_str = [error_str ''error = '' ERR.message '', line '' num2str(ERR.stack.line) ''\\n\\n''];\nend\n\n'];
  
        
    end

    %Open m file for writing
    fid = fopen(tmp_file ,'w');


    %Write opening strings
    fprintf(fid, '%s', sprintf(queue_str));
    
    fprintf(fid, '%s\n','if ~isempty(error_str)');
    fprintf(fid, '%s\n','fid = fopen([mfilename(''fullpath'') ''_ERROR.log''], ''w'');');
    fprintf(fid, '%s\n','fprintf(fid, error_str);');
    fprintf(fid, '%s\n','fclose(fid);');
    fprintf(fid, '%s\n','else');    
    fprintf(fid, '%s\n','delete([mfilename(''fullpath'') ''.m'']);');
    fprintf(fid, '%s\n','end');
    fprintf(fid, '%s\n','clear all;');
    fprintf(fid, '%s\n','exit;');
    fclose(fid);
end




