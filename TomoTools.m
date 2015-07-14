classdef TomoTools < handle

    properties (SetObservable = true)      
      handles;     
    end
    
    
    methods
        function obj = TomoTools 
            obj.handles.defaults = TomoTools_defaults;
            fprintf('\n\n===================================================\n\n'); 
            fprintf(['TomoTools v' obj.handles.defaults.version '\n\n']);      
            p = mfilename('fullpath');
            sl_pos = strfind(p, '\');
            p = p(1:sl_pos(end)-1);
            HSPLASH =  splash([p '\icons\TTsplash600.png']);
            t1 = tic;
            
            %initialise data handles
            obj.handles.DATA = [];
            obj.handles.SINODATA = [];
            obj.handles.image = [];
            obj.handles.do_pointer_val = 0;
            obj.handles.del_fcn = @delete_fcn;

            %Initialise queue
            obj.handles.queue = {};
            obj.handles.get_queue = @() obj.handles.queue;
            obj.handles.add2queue = @add2queue;
            obj.handles.run_queue = @run_queue;
            obj.handles.view_queue = @view_queue;

            %Load main GUI
            obj.handles.modules = {};
            obj.handles.addins = @() obj.handles.modules;
            obj.handles = GUI_main(obj.handles);

            %set up shared functions
            obj.handles.add_shared_function = @(name, fhdl) add_shared_function(name, fhdl);
            obj.handles.get_shared_function = @(name) get_shared_function(name);
            
            
            %Load plugins                
            listing = dir([p '\addins\*addin.m']);
            fprintf(['Found ' num2str(numel(listing))  ' plugins:\n']);
            count = 0;
            for n = 1:numel(listing)                   
                fprintf(['  Loading ' listing(n).name(1:end-2) '...']);
                count = count+1;
                try
                    eval(['obj.handles.modules{count} = '  listing(n).name(1:end-2) '(obj.handles);']);    
                    fprintf('Done.\n');
                catch
                    count = count-1;
                    fprintf('Error.\n');
                end
                
            end
            
            fprintf('\n===================================================\n\n');
                      
                      
            %show figure
            set(obj.handles.fig, 'visible', 'on');
            drawnow;
            t = toc(t1);
            if t<3
                pause(3-t);
            end
            splash(HSPLASH, 'off');   
            
            %NESTED FUNCTION
                function fcns = get_shared_function(name)
            
                    fcns = getappdata(obj.handles.fig, 'shared_functions'); 
                    if ~isempty(name)
                        try
                           fcns = fcns.(name); 
                        catch
                           warning(['Shared function with name = ' name 'does not exist.']) 
                        end
                    end
                    
                    
                end
                
                function add_shared_function(name, fhdl)
            
                    shared_fcns = get_shared_function([]);
                    shared_fcns.(name) = fhdl;
                    setappdata(obj.handles.fig, 'shared_functions', shared_fcns);
                    
                end
                
                function run_queue
                    
                     pathdeffile = which('pathdef');
                     if ~exist(obj.handles.defaults.local_tmp_dir)
                         obj.handles.defaults.local_tmp_dir  = tempdir;                       
                     end
                     queue_tmp_file =  [obj.handles.defaults.local_tmp_dir 'TTqueue_tmp_' sprintf('%06i', randi(1e6)) '.m'];
                     TomoToolsqueue_mfile(obj.handles.queue, queue_tmp_file,0, pathdeffile)                
                
                    %Run in another instance of matlab                     
                    dos(['matlab -automation -r run(''' queue_tmp_file ''') &']);
                    
                    msgbox({['Running queue in background. Start time is ' datestr(now)] ,[],['Queue file:  ' queue_tmp_file ],[],'A corresponding log files is generated if there are errors.'}, ['TomoTools v' obj.handles.defaults.version ': batch queue'])
                    
                    %Clear queue
                    handles.queue = [];
                
                
                end
                
                function view_queue
                    
                    if ~isempty(obj.handles.queue) 
                        inds = TTqueue_table(obj.handles.queue);
                        obj.handles.queue = obj.handles.queue(inds);
                    end  
                
                
                end
            
            
                function add2queue(queue_item)
                    queue_n = max(size(obj.handles.queue));
                    obj.handles.queue{queue_n+1} = queue_item;
                    msgbox([queue_item.function ' job added to queue']);
                end
            
                
                
               function delete_fcn(fig)
                    delete(fig);
                    delete(obj);
                end 
        
        
        end
        
        

        
    end    
    
 


end