function imgN = DATA3D_add_noise(img, img_ref, img_rng,options)


%assume img is already reference corrected
imgN = img;
nimgs = size(img,3);
for n = 1:nimgs
    %Estimate true transmission image e.g. medfilt2(img,[5 5])    
    %img_rng(n)
    Ttrue = options.EstTrue(img(:,:,n),img_rng(n));    
    %imager(Ttrue)
    imgN(:,:,n) = add_T_noise(img(:,:,n), Ttrue, options.Nref, options.sigma_det, options.A*img_ref, options.noise_level);
    
end



end