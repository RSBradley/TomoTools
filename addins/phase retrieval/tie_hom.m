function [img_obj_plane img_thickness] = tie_hom(img_in, E, R1, R2,pix_size, RI, bg_val, show_prgs)


%Phase retrieval using the Transport of Intensity Equation for homogeneous
%samples
%
%   img_out = tie_hom(img_in, k_in, R1, R2,pix_size, dbratio)
%
%where
%
%       img_out = phase retieved image (2D matrix)
% img_thickness = image of sample thickness (m)
%        img_in = image to be phase retrieved (must be reference corrected). Must be a 2D matrix or empty if
%                 use dialog to read image file
%             E = mean x-ray energy (keV)
%            R1 = source to sample distance (m)
%            R2 = sample to detector distance (m)
%      pix_size = size of the image pixels (m)
%            RI = complex sample refractive index [delta beta]. NB ratio of real part to
%                 imaginary part will be of the order of 1000. If a vector will carry out phase retrieval based
%                 on each element
%        bg_val = background intensity in img_in (e.g. 1, 100...)
%
%NB beta = absorption coefficient/(2*k) where k = x-ray wavenumber
%Also img_in should be normalized on the detector plane so no factor of M^2
%is needed
%
% Copyright (c) Robert S. Bradley 2015


%Load image from file if img_in is empty
if isempty(img_in)
    [FileName,PathName] = uigetfile({'*.tif; *.tiff; *.bmp; *.jpeg;','Image files (*.tif, *.tiff, *.bmp, *.jpeg)';...
                                                        '*.*','All files (*.*)'},...
                                                        'Select phase contrast images', 'MultiSelect', 'off');

   img_in = single(imread([PathName FileName]));
end    

%Calculate x-ray wavenumber
k_in = kev2wn(E);

%Calculate geometrical magnification
if isinf(R1)
    M = 1;
else
    M = (R1+R2)/R1;
end

%Pad img_in to remove fft errors
pad_sz = 128;
if nargin>6
    img_in = padtovalue(img_in, [pad_sz pad_sz], bg_val);
else
    bg_val = 1;
end
if nargin<8
    show_prgs = 1;
end
    

%Initialise output matrices
img_obj_plane = zeros([size(img_in) size(RI,1)]);
img_thickness = img_obj_plane;

% FFT of img_in
%fprintf('Calculating image fourier transform...');
img_infft = fftshift(fft2(img_in));
%fprintf('Done\n');


% define spatial frequency matrix magnitude k
if show_prgs
    fprintf('Calculating phase retrieved images...    ');
end
[dimX dimY] = size(img_infft);
[kx ky] = meshgrid(0:dimX-1 , 0:dimY-1);

%shift matrix to be centred on zero
kx = (kx - ((dimX+0*1)/2));
ky = (ky - ((dimY+0*1)/2));

%calculate spatial frequency range in image in the x and y directions
kx = 2*pi()*kx/(dimX*pix_size);
ky = 2*pi()*ky/(dimY*pix_size);

%Net spatial frequency range
k = sqrt(kx.^2+ky.^2);
k_sqr = k'.^2;

clear kx ky

%Initialize matrix for phase retrieved image
%tmp = zeros(size(img_infft));

dbratio = RI(:,1)./RI(:,2);

do_thickness = 0;
if nargout>1
    do_thickness = 1;
end    

%Perform phase retrieval for each element of dbratio
for n = 1:max(size(dbratio))
    if show_prgs
        fprintf(['\b\b\b\b' sprintf('%4i',n)]);
    end
    
    %Calculate fourier filter
    ffilt =k_sqr*R2*dbratio(n)/(2*k_in*M)+1;
   
         
    %Apply filter by dividing all non-zero points in img_infft by ffilt
    %ind = int32(find(ffilt ~= 0));
    %tmp(ind) = img_infft(ind)./ ffilt(ind);    
       
    ind = int32(find(ffilt == 0));
    ffilt(ind) = 1e100;
    tmp=img_infft./ ffilt;
    
    %tmp(ind) = img_infft(ind)./ ffilt(ind);  
    
    %Inverse fourier transform to calculate phase retrieved image
    tmp = (ifft2(ifftshift(tmp)));
    img_obj_plane(:,:,n) = real(tmp);
    
      
    if do_thickness
        %Inverse fourier transform to calculate phase retrieved image
        img_thickness(:,:,n) = -log(img_obj_plane(:,:,n)/bg_val)/(2*k_in*RI(n,2));
    end
    
end
    

if nargin>6
    img_obj_plane = img_obj_plane(pad_sz+1:end-pad_sz,pad_sz+1:end-pad_sz,:);
    if do_thickness
        img_thickness = img_thickness(pad_sz+1:end-pad_sz,pad_sz+1:end-pad_sz,:);
    end
end

if show_prgs
    fprintf('\b\b\b\bDone\n');
end



end

