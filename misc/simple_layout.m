function simple_layout(parent, arrangement, margin)

if iscell(parent)
    ch = parent{2};
    parent = parent{1};
else
    ch = get(parent, 'children');
end
if isempty(ch)
    return;
end

set(parent, 'Units', 'pixels');
position = get(parent, 'Position');

start_pos = [0 0];
dir = [0 0];
do_margin = {0, 0};

if ischar(arrangement)
net_arrangement = strsplit(arrangement, '-');
arrangement = net_arrangement{1};
if numel(net_arrangement)==1
    sub_arrangement = 'MM';  
else
    sub_arrangement = net_arrangement{2};
end
else
   sub_arrangement = arrangement{2};
   arrangement = arrangement{1}; 
end
%Overall grid location
switch arrangement(1)
    case 'L'
        start_pos(1) = 0;
        dir(1) = 1;
    case 'M'        
        start_pos(1) = position(3)/2;
        do_margin{1} = 'w';
        dir(1) = 1;
    case 'R'   
        start_pos(1) = position(3);
        do_margin{1} = -1;
        dir(1) = -1;
end
switch arrangement(2)
    case 'T'
        start_pos(2) = position(4);
        do_margin{2} = -1;
        dir(2) = -1;
    case 'M'        
        start_pos(2) = position(4)/2;
        do_margin{2} = 'w';
        dir(2) = 1;
    case 'B'   
        start_pos(2) = 0;
        dir(2) = 1;
end





%Loop over children to calculate grid size
relpos_o = zeros(numel(ch),2);
ch_pos = zeros(numel(ch),4);
for n = 1:numel(ch)
    rp = get(ch(n), 'UserData');
    if ~isempty(rp)        
        relpos_o(n, 1:2) = rp(1:2);  
        ch_pos(n,:) = get(ch(n), 'position');
    else
        ch(n) = NaN;
    end    
end
if max(relpos_o)==0
   return; 
end
ch_pos = ch_pos(~isnan(ch),:);
relpos_o  = relpos_o (~isnan(ch),:);
ch = ch(~isnan(ch));

%Group controls as necessary
relpos = floor(relpos_o);
[U1, IA, IC] = unique(relpos, 'rows');

if size(U1,1)~=numel(ch)
    rem_inds = ones(numel(ch),1);
    nu = find(~ismember(1:numel(ch), IA));
    U = unique(relpos(nu,:), 'rows');
    gps = cell(size(U,1),2);
    for ng = 1:size(U,1)
       gps{ng,1} = U(ng,:);
       gps{ng,2} = find(relpos(:,1) == U(ng,1) & relpos(:,2) == U(ng,2));
       rem_inds(gps{ng,2})=0;
       for ng1 = 1:numel(gps{ng,2})           
           UD = get(ch(gps{ng,2}(ng1)),'UserData');
           UD = round(10*(UD-floor(UD)));
           UD(UD==0)=1;
           set(ch(gps{ng,2}(ng1)),'UserData', UD);
       end
       
       if ischar(sub_arrangement)            
           gp_arrangement = ['LT-' sub_arrangement];
       else
           ud = floor(get(ch(gps{ng,2}(1)),'UserData'));
           gp_arrangement = ['LT-' sub_arrangement{ud(2), ud(1)}];
       end
       
       simple_layout({parent, ch(gps{ng,2})}, gp_arrangement, margin); 
       
       pos = get(ch(gps{ng,2}), 'Position');
       pos = cat(1,pos{:});
       net_pos = [0 0 0 0];
       net_pos(1) = min(pos(:,1));
       net_pos(2) = min(pos(:,2));
       net_pos(3) = max(pos(:,1)+pos(:,3))-net_pos(1);
       net_pos(4) = max(pos(:,2)+pos(:,4))-net_pos(2);
       
       ch_pos(gps{ng,2},:) = repmat(net_pos, [numel(gps{ng,2}),1]);
    end 
    
    chU = ch(IA);
    ch_pos = ch_pos(IA,:);
    relpos = relpos(IA,:);
else
    chU = ch;
    gps = [];
end

maxrow = max(relpos(:,2));
maxcol = max(relpos(:,1));

grid_sz{1} = zeros(maxcol,1);
grid_sz{2} = zeros(maxrow,1);

for m = 1:maxrow
    inds = find(relpos(:,2)==m);
    if ~isempty(inds)
        grid_sz{2}(m)=max(ch_pos(inds,4));  
    end
end
for m = 1:maxcol
    
    inds = find(relpos(:,1)==m);
    if ~isempty(inds)
        grid_sz{1}(m)=max(ch_pos(inds,3));  
    end
end

%Map out grid
gridx = cumsum([0;dir(1)*grid_sz{1}(1:end-1)]+dir(1)*margin(3));
gridy = cumsum([0;dir(2)*grid_sz{2}(1:end-1)]+dir(2)*margin(4));


%Adjust margin from edges
gridx = gridx-gridx(1)+dir(1)*margin(1);
gridy = gridy-gridy(1)+dir(2)*margin(2);

%Adjust centre position
if isnumeric(do_margin{2})
    gridy = gridy+do_margin{2}*grid_sz{2}(1);
else
    %centre grid across parent
    [mxval, mxind] = max(gridy);
    mnval = min(gridy);
    gridy = gridy-mnval-(mxval+grid_sz{2}(mxind)-mnval)/2;
end

if isnumeric(do_margin{1})
    gridx = gridx+do_margin{1}*grid_sz{1}(1);
else
    %centre grid across parent
    [mxval, mxind] = max(gridx);
    mnval = min(gridx);
    gridx = gridx-mnval-(mxval+grid_sz{1}(mxind)-mnval)/2;
end


%Reposition

if ~isempty(gps)
    gp_ch = ch(cat(1,gps{:,2}));
else
    gp_ch = [];
end
for n = 1:numel(chU)

    if ~ismember(chU(n),gp_ch)        
    
    %LB sub-arrangement by default
    ch_pos(n,1) = start_pos(1)+gridx(relpos(n,1));
    ch_pos(n,2) = start_pos(2)+gridy(relpos(n,2));
    
    %Sub-arrangement    
    dw = grid_sz{1}(relpos(n,1))-ch_pos(n,3);
    dh = grid_sz{2}(relpos(n,2))-ch_pos(n,4);
    if ischar(sub_arrangement)
        sa = sub_arrangement;
    else
       sa =  sub_arrangement{relpos(n,2), relpos(n,1)};
    end
    switch sa(1)
        case 'R'
            ch_pos(n,1) = ch_pos(n,1)+dw;            
        case 'M'
            ch_pos(n,1) = ch_pos(n,1)+dw/2;                
    end
    switch sa(2)
        case 'T'
            ch_pos(n,2) = ch_pos(n,2)+dh;            
        case 'M'
            ch_pos(n,2) = ch_pos(n,2)+dh/2;          
    end
    
    set(chU(n), 'Position',ch_pos(n,:));
    end
end


if ~isempty(gps)
    %drawnow
    for ng = 1:size(gps,1)
        chinds = gps{ng,2};
        relpos = floor(relpos_o(chinds,:));
        ch_pos = get(ch(chinds), 'position');
        ch_pos = cat(1,ch_pos{:});
        
        ch_pos(:,1) = ch_pos(:,1)-min(ch_pos(:,1)); 
        ch_pos(:,2) = ch_pos(:,2)-min(ch_pos(:,2));
        dp1 = start_pos(1)+gridx(relpos(1,1));
        dp2 = start_pos(2)+gridy(relpos(1,2));
        
        W = max(ch_pos(:,1)+ch_pos(:,3));
        H = max(ch_pos(:,2)+ch_pos(:,4));        
        
        %Sub-arrangement    
        dw = grid_sz{1}(relpos(1,1))-W;
        dh = grid_sz{2}(relpos(1,2))-H;
        if ischar(sub_arrangement)
            sa = sub_arrangement;
        else
            sa =  sub_arrangement{relpos(1,2), relpos(1,1)};
        end
        
        
        switch sa(1)
            case 'R'
                dp1 = dp1+dw;            
            case 'M'
                dp1 = dp1+dw/2;               
        end
        switch sa(2)
            case 'T'
                dp2 = dp2+dh;            
            case 'M'
                dp2 = dp2+dh/2;          
        end
        
        for ngn = 1:numel(chinds) 
            
            ch_pos(ngn,1) = ch_pos(ngn,1)+dp1;%start_pos(1)+gridx(relpos(ngn,1));
            ch_pos(ngn,2) = ch_pos(ngn,2)+dp2;%start_pos(2)+gridy(relpos(ngn,2));             
            set(ch(chinds(ngn)), 'Position',ch_pos(ngn,:));
            
        end
        
        
    end
  
    
end




