function TTreconstruction(recon_params, create_sino)

if nargin<2
    create_sino = 1;
end
if strcmpi(recon_params.SD.DATA3D_h.contents, 'sinograms')
    create_sino = 0;
end

%create_sino = 0;
%Create sinograms
if isempty(dir([recon_params.sinogram_dir '\*.tif'])) | create_sino    
    
    %Load sino data class as necessary
    if ischar(recon_params.SD)
        [~, hdr_short] = eval(recon_params.SD);
        tmp = DATA3D(hdr_short);
        recon_params.SD = SINO_DATA3D(tmp);   
    end
    
    %Update SD
    recon_params.SD.shifts = recon_params.shifts;
    recon_params.SD.DATA3D_h.apply_shifts = 0;
    recon_params.SD.apply_shifts = 1;
    recon_params.SD.DATA3D_h.apply_ff = 1;
    recon_params.SD.output_file_name = [recon_params.sinogram_dir '\sinogram'];
    
    if recon_params.despeckle>0
       recon_params.SD.prefilter_options = {@(x,p) remove_extreme_pixels1(x, [9 9], p, 'local'),{recon_params.despeckle}};        
    end
    
    if recon_params.pad_options(1)>0        
       recon_params.SD.padding_options  = recon_params.pad_options;
    end
    
    recon_params.SD.ROI(:,1) = recon_params.ROI(:,3); %proj_inds
    recon_params.SD.ROI(:,3) = recon_params.ROI(:,1); %slices
    recon_params.SD.ROI(:,2) = recon_params.ROI(:,2); %slices
    recon_params.SD.slice_nos = recon_params.ROI(1,1):1:recon_params.ROI(3,1); %CHECK!!!
    
    %create sinograms
    recon_params.SD.export;        
end

%Load sinograms
fs = [recon_params.sinogram_dir '\sinogram_info.xml'];
[~, hdr_short] = TTxml(fs);
recon_params.SD = DATA3D(fs, hdr_short);


%Run reconstruction
switch recon_params.geometry
    case 'parallel beam'
        recon_params
        pb_reconstruction_astra(recon_params)
        return;
        
        if numel(recon_params.centre_shift)==1
            recon_params.centre_shift = recon_params.centre_shift*ones(numel(recon_params.rows),1);
        end
        shifts = zeros(numel(recon_params.angles),1);
        
        s_info = xml_read([recon_params.sinogram_dir '\sinogram_info.xml']);
        if numel(s_info.Angles)>2560
            pb_reconstruction(recon_params.sinogram_dir, recon_params.reconstruction_dir, recon_params.centre_shift,...
                recon_params.beam_hardening, recon_params.reconstruction_filter, recon_params.output_dims, shifts)
            
        else
            %USE ASTRA
            shifts
            pause
            pb_reconstruction_astra(recon_params, shifts)
        end
    case 'cone beam'
        %Todo

end