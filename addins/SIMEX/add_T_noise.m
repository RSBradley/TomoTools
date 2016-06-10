function [Tout, sigma_T] = add_T_noise(T, True, Nref, sigma_det, Ref_counts, noise_level)


%noise level = 1/sqrt(Ref_counts)
%sigma_det is in units of Ref_counts.

sigma_T = (True./sqrt(Ref_counts)).*sqrt((1./True)+(1/Nref)+((sigma_det^2)./Ref_counts).*((True.^(-2))+1/Nref));

Tout = T+noise_level*sigma_T.*randn(size(T));




end