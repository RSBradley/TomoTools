function pks = kdepeak_pos(X, Y, do_plot)

if nargin<3
    do_plot = 1;
end
if do_plot
   set(gcbf, 'Pointer', 'watch');
   drawnow;
end

%Remove large outliers
Y = double(Y);
X = double(X);

Ymed = medfilt1(Y, 5);
Ydiff = abs(Y-Ymed);
Ydiffmed = median(Ydiff(:));
Y(Ydiff>1000*Ydiffmed) = Ymed(Ydiff>1000*Ydiffmed);


%Normalise Y
Ysum = sum(Y(~isnan(Y)));
Y = double(Y)./Ysum;


Yscaled = round(Y.*10000);


%Generate data
Nvals =  sum(Yscaled(~isnan(Yscaled)));

Xnew = zeros(Nvals,1);

count = 1;
for n = 1:numel(Y)
   if Yscaled(n)>0
     Xnew(count:count+Yscaled(n)-1) = X(n);  
     count = count+Yscaled(n);
   end    
end


%[Ynew,~, fbw] = ksdensity(Xnew,X);
%[pk,locs] = findpeaks(Ynew);
%[Ynew,~, fbw] = ksdensity(Xnew,X, 'width', 3);
[Ynew,~,fbw] = ssvkernel(Xnew,X, (X(2)-X(1)).*[0.5:0.5:20]);


%Ynew = Y/(X(2)-X(1));
try
    [pk,locs] = findpeaks(Ynew);
catch
    [pk,locs] = findpeaks(Y);
end

if isempty(pk)
    errordlg('No peaks found')
    set(gcbf, 'Pointer', 'arrow');
    return;
end
ind=find(pk>0.01*max(pk(:)));
pk = pk(ind);
locs = locs(ind);


sigma = fbw(locs);
locsX = X(locs);






%Fit peaks in histogram to get std
options = statset('Display', 'off');


pks = zeros(numel(pk),3);
pkus = zeros(numel(pk),3);
for a = 1:numel(pk)
    params0 = [sigma(a).*sqrt(2*pi())*pk(a)' locsX(a)' sigma(a)'];
    rng_ind = find(X>locsX(a)-2*sigma(a) & X<locsX(a)+2*sigma(a));
    if numel(rng_ind)<5
        rng_ind = (locs(a)-2:locs(a)+2);
    end
    ff = @(p) Ynew(rng_ind)-p(1)*normpdf(X(rng_ind),p(2), p(3));    
    pks(a,:) = lsqnonlin(ff,params0, [0 0 0],[Inf Inf Inf],options);
    
   
    ff = @(p) Y(rng_ind)-p(1)*normpdf(X(rng_ind),p(2), p(3));
    pkus(a,:) = lsqnonlin(ff,params0, [0 0 0],[Inf Inf Inf],options); 
end

if do_plot
    figure('Name', 'Peak positions','NumberTitle','off', 'Color', [1 1 1]);
    %bar(X, Y, 'FaceColor', [0.5 0.5 0.5]);
    area(X, Y./(sum(Y(:)*(X(2)-X(1)))), 'FaceColor', 0.75*[1 1 1], 'LineStyle', 'none');
    drawnow
    %bar(X, Y./(sum(Y(:)*(X(2)-X(1)))), 'k');
    hold on
    plot(X, Ynew, 'LineWidth', 2);
    ylabel('normalized frequency', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    
    pktext = sprintf(['Histogram smoothed using KDE with bandwidths ' sprintf('%0.3f,', sigma) '\n\n' num2str(numel(pk)) ' peaks found at:\n\n']);
    for n = 1:numel(pk)
        plot([pks(n,2) pks(n,2)], [0 pks(n,1)*normpdf(0,0,pks(n,3))], '-r');
        pktext = [pktext num2str(n) '.  ' num2str(pks(n,2)) ', peak height = ', num2str(pks(n,1)*normpdf(0,0,pks(n,3))) ', standard deviation = ' num2str(pks(n,3)) sprintf('\n')];
    end
     pktext = [pktext sprintf('\n\nUnsmoothed peak positions:\n\n')];
    for n = 1:numel(pk)        
        pktext = [pktext num2str(n) '.  ' num2str(pkus(n,2)) ', peak height = ', num2str(pkus(n,1)*normpdf(0,0,pkus(n,3))) ', standard deviation = ' num2str(pkus(n,3)) sprintf('\n')];
    end
    
    out = dialog('WindowStyle', 'normal', 'Name', 'Peak fitting results');    
    pkedit = uicontrol('style', 'edit', 'unit', 'normalized','position', [0 0 1 1], 'String', pktext, 'Max', 10, 'parent', out, 'BackgroundColor', [1 1 1],'HorizontalAlignment', 'Left');
    
    
    set(gcbf, 'Pointer', 'arrow');

end



end