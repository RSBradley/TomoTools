function gm = gmhistfit(X, Y, k, do_plot)

if nargin<4
    do_plot = 1;
end
if nargin<3
  answer = (inputdlg({'Enter number of peaks to fit'},'Fit Gaussian Mixture model',1,{'2'}));
  k = str2num(answer{1});
end

%Remove large outliers
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
dX = X(2)-X(1);

if numel(k)>1
    AIC = zeros(1,4);
    GMModels = cell(1,4);
    for n = 1:numel(k)
        GMModels{n} = fitgmdist(Xnew,k(n),'Options',statset('MaxIter',1500), 'Replicates', 11);   
        AIC(n) = GMModels{n}.AIC;
    end
    [~,mind] = min(AIC);
    gm = GMModels{mind};
    k = k(mind);
else
    gm = fitgmdist(Xnew,k,'Options',statset('MaxIter',1500), 'Replicates', 11);
end

gmnet = dX*pdf(gm, X(:));
if do_plot
    figure('Name', 'Gaussian Mixture Model plots','NumberTitle','off');plot(X, Y, 'LineWidth', 2);
    hold on
    plot(X, gmnet, '-g');
    for n = 1:k
        Ygm = gm.PComponents(n)*dX*normpdf(X(:), gm.mu(n), sqrt(gm.Sigma(n)));    
        plot(X, Ygm, '-r');
    end
    out = dialog('WindowStyle', 'normal', 'Name', 'Gaussian Mixture Model results');
    gmtext = evalc('disp(gm)');
    gmedit = uicontrol('style', 'edit', 'unit', 'normalized','position', [0 0 1 1], 'String', gmtext, 'Max', 10, 'parent', out, 'BackgroundColor', [1 1 1],'HorizontalAlignment', 'Left');
end


end