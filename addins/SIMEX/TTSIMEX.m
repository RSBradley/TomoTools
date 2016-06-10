function TTSIMEX(noise_params, mfh, SIMEX_lambda, SIMEX_repeats)

% recon_params - reconstruction parameters from TomoTools
% noise_params - [A sigma_det Nref]
%                 A and sigma_det are from noise fitting
%                 Nref = number of (white/flat field) reference images
% mfh          - measurement functon handle such that
%                measurement = mfh(data);
% SIMEX_lambda - SIMEX noise levels. Defaults [0 0.5 1 1.5 2]
% SIMEX_repeats - # of simulation repeats. Defaults to 15

% (c) Robert S Bradley 2016
global recon_params

if nargin<3
    SIMEX_lambda = [0 0.5 1 1.5 2];
end

if nargin<4
    SIMEX_repeats = 15;
end

Measurement_Cell = cell(numel(SIMEX_lambda),2);
Nruns = numel(find(SIMEX_lambda>0))*SIMEX_repeats+numel(find(SIMEX_lambda==0));
count = 0;
options.InfoString = 'Running SIMEX repeats...';
w1 = TTwaitbar(0,options);

%Loop over SIMEX lambda
for NL = 1:numel(SIMEX_lambda)
   %Loop over repeats
   if SIMEX_lambda(NL)==0
       fprintf('%s',['Processing: SIMEX lambda = ' num2str(SIMEX_lambda(NL)) ', Repeat = 1/1.']);
       tic
       recon_params.SD.DATA3D_h.add_noise = [];
       TTreconstruction(recon_params,1);   
       TF = TTxml([recon_params.reconstruction_dir '\reconstruction_info.xml']);
       DT = DATA3D(TF.File,TF);
       data = DT(:,:,:);
       Measurement_Cell{NL,1} = 0;
       Measurement_Cell{NL,2} = mfh(data);
       save([recon_params.reconstruction_dir '\Measurement_Cell.mat'], 'Measurement_Cell');
       clear data TF DT;
       t = toc;
       fprintf('%s',[' Done in ' num2str(t) 's.\n']);
       delete([recon_params.reconstruction_dir '\*.tif']);
       delete([recon_params.sinogram_dir '\*.tif']);
       pause(0.1);
       count = count+1;
       TTwaitbar(count/Nruns,w1);
   else
       %Set noise parameters
       recon_params.SD.DATA3D_h.add_noise.Nref = noise_params(3);
       recon_params.SD.DATA3D_h.add_noise.A = noise_params(1);
       recon_params.SD.DATA3D_h.add_noise.sigma_det = noise_params(2);
       recon_params.SD.DATA3D_h.add_noise.noise_level = SIMEX_lambda(NL);
       recon_params.SD.DATA3D_h.add_noise.EstTrue = @(x,n) medfilt2(x,[5 5]);
       Measurement_Cell{NL,1} = SIMEX_lambda(NL);
       Measurement_Cell{NL,2} = cell(SIMEX_repeats,1);
       for NR = 1:SIMEX_repeats
            tic;
            try
            fprintf('%s',['Processing: SIMEX lambda = ' num2str(SIMEX_lambda(NL)) ', Repeat = ' num2str(NR) '/' num2str(SIMEX_repeats) '.']);
            TTreconstruction(recon_params,1);
            TF = TTxml([recon_params.reconstruction_dir '\reconstruction_info.xml']);
            DT = DATA3D(TF.File,TF);
            data = DT(:,:,:);
            Measurement_Cell{NL,2}{NR} = mfh(data);
            save([recon_params.reconstruction_dir '\Measurement_Cell.mat'], 'Measurement_Cell');
            clear data TF DT;
            catch
            end
            t = toc;
            fprintf('%s',[' Done in ' num2str(t) 's.\n']);
            delete([recon_params.reconstruction_dir '\*.tif']);
            delete([recon_params.sinogram_dir '\*.tif']);
            pause(0.1);
            count = count+1;
            TTwaitbar(count/Nruns,w1);
       end
   end
    
end




end