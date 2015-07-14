function handles = TTvtabs(Parent, Position, TabNames, TabSize, options)


%Defaults options
opts.btncolor = [0.8 0.8 0.8;0.6 0.6 0.6];
opts.tabcolor = 1.1*[0.8 0.8 0.8;0.6 0.6 0.6];
opts.highlightcolor = [1 1 1];
opts.margin = 5*[1 1];
if nargin>4
    fn = fieldnames(options);
    for nf = 1:numel(fn)
        opts.(fn{nf}) = options.(fn{nf});   
    end
end

TLHC = [Position(1) Position(2)+Position(4)];
p = fileparts(mfilename('fullpath'));
pic = javax.swing.ImageIcon([p '\pluscircled32.png']);
mic = javax.swing.ImageIcon([p '\minuscircled32.png']);

%Loop over tabs
for n = 1:numel(TabNames)
    
    jLabel = javaObjectEDT('javax.swing.JLabel',TabNames{n});
    %jLabel = javax.swing.JLabel(TabNames{n},javax.swing.ImageIcon('D:\HMtoolsV3\plus.ico'));
    jLabel.setIcon(pic);
    [handles.(['Tab' num2str(n)]).Btn{1},handles.(['Tab' num2str(n)]).Btn{2}] = javacomponent(jLabel,[TLHC(1) TLHC(2)-n*(TabSize(2)+opts.margin(1)) TabSize(1) TabSize(2)],Parent);
    col = opts.btncolor(rem(n,2)+1,:);    
    handles.(['Tab' num2str(n)]).Btn{1}.setBackground(java.awt.Color(col(1), col(2), col(3)));
    set(handles.(['Tab' num2str(n)]).Btn{1}, 'MouseClickedCallback', {@tabchange, n});
    set(handles.(['Tab' num2str(n)]).Btn{2}, 'Tag', 'TTvtab-btn');
    %handles.(['Tab' num2str(n)]).BtnLabel = uicontrol('Style', 'text','Parent', Parent, 'String', TabNames{n},'units', 'pixels',...
    %                                             'Position', [TLHC(1) TLHC(2)-n*TabSize(2) TabSize(1) TabSize(2)], ...
    %                                             'BackgroundColor', opts.btncolor(rem(n,2)+1,:));
    %handles.(['Tab' num2str(n)]).Btn = uipanel('Parent', Parent, 'units', 'pixels','BorderType', 'line',...
    %                                             'Position', [TLHC(1) TLHC(2)-n*TabSize(2) TabSize(1) TabSize(2)], ...
    %                                             'BackgroundColor', [0 0 0], 'ButtonDownFcn', {@tabchange, n});
                                        
                            
    handles.(['Tab' num2str(n)]).MiniTab = uipanel('units', 'pixels','Position', [TLHC(1)+TabSize(1)+opts.margin(1) TLHC(2)-n*(TabSize(2)+opts.margin(2)) Position(3)-TabSize(1) TabSize(2)],...
                                                    'BackgroundColor', opts.tabcolor(rem(n,2)+1,:),'BorderType', 'none', 'ButtonDownFcn', {@tabchange, n}, 'Parent', Parent, 'Tag', 'TTvtab-mini');
    handles.(['Tab' num2str(n)]).FullTab = uipanel('units', 'pixels','Position', [TLHC(1)+TabSize(1)+opts.margin(1) Position(2) Position(3)-TabSize(1) Position(4)-TabSize(2)],...
                                                    'Visible', 'off','BackgroundColor', opts.highlightcolor, 'BorderType', 'none', 'Parent', Parent, 'Tag', 'TTvtab-full');
    
    handles.(['Tab' num2str(n)]).State = 0;



end




    function tabchange(hobj,~,N)        
        if handles.(['Tab' num2str(N)]).State==0
            expand(N);
        else
            reset;
        end
        
    end

    function expand(N)
        
        for m = 1:numel(TabNames)
            if m==N
                handles.(['Tab' num2str(m)]).State=1;
                pos = get(handles.(['Tab' num2str(m)]).Btn{2}, 'Position');
                set(handles.(['Tab' num2str(m)]).Btn{2}, 'Position', [pos(1:2) TabSize(1)+opts.margin(1) pos(4)]);
                col = opts.highlightcolor;
                handles.(['Tab' num2str(m)]).Btn{1}.setBackground(java.awt.Color(col(1), col(2), col(3)));                
                handles.(['Tab' num2str(m)]).Btn{1}.setIcon(mic);
                
                ch = findobj('Parent', handles.(['Tab' num2str(m)]).MiniTab, 'Style', 'text');
                set(ch, 'BackgroundColor', opts.highlightcolor);
                
                set(handles.(['Tab' num2str(m)]).MiniTab, 'Position', [pos(1)+TabSize(1)+opts.margin(1) Position(2)+Position(4)-TabSize(2)-opts.margin(2) Position(3)+TLHC(1)-TabSize(1)-pos(1) TabSize(2)], ...
                            'Visible', 'on', 'BackgroundColor',opts.highlightcolor);
                set(handles.(['Tab' num2str(m)]).FullTab, 'Position', [pos(1)+TabSize(1)+opts.margin(1) Position(2) Position(3)+TLHC(1)-TabSize(1)-pos(1) Position(4)-TabSize(2)-opts.margin(2)], ...
                             'Visible', 'on');
                         
            else
                handles.(['Tab' num2str(m)]).State = 0;
                %set(handles.(['Tab' num2str(m)]).Btn, 'Value',0);
                col =opts.btncolor(rem(m,2)+1,:);
                set(handles.(['Tab' num2str(m)]).Btn{1}, 'Background', java.awt.Color(col(1), col(2), col(3)));
                handles.(['Tab' num2str(m)]).Btn{1}.setIcon(pic);
                pos = get(handles.(['Tab' num2str(m)]).Btn{2}, 'Position');
                set(handles.(['Tab' num2str(m)]).Btn{2}, 'Position', [pos(1:2) TabSize(1) pos(4)]);
                                
                
                set(handles.(['Tab' num2str(m)]).MiniTab, 'Visible', 'off');
                set(handles.(['Tab' num2str(m)]).FullTab, 'Visible', 'off');
            end
        end        
    end

    function reset
        %Reset size and positions of tabs
        for m = 1:numel(TabNames)
             handles.(['Tab' num2str(m)]).State = 0;
             col = opts.btncolor(rem(m,2)+1,:);
             handles.(['Tab' num2str(m)]).Btn{1}.setBackground(java.awt.Color(col(1), col(2), col(3)));
             handles.(['Tab' num2str(m)]).Btn{1}.setIcon(pic);             
             pos = get(handles.(['Tab' num2str(m)]).Btn{2}, 'Position');
             set(handles.(['Tab' num2str(m)]).Btn{2}, 'Position', [pos(1:2) TabSize(1) pos(4)]);
             
             
             ch = findobj('Parent', handles.(['Tab' num2str(m)]).MiniTab, 'Style', 'text');
             set(ch, 'BackgroundColor', opts.tabcolor(rem(m,2)+1,:));
             
             set(handles.(['Tab' num2str(m)]).MiniTab, 'Position', [pos(1)+TabSize(1)+opts.margin(1) pos(2) Position(3)+Position(1)-TabSize(1)-pos(1) TabSize(2)],...
                           'Visible', 'on', 'BackgroundColor', opts.tabcolor(rem(m,2)+1,:));
             set(handles.(['Tab' num2str(m)]).FullTab, 'Position', [pos(1)+TabSize(1) Position(2) Position(3)+Position(1)-TabSize(1)-pos(1) Position(4)-TabSize(2)], ...
                            'Visible', 'off');
        end
    end

end