function txrm_add_noise(file_in, file_out, noise_level, Nref, A, sigma_det)

%Read header info
if ~iscell(file_in)
    hdr = txmheader_read8(file_in);
    n_imgs = double(hdr.ImageInfo.NoOfImages);


    %Read ref
    FF = txmimage_read8(hdr, [], 0, 0);
    Ref_counts = FF*A;
else
   
    n_imgs = size(file_in{1},3);
    Ref_counts = file_in{2}*A;
    FF = double(file_in{2});
end

%Loop over images
for n = 1:n_imgs
    tic;
    fprintf(1, ['Processing image ' num2str(n) '...']);
    
    %Load image
    %n\
    if iscell(file_in)
        T = double(file_in{1}(:,:,n))./double(file_in{2});
        
    else
        img = txmimage_read8(hdr, n, 0, 0);
        T = img./FF;
    end
    
    %Estimage Ttrue
    %Ttrue = medfilt2(T, [3 3]);
    %calculate Ttrue or load
    if isempty(file_in{3})
        Ttrue = medfilt2(T, [5 5], 'symmetric');
        %Ttrue = imfilter(T, fspecial('gaussian', [3 3], 0.5));
        save(['Ttmp' num2str(n) '.mat'], 'Ttrue', '-v6');
    else
       %load 
        tmp = load(['Ttmp' num2str(n) '.mat']);
        Ttrue = tmp.Ttrue;
    end
    
    %Add noise
    Tout = add_T_noise(T, Ttrue, Nref, sigma_det, Ref_counts, noise_level);
    
    %Write out data
    Tout = uint16(Tout.*FF);
    
    imgdata_no = floor((n-1)/100)+1;
    struct_name = ['ImageData' num2str(imgdata_no)];
     
    fwritess(file_out, {[struct_name '\Image' num2str(n)]}, {Tout(:)});
    t = toc;
    fprintf(1, ['Done in ' num2str(t) 's\n']);
    
end









end