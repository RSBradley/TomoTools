function [info fmt_fns aqmodekey]= txmheader_info8(varargin)

%Cell array listing the header data contained in the Xradia files and the
%corresponding data type, length of data, and format
%Written by: Rob Bradley, (c) 2010

        info = {'Version', 'float32', 4, [];               %Version number of txmcontroller
                'NoOfImages', 'int32', 4, [];                %Number of images taken
               'ImagesTaken', 'int32', 4, [];               %Number of images taken
               'AcquisitionMode', 'int32', 4, [];           %Aquisition mode e.g. tomography, averaging...
               'ReadOutTime', 'int32', 4, [];               %Camera read out time
               'HorizontalBin', 'int32', 4, [];             %Camera binning in horizontal direction
               'VerticalalBin', 'int32', 4, [];             %Camera binning in vertical direction
               'Temperature', 'int32', 4, [];               %Camera temperature
               'SourceVoltage', 'int32', 4, [];             %Source voltage
               'Voltage', 'int32', 4, [];                   %Source voltage
               'Current', 'int32', 4, [];                   %Source current
               'ImageWidth', 'int32', 4, [];                %Width of image in pixels
               'ImageHeight' 'int32', 4, [];                %Height of image in pixels
               'DataType', 'int32', 4, [];                  %Image datatype e.g. 5 (int16)
               'NoOfImagesAveraged', 'int32', 4, [];        %Number of images averaged
               'PixelSize', 'float32', 4, [];               %Size of pixels in microns
               'PixelSizeX', 'float32', 4, [];              %Relative size of pixels in x direction
               'PixelSizeY', 'float32', 4, [];              %Relative size of pixels in y direction
               'CameraNo', 'int32', 4, [];                  %Index of camera if more than 1
               'Angles', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};                  %Sample rotation angles for the image sequence
               'ExpTimes', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};                %Exposure times for the corresponding images
               'XPosition', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};               %Sample x positions for the image sequence
               'YPosition', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};               %Sample y positions for the image sequence
               'ZPosition', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};               %Sample z positions for the image sequence
               'TubelensPosition', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};        %Tube lens position for the image sequence (nanoXCT only)
               'IonChamberCurrent', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};       %Ion chamber current for the image sequence (nanoXCT only)
               'Energy', 'float32', 4, [];                  %X-ray energy (nanoXCT only)
               'NanoImageMode', 'int32', 4, [];             %1 or 0 if using/not using nanoXCT (nanoXCT only)?
               'StoRADistance', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};           %Source to rotation axis distances for the image sequence 
               'DtoRADistance', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};           %Detector to rotation axis distances for the image sequence 
               'UseForRADistances', 'float32', 4, [];       %Detector to rotation axis distances for the image sequence?
               'OpticalMagnification', 'float32', 4, [];    %Optical magnification used (nanoXCT only?)
               'MosiacRows', 'int32', 4, [];                %Number of mosiac rows
               'MosiacColumns', 'int32', 4, [];             %Number of mosiac columns
               'MosiacMode', 'int32', 4, [];                %1 or 0 if in/not in mosaic mode
               'MosaicFastAxis', 'int32', 4, [];            %Fast axis if in mosiac mode
               'MosaicSlowAxis', 'int32', 4, [];            %Slow axis if in mosiac mode
               'BigOrSmallSampleHolder', 'int32', 4, [];    %Not used?
               'FocusTarget', 'int32', 4, [];               %Not used?
               'ReferenceFile', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};        %Reference file name (white reference/ flat field image)
               'BackgroundFile', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};       %Background file name (black background image)
               'Date', 'char=>char', 1, {'matchstr', {'\d\d/\d\d/\d\d\W\d\d:\d\d:\d\d'}};                 %Date tomography was started
               'SampleInfo','char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};            %Information supplied by user about the sample
               'Analyst', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};              %Name of analyst
               'Facility', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};             %Name of facility
               'SampleID', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};             %Sample ID
               'DateIn', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};               %Sample in date                                        '
               'DateOut', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};              %Sample out date                                '
               'FailureInfo', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};          %Information if failure occurs?
               'ProcessInfo',  'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};         %Information about current process?
               'PositionInfo', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};         %Information about current position?
               'NoOfImages_', 'int32', 4, [];               %Number of images taken
               'TotalAxis', 'int32', 4, [];                 %Number of system component axes
               'MotorPositions', 'float32', 4, {'resize',{'[header.PositionInfo.TotalAxis header.ImageInfo.NoOfImages]'}};          %Motor positions?
               'HomeOffset', 'int32', 4, [];                %Home positions for the system component axes (in nm for nanoXCT)
               'AxisNames', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}; 'resize', {'[header.PositionInfo.TotalAxis 1]'}}; %{[char(256) '|' char(0)], 1}
               'AxisUnits', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}; 'resize', {'[header.PositionInfo.TotalAxis 1]'}}; %Names of the axes
               'StageCalibration', 'int32', 4, [];          %The stage position is (1) or is not (0) calibrated to give a virtual axis of rotation (nanoXCT only)
               'XValue', 'float32', 4, [];                  %X-value used in the stage calibration
               'ZValue', 'float32', 4, [];                  %Z-value used in the stage calibration
               'Annotations', 'float32', 4, [];             %Information about annotations?
               'AnnSize', 'int32', 4, [];                   %Size of annotations?
               'AnnData', 'int32', 4, [];                   %Annotation data?
               'AutoRecon', 'int32', 4, [];                 %Do or don't do automatic reconstruction
               'CenterShift', 'float32', 4, [];             %Center shift (rotation axis position) for reconstruction
               'AutoReconON', 'int32', 4, [];               %Do automatic reconstruction?
               'ReconBinning', 'int32', 4, [];              %Binning used for reconstruction
               'ReconDataType', 'int32', 4, [];             %Datatype used for reconstruction
               'RemoveRingON', 'int32', 4, [];              %Apply (1) or don't apply (0) ring artefact removal
               'MaximizeVolume', 'int32', 4, [];            %Unknown reconstruction variable 
               'BeamHardening', 'float32', 4, [];           %Beam hardening constant used for reconstruction
               'RotationAngle', 'float32', 4, [];           %Angle to rotate by for reconstruction
               'ReconFilter', 'int32', 4, [];               %Use (1) or don't use (0) reconstruction filter
               'GlobalMin', 'float32', 4, [];               %Global minimum used for reconstruction
               'GlobalMax', 'float32', 4, [];               %Global maximum used for reconstruction      
               'NumOfProjects', 'int32', 4, [];             %Number of projection images used for reconstruction
               'AngleSpan', 'float32', 4, [];               %Angle span of projection images?
               'MeanSampleX', 'float32', 4, [];             %Mean sample X position?
               'MeanSampleY', 'float32', 4, [];             %Mean sample Y position?
               'MeanSampleZ', 'float32', 4, [];             %Mean sample Z position?
               'ReferenceData', 'float32', 4, [];           %Unknown
               'Binning', 'int32', 4, [];                   %Binning for reference image?
               'DataType_', 'int32', 4, [];                 %Datatype for reference image?
               'ExpTime', 'float32', 4, [];                 %Exposure time for reference image?
               'IonCurrent', 'float32', 4, [];              %Ion current for reference image? (nanoXCT only)
               'BGAdjustments', 'int32', 4, [];             %Unknown
               'RefS2RADistance', 'float32', 4, [];         %Source to rotation axis distance for reference image?
               'RefD2RADistance', 'float32', 4, [];         %Detector to rotation axis distance for reference image?
               'Alignment', 'int32', 4, [];                 %Unknown
               'X_Shifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};                %Alignment shifts in x direction (nanoXCT only)
               'Y_Shifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};                %Alignment shifts in y direction (nanoXCT only)
               'Selection', 'int32', 4, [];                 %Unknown
               'SelectedImages', 'int32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};            %Images in sequence selected for reconstruction etc (0 for unselected, 1 for selected)
               'SineFitCenter', 'int32', 4, [];             %Unknown
               'SineFitCenterX', 'float32', 4, [];          %Sine fit x-value for virtual centre of rotation? (nanoXCT only)
               'SineFitCenterY', 'float32', 4, [];          %Sine fit y-value for virtual centre of rotation? (nanoXCT only)
               'CameraName', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};
               'XrayMagnification', 'float32', 4, [];
               'XrayVoltage', 'float32', 4,{'resize',{'[1 header.ImageInfo.NoOfImages]'}};
               'XrayCurrent', 'float32', 4,{'resize',{'[1 header.ImageInfo.NoOfImages]'}};
               
               'DageVoltages', 'float32', 4,[];
               'DagePowers', 'float32', 4,[];
               'DageCenteringX', 'float32', 4, [];
               'DageCenteringY', 'float32', 4, [];
               'DageVacuumLevel','float32', 4, [];
               'DageTubeCurrents','float32', 4, [];
               'DageFocusCurrent','float32', 4, [];
               'DageHoursOnTarget','float32', 4, [];
               'DageTargetCurrents','float32', 4, [];
               'DageTargetTurnNumber','int32', 4, [];
               
               'Temperatures','float32', 4, {'resize',{'[header.TemperatureInfo.TotalAxis header.ImageInfo.NoOfImages]'}};
               'StageShiftsApplied', 'int32', 4, [];        %Stage shifts are applied
               'MetrologyShiftsApplied', 'int32', 4, [];        %Metrology shifts are applied
               'ReferenceShiftsApplied', 'int32', 4, [];        %Reference shifts are applied
               'SourceDriftApplied', 'int32', 4, [];            %Source drift shifts are applied
               'EnableDistortionCorrection', 'int32', 4, [];        %Enable Distortion correction (relating to image distortion by optics)
               'PinholeCondenserSafetyConstant','float32', 4, [];   %Unknown (nanoXCT only)?
               'EncoderShiftsApplied', 'int32', 4, [];              %Motor Encoder shifts are applied
               'EncoderXShifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};          %Encoder X shifts
               'EncoderYShifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};          %Encoder Y shifts
               'StageXShifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};            %Stage X shifts
               'StageYShifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};            %Stage Y shifts
               'UseDithering', 'int32', 4, [];              %Use Dithering
               'Dither', 'int32', 4, [];                    %Use Dithering?
               'DitherXShifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};           %Dithering X shifts
               'DitherYShifts', 'float32', 4, {'resize',{'[1 header.ImageInfo.NoOfImages]'}};           %Dithering y shifts
               
               'SampleStackOrientation','int32', 4, [];             %Unknown
               'BigSampleYPosForSmallSample','int32', 4, [];        %Unknown
               'SmallSampleYPosForBigSample','int32', 4, [];        %Unknown
               'SourceLimitForBigSample','int32', 4, [];            %Unknown
               'DetectorLimitForBigSample','int32', 4, [];          %Unknown
               'HiResCameraPresetX','int32', 4, [];        %Unknown
               'HiResCameraPresetY','int32', 4, [];        %Unknown
               'SmallSampleCameraPresetZ','int32', 4, [];           %Unknown
               'LoResCameraPresetX','int32', 4, [];        %Unknown
               'LoResCameraPresetY','int32', 4, [];        %Unknown
               'BigSampleCameraPresetZ','int32', 4, [];             %Unknown
               'SourcePresetZForBigSample','int32', 4, [];          %Unknown
               'SourcePresetZForSmallSample','int32', 4, [];        %Unknown
               'BigSampleDistanceToSmall','int32', 4, [];           %Unknown
               'Motorized_Objective','int32', 4, [];                %Unknown
               'HeatedSample','int32', 4, [];               %Unknown
               'ComPortNumberForHeatedSample','int32', 4, [];       %Unknown
               'LoResCameraPresetZ','int32', 4, [];         %Unknown
               'HiResCameraPresetZ','int32', 4, [];         %Unknown
               'DetectorLimitSmallSampleLowResC','float32', 4, [];        %Unknown
               'SafetyDistance','float32', 4, [];           %Unknown
               'CameraX', 'float32', 4, [];                 %Unknown
               'CameraZ', 'float32', 4, [];                 %Unknown              
               'BeamLine', 'int32', 4, [];                  %Unknown
               
               'ZonePlateAlignmentPiezos', 'int32', 4, [];
               'ZonePlateAlignmentComPort', 'int32', 4, [];
               'DistortionParamLength', 'int32', 4, [];
               'DistortionWidth', 'int32', 4, [];
               'DistortionHeight', 'int32', 4, [];
               'DistortionParam', 'float32', 4, [];
               
               'Stage', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}}; 
               'BeamHardeningFileName', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}}; 
               'UserMinMax', 'float32', 4, [];
               
               'CropWidth', 'int32', 4, [];
               'CropHeight', 'int32', 4, [];
               'DefectCorrection', 'int32', 4 [];
               'Material', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}};  
               'ObjectiveName', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}}; 
               'PositiveRotationLimit', 'float32', 4, [];
               'NegativeRotationLimit', 'float32', 4, [];
               'TransmissionScaleFactor', 'float32', 4, [];
               'AbsorptionScaleFactor', 'float32', 4, [];
               'AbsorptionScaleOffset', 'float32', 4, [];
               'RefTypeToApplyIfAvailable', 'int32', 4 [];
               'OriginalDataRefCorrected',  'int32', 4 [];
               'Resolution', 'float32', 4, [];
               'MaxVelocity', 'float32', 4, [];
               'PosLimits', 'float32', 4, [];
               'NegLimits', 'float32', 4, [];
               'Axis', 'char=>char', 1, {'splitstr', {[char(256) '|' char(0)], 1}}; 
               'ThirdOrderRotationLimit', 'float32', 4, [];
               'IonChamberConstant', 'float32', 4, [];
               'ZoneplatePos', 'float32', 4, [];
               'TubeLensPos', 'float32', 4, [];
               'DefaultCenterShift', 'float32', 4, [];
               'DetectorOffset', 'float32', 4, [];
               'AxisInUse', 'int32', 4 [];
               'RefInterval','int32', 4 [];
               'TotalRefImages','int32', 4 [];
               
               'ID','int32', 4 [];
               'XradiaID','int32', 4 [];
               'Unit','int32', 4 [];
               'Mode','int32', 4 [];
               'Arrow','int32', 4 [];
               'BacklashCorrection','float32', 4 [];
               'HomingRoutine','int32', 4 [];
               'EnableFlyScan','int32', 4 [];
               'DisableDuringAcquisition','int32', 4 [];
              
               'Minimum', 'float32', 4, [];                 %Minimum reconstructed value?
               'Maximum', 'float32', 4, []};                %Maximum reconstructed value?

           
%Create structure of handles for formatting functions         
fmt_fns.resize = @resize;          
fmt_fns.matchstr = @matchstr;          
fmt_fns.splitstr = @splitstr;

aqmodekey = {0, 'Tomography';
             2, 'Single';
             3, 'Continuous';
             4, 'Focal Series';
             5, 'Background'; %Check
             6, 'Averaging';
             7, 'Mosaic'};

if nargin==0

    return;

else
    data_name = varargin{1};    
    ind = find(cell2mat(cellfun(@(x) strcmpi(x,data_name), info(:,1), 'UniformOutput',0)));
    if ~isempty(ind)
        info = info(ind,:);
    else
        error([data_name ' is not a correct header name.']);
    end     
end

%


%Nested formatting functions
    function data_out = resize(data, dims_str)        
        
        try
            data_dims = evalin('caller', dims_str);
            data_out = reshape(data(1:prod(data_dims)), data_dims)';
        catch
            data_out = data;
        end    
    end
        
    function data_out = matchstr(data, expr)
            
        data_out = regexp(data, expr, 'match')';  

    end

    function data_out = splitstr(data, varargin)
       
        if isempty(data)
            data_out = [];
            return;
        end
             
        expr = varargin{1};
        rem_rep = varargin{2};
        data_out = regexp(data, expr, 'split')';
        %pause
        %data_out{1}
        if rem_rep
            data_out(cellfun(@isempty, data_out))=[];
        end   
        if numel(data_out)==1
           data_out = data_out{1};           
        elseif numel(data_out)==0
           data_out = []; 
        end
        
    end

   
    
end