function [img_obj_plane img_thickness] = pd_phaseretrieval(img_in, E, R1, R2, pix_size, RI, threshold, bg_val,show_prgs)


%Phase retrieval using the equation of Wu et al. [1] based on phase-attenuation duality or a homogeneous
%sample
%
%   [img_obj_plane img_thickness] = pd_phaseretrieval(img_in, E, R1, R2,pix_size, RI, threshold, bg_val)
%
%where
%
%       img_out = phase retieved image (2D matrix)
% img_thickness = image of sample thickness (m) if homogeneous sample or
%                 projected electron density (m-2) if using phase-attenuation duality
%       img_in  = image to be phase retrieved (must be reference corrected). Must be a 2D matrix or empty if
%                 use dialog to read image file
%            E  = mean x-ray energy (keV)
%           R1  = source to sample distance (m)
%           R2  = sample to detector distance (m)
%     pix_size  = size on the image pixels (m)
%           RI  = complex sample refractive index [delta beta] of homogeneous sample.
%                 Leave empty to use phase-attenuation duality. If a vector will carry out phase retrieval based
%                 on each element
%     threshold = threshold below which Tikhonov regularization is used
%                 (e.g. 0.8); 
%        bg_val = background intensity in img_in (e.g. 1, 100...), leave
%                 empty for no padding
%
%NB beta = absorption coefficient/(2*k) where k = x-ray wavenumber
%Also img_in should be normalized on the detector plane so no factor of M^2 is needed
%
%[1] 

%Load image from file if img_in is empty
if isempty(img_in)
    [FileName,PathName] = uigetfile({'*.tif; *.tiff; *.bmp; *.jpeg;','Image files (*.tif, *.tiff, *.bmp, *.jpeg)';...
                                                        '*.*','All files (*.*)'},...
                                                        'Select phase contrast images', 'MultiSelect', 'off');

   img_in = single(imread([PathName FileName]));
end  

if nargin<9
    show_prgs = 1;
end

%Calculate wavenumber in m-1
wn = kev2wn(E);
lambda = 2*pi()/wn;

%Geometrical magnification
M = (R1+R2)/R1;

if isempty(RI)
    %Use phase-attenuation duality e.g. Compton scattering dominates
    %Calculate compton scattering cross-section in m
    sigma = kn_cross_section(E,'m');
    
    %classical electron radius in m
    re =  (1/(4*pi()*8.8541878e-12))*((1.602176e-19)^2)/ (9.10938188e-31*(2.99792458e8^2)); %CORRECT

    %Gamma
    gamma = lambda*re/sigma;
    
     %'Absorption coefficient' required for calculating projection electron
    %density 'thickness'
    abs_coeff =sigma;
    
else
    %Gamma
    gamma = 0.5*RI(:,1)./RI(:,2);
    
     %Absorption coefficient required for calculating thickness
    abs_coeff = 2*wn*RI(:,2);
    
   
end

%Number of images to calculates
n_vals = numel(gamma);

%Fresnel propagator multiplication factor
fpmf = R2/(2*wn*M);


%Pad img_in to remove fft errors
pad_sz = 128;
if nargin>7
    img_in = padtovalue(img_in, [pad_sz pad_sz], bg_val);
else
    bg_val = 1;
end    

%FFT2 of input image
img_infft = fftshift(fft2(img_in));

%Pre-allocate output matrices
%Initialise output matrices
img_obj_plane = zeros([size(img_in) n_vals]);

%Check if to calculate thickness image
do_thickness = 0;
if nargout>1
    do_thickness = 1;
    img_thickness = img_obj_plane;
end
%Calculate spatial frequency matrix
[dimX dimY] = size(img_in);
[kx ky] = meshgrid(0:dimX-1 , 0:dimY-1);

%shift matrix to be centred on zero
kx = (kx - ((dimX+0*1)/2));
ky = (ky - ((dimY+0*1)/2));

%calculate spatial frequency range in image in the x and y directions
%NB in DFT frequency range is from 0 to 2pi in steps of 2pi/N
%Here to get same range -pi to pi in steps of 2pi/N
kx = 2*pi()*kx/(dimX*pix_size);
ky = 2*pi()*ky/(dimY*pix_size);


%Net spatial frequency range
k_sqr = kx.^2+ky.^2;

%Calculate alpha
alpha = fpmf*k_sqr;

%Do fourier filtering
kappa = 1e-2;
if show_prgs
    fprintf('Calculating phase retrieved images...    ');
end
for n = 1:n_vals
    if show_prgs
        fprintf(['\b\b\b\b' sprintf('%4i',n)]);
    end
    
    %Calculate delta
    delta = sqrt(1+(2*gamma(n)+alpha).^2);

    %Calculate alpha1
    alpha1 = alpha - asin((2*gamma(n)+alpha)./delta);

    %Calculate frequency filter
    filt = 1./(delta.*cos(alpha1));

    %min(filt(:))
    
    filt_reg = cos(alpha1)./(delta.*(cos(alpha1).^2+kappa^2));
    filt(alpha1>threshold) = filt_reg(alpha1>threshold);

    %Do filtering
    img_outfft = img_infft.*filt;

    
    %Calculate out plane image
    img_obj_plane(:,:,n) = real(ifft2(ifftshift(img_outfft)));

    if do_thickness
        %Calculate thickness
        img_thickness = -log(img_obj_plane/bg_val)/abs_coeff(n); 
    end    
end    

%Crop to remove padding
if nargin>7
    img_obj_plane = img_obj_plane(pad_sz+1:end-pad_sz,pad_sz+1:end-pad_sz,:);
    if do_thickness
        img_thickness = img_thickness(pad_sz+1:end-pad_sz,pad_sz+1:end-pad_sz,:);
    end
end
if show_prgs
    fprintf('\b\b\b\bDone\n');
end
end