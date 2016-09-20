function [r, Nval, mask]= central_slice_astra(s, angles, R12, pixel_size, shifts, centre_shift, filt, output_size, options)



%FOR PB, s should be in [angle column order]
%FOR CB, s should be in [column angle row];
%pixel_size = pixel_size at object plane

%% Process inputs and set defaults
%Filter
if nargin<7 || isempty(filt)
    filt = 'Ram-Lak';
end

%Ouput dimensions
if nargin<8
    if isinf(R12(1))
        %PB
         output_size = [size(s,2) size(s,2)];
    else
        %CB
        output_size = [size(s,1) size(s,1)];
    end
         
end

%Dither shifts
if isempty(shifts)
    shifts = zeros(numel(angles),1);
end

%Process pixel size
if numel(pixel_size)==1
    pixel_size(2)= pixel_size(1);
end

%Process optional arguments
mid_plane = 0;
if nargin<9
    options = [];    
end
if isfield(options, 'show_wb')
    %Show waitbar
    show_wb = options.show_wb;
else
    show_wb = 1;
end
if isfield(options, 'detector_shiftx')
    %Detector centre position x
    dsx = options.detector_shiftx;
else
    dsx = 0;
end
if isfield(options, 'detector_shifty')
    %Detector centre position y
    dsy = options.detector_shifty;
else
    dsy = 0;
end
if ~isinf(R12(1))
    %Required arguments for conebeam reconstruction
    slices = options.slices;
    dh = options.detector_height;
    mid_plane = (mean(slices(:))-(dh/2));
end
if isfield(options, 'algorithm')  
    %algorithm
   algorithm =  options.algorithm;
else
   algorithm = 'BP3D_CUDA';
end
if isfield(options, 'iterations')
    %algorithm iterations
   iterations =  options.iterations;
else
   iterations = 1;
end
if isfield(options, 'GPUindex')
    %GPU selection
    GPUindex = options.GPUindex-1;
else
    GPUindex = 0;
end

if isfield(options, 'centre_shift_mode')
    centre_shift_mode = options.centre_shift_mode;
elseif isinf(R12(1))
    centre_shift_mode = 'fft';
else
    centre_shift_mode = 'vector geom';
end
if isfield(options, 'mask');
   do_mask = 1;
   if numel(options.mask)==1;
       %calculate mask
       [Y, X] = meshgrid(-output_size(2)/2:output_size(2)/2-1, -output_size(1)/2:output_size(1)/2-1); 
       do_mask=2;
       minR = options.mask;
       if minR==0
          minR = floor(size(s,1)/2)+1;          
       end
   else
       %use precalculated mask
        options.mask = single(options.mask);
        if size(options.mask,3)<size(s,3)
            options.mask = repmat(options.mask(:,:,1), [1 1 size(s,3)]); 
        end
   end
else
   do_mask = 0;
end
if isfield(options, 'rotation_direction')
    %Do something?
end
if isfield(options, 'gpu_memory_limit')
    gpu_mem_limit = options.gpu_memory_limit;
    %Do something?
else
    gpu_mem_limit = Inf;
end
%Convert angles to radian as necessary
if max(angles(:))>10    
   angles = angles*pi()/180; 
end

%% SET UP GEOMETRY and ASTRA config
if isinf(R12(1))
    %parallel beam geometry
    if size(s,3)>1
       s = s(:,:,round(size(s,3)/2)); 
    end
    if strcmpi(centre_shift_mode, 'fft')
        if size(s,3)==1
            proj_geom = astra_create_proj_geom('parallel', 1.0, size(s,1), angles(:)');        
            vol_geom = astra_create_vol_geom([output_size(1), output_size(2)]);
            if find(strcmpi(algorithm,{'FBP_CUDA', 'BP3D_CUDA'})); 
                cfg = astra_struct('BP_CUDA');
            else
                algorithm = regexprep(algorithm, '3D', '');
                cfg = astra_struct(algorithm);
                filt = 'none';
            end
        end
    else
        vectors = zeros(numel(angles),12);

        %source
        vectors(:,1) = sin(angles);
        vectors(:,2) = -cos(angles);
        vectors(:,3) = 0;

        % center of detector
        vectors(:,4) = 0-dsx*cos(angles);
        vectors(:,5) = 0-dsx*sin(angles);
        vectors(:,6) = (dsy);

         % vector from detector pixel (0,0) to (0,1)
         vectors(:,7) = cos(angles);
         vectors(:,8) = sin(angles);
         vectors(:,9) = 0;

         % vector from detector pixel (0,0) to (1,0)
         vectors(:,10) = 0;
         vectors(:,11) = 0;
         vectors(:,12) = 1;    

        proj_geom = astra_struct('parallel3d_vec');
        proj_geom.DetectorRowCount = 1;
        proj_geom.DetectorColCount = size(s,1);
        proj_geom.Vectors = vectors;


    % %     proj_geom = astra_create_proj_geom('parallel', 1.0, size(s,2), angles(:)');
        vol_geom = astra_create_vol_geom([output_size(1), output_size(2) 1]);
    % %     
    % %  
        if strcmpi(algorithm(1:2), 'BP')
            s = filterProjections(s, filt, Inf);
        end
        cfg = astra_struct(algorithm);
    end
    
    
    cfg.FilterType = filt;
    cfg.option.GPUindex = GPUindex;
    do_pb = 1;
    
    
    if do_mask==1
        cfg.option.ReconstructionMaskId = astra_mex_data3d_c('create', '-vol', vol_geom, options.mask);
    end

else
    
    %Create vectors describing geometry
    vectors = zeros(numel(angles),12);
    
    %pause
    M = 1+R12(2)/R12(1);
    
    %VECTOR GEOMETRY - DISTANCES ARE RELATIVE TO VOXEL SIZE
    %source
    vectors(:,1) = sin(angles) * R12(1);
    vectors(:,2) = -cos(angles) * R12(1);
    vectors(:,3) = -mid_plane*pixel_size(2);

    % center of detector
    vectors(:,4) = (-sin(angles) * R12(2)) -dsx*pixel_size(1)*M*cos(angles);
    vectors(:,5) = (cos(angles) * R12(2)) -dsx*pixel_size(1)*M*sin(angles);
    vectors(:,6) = mid_plane*pixel_size(2)*R12(2)/R12(1);

     % vector from detector pixel (0,0) to (0,1)
     vectors(:,7) = cos(angles)*M*pixel_size(1);
     vectors(:,8) = sin(angles)*M*pixel_size(1) ;
     vectors(:,9) = 0;

     % vector from detector pixel (0,0) to (1,0)
     vectors(:,10) = 0;
     vectors(:,11) = 0;
     vectors(:,12) = M*pixel_size(2);    
    
     %Normalize to pixel size
     vectors = vectors/pixel_size(1);
    
% %    OLD CODE
% %     mid_plane = -3*pixel_size(2)
% %     %Normalize to pixel size
% %     
% %     % source
% %     vectors(:,1) = sin(angles) * R12(1)/pixel_size(1);
% %     vectors(:,2) = -cos(angles) * R12(1)/pixel_size(1);
% %     vectors(:,3) = 0*mid_plane/pixel_size(2);
% % 
% %     % center of detector
% %     vectors(:,4) = (-sin(angles) * R12(2) -dsx*cos(angles))/pixel_size(1);
% %     vectors(:,5) = (cos(angles) * R12(2) - dsx*sin(angles))/pixel_size(1);
% %     vectors(:,6) = 0*(0+dsy+mid_plane)/pixel_size(2);
% % 
% %      % vector from detector pixel (0,0) to (0,1)
% %      vectors(:,7) = cos(angles) * M;
% %      vectors(:,8) = sin(angles) * M;
% %      vectors(:,9) = 0;
% % 
% %      % vector from detector pixel (0,0) to (1,0)
% %      vectors(:,10) = 0;
% %      vectors(:,11) = 0;
% %      vectors(:,12) = M*pixel_size(2)/pixel_size(1);   
    
     
     %vectors = vectors*2;
     
    
    proj_geom = astra_struct('cone_vec');
    proj_geom.DetectorRowCount = size(s,3);
    proj_geom.DetectorColCount = size(s,1);
    proj_geom.Vectors = vectors;    
    vol_geom = astra_create_vol_geom([output_size(1), output_size(2),1]); %size(s,3)
    
    %mid_plane = 0*mid_plane/pixel_size(2)+300
    
    %vol_geom.option.WindowMinZ = vol_geom.option.WindowMinZ-7000;
    %vol_geom.option.WindowMaxZ = vol_geom.option.WindowMaxZ-7000;
    
    %vol_geom.option.WindowMinX = vol_geom.option.WindowMinX+300;
    %vol_geom.option.WindowMaxX = vol_geom.option.WindowMaxX+300;
    
    
    %vol_geom.option
    
    %cfg = astra_struct('FDK_CUDA');
    cfg = astra_struct(algorithm);
    cfg.option.GPUindex = GPUindex;
    
    if do_mask==1
        cfg.option.ReconstructionMaskId = astra_mex_data3d_c('create', '-vol', vol_geom, options.mask);
    end
    
    %pre filter sinograms  
    if strcmpi(algorithm(1:2), 'BP')
        s = filterProjections(s, filt, (R12(1)+R12(2)), pixel_size, angles, [dsx dsy+mid_plane]./M);
    end
    
    
    %cfg.FilterType = filt;
    do_pb = 0; 
end


%% RUN RECONSTRUCTION

%Check if there are more than 1 value of centre shift and No iterations
nsc = numel(centre_shift);
nsi = numel(iterations);
iterationsO = iterations;
if nsc>1 & nsi>1
   %error cannot loop over both
   errordlg('More than one value for centre shift and No. iterations. Can only loop over 1 variable at a time.')
   return;
    
end

[N, Nval] = max([nsc, nsi]);

r = zeros(output_size(1), output_size(2), N, 'single');

if show_wb
    wbopt.Title = 'central_slice_astra';
    wbopt.InfoString = 'Reconstructing slices..';
    wb = TTwaitbar(0, wbopt);
end

ang_block = floor(size(s,2)/floor(((numel(s)+output_size(1)*output_size(2))*8)/(gpu_mem_limit*1024*1024)));
ang_blocks = 1:ang_block:size(s,2);
if ang_blocks(end)<size(s,2)
    ang_blocks = [ang_blocks size(s,2)];
end


%Reconstruct
for n = 1:N  
    if Nval==1
        fprintf(1, ['Reconstructing with centre shift = ' num2str(centre_shift(n)) '...']);
    else
       fprintf(1, ['Reconstructing with No. iterations = ' num2str(iterationsO(n)) '...']);
    end
    
    if do_mask==2
        if Nval==1
            cs = centre_shift(n);
        else
            cs = centre_shift;
        end
        options.mask = single((X.^2 + Y.^2 < (minR-abs(cs))^2));
        options.mask = repmat(options.mask, [1 1 1]);%size(s,3)
        if strcmpi(centre_shift_mode, 'fft') 
            cfg.option.ReconstructionMaskId = astra_mex_data2d_c('create', '-vol', vol_geom, options.mask);
        else
            cfg.option.ReconstructionMaskId = astra_mex_data3d_c('create', '-vol', vol_geom, options.mask);
        end
    end
    %imager(s1)
    %pause
    if do_pb
        proj_geom1 = proj_geom;
        
        if Nval==1 %DENTRE SHIFT
            cs = centre_shift(n);
        else %ITERATIONS
            cs = centre_shift(1);
            iterations = iterationsO(n);
        end
       
        %%s1 = sinogram_shift(s, shifts+centre_shift(n)); 
        
        %class(s)
        %s = zeros(1984,721,1,'single');
        %size(s)
        %assignin('base', 'proj_geom2', proj_geom1);
        if strcmpi(centre_shift_mode, 'fft') 
            s1 = filterProjections(s, filt, Inf, 1, angles, [0 0], cs);
            proj_geom1 = proj_geom;
            sino_id = astra_mex_data2d('create','-sino', proj_geom1, s1');
            rec_id = astra_mex_data2d('create', '-vol', vol_geom);
            cfg.ProjectionDataId = sino_id;
            cfg.ReconstructionDataId = rec_id;
            
            alg_id = astra_mex_algorithm('create', cfg);
            tic;
            astra_mex_algorithm('run', alg_id, iterations);
            r(:,:,n) = astra_mex_data2d('get', rec_id);
        else                       
            proj_geom1.Vectors(:,4) = proj_geom.Vectors(:,4) -cs*cos(angles);
            proj_geom1.Vectors(:,5) = proj_geom.Vectors(:,5) -cs*sin(angles);
            sino_id = astra_mex_data3d('create','-sino', proj_geom1, s);
            rec_id = astra_mex_data3d('create', '-vol', vol_geom);

            cfg.ProjectionDataId = sino_id;
            cfg.ReconstructionDataId = rec_id;

            alg_id = astra_mex_algorithm('create', cfg);
            tic;
            astra_mex_algorithm('run', alg_id, iterations);
            r(:,:,n) = astra_mex_data3d('get', rec_id);
            astra_mex_data2d('delete', sino_id);
            astra_mex_data2d('delete', rec_id);
            astra_mex_algorithm('delete', alg_id);
        end
        t = toc;
        fprintf(1, ['Done in ' num2str(t) 's.\n']);
        
        
    else
        %s1 = sinogram3D_shift(s, shifts+centre_shift(n)); 
        
        proj_geom1 = proj_geom;
        if Nval==1 %DENTRE SHIFT
            cs = centre_shift(n); 
        else %ITERATIONS
            cs = centre_shift(1);
            iterations = iterationsO(n);
        end
        %Update geometry
        proj_geom1.Vectors(:,4) = proj_geom.Vectors(:,4) -cs*cos(angles(:));
        proj_geom1.Vectors(:,5) = proj_geom.Vectors(:,5) -cs*sin(angles(:));        
        
        
        for nangs = 1:numel(ang_blocks)-1
            
        proj_geom2 = proj_geom1;
        proj_geom2.Vectors = proj_geom2.Vectors(ang_blocks(nangs):ang_blocks(nangs+1)-1,:);
            
        sino_id = astra_mex_data3d('create','-sino', proj_geom2, s(:,ang_blocks(nangs):ang_blocks(nangs+1)-1,:));
        rec_id = astra_mex_data3d('create', '-vol', vol_geom);
        
        cfg.ProjectionDataId = sino_id;
        cfg.ReconstructionDataId = rec_id;
    
        alg_id = astra_mex_algorithm('create', cfg);
        tic;
        astra_mex_algorithm('run', alg_id, iterations);
        tmp = astra_mex_data3d('get_single', rec_id);
 
        
        r(:,:,n) = r(:,:,n)+tmp(:,:,round(size(tmp,3)/2));
        
        astra_mex_data3d('delete', sino_id);
        astra_mex_data3d('delete', rec_id);
        astra_mex_algorithm('delete', alg_id);
        end
        toc
    end
    
    
    if do_mask>0
        r(:,:,n) = r(:,:,n).*options.mask(:,:,1);
    end
    
    if show_wb
       TTwaitbar(n/N, wb); 
    end
    %pause
end

if show_wb
     close(wb);
end

mask = options.mask;


%astra_mex_data2d('delete', rec_id);


