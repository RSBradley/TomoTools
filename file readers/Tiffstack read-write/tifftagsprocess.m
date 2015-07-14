function info = tifftagsprocess ( info )
% TIFFTAGSPROCESS Processes raw TIFF tags into human-readable form
%
%   INFO = TIFFTAGSPROCESS(TAGS) processes the cell array TAGS into a 
%   structure with name/value pairs.  There will be one structure for
%   each image in the image file.  If one of the tag elements
%   indicates a sub IFD, then the resulting name/value pair will consist
%   of another structure of name/value pairs.
%
%   Unrecognized tags are placed into a field called 'UnknownTags'.
%
%   See also TIFFTAGSREAD, IMFINFO

%   Copyright 2008-2011 The MathWorks, Inc.
%   $Revision: 1.1.8.12 $  $Date: 2011/07/20 00:01:54 $


num_ifds = numel(info);
if num_ifds > 0 
	if isfield ( info(1), 'DigitalCamera' )
		info(1).DigitalCamera = exiftagsprocess ( info(1).DigitalCamera );
	end
	if isfield ( info(1), 'GPSInfo' )
		info(1).GPSInfo = gpstagsprocess ( info(1).GPSInfo );
	end
end



return




function info = exiftagsprocess ( info )
% EXIFTAGSPROCESS Processes raw exif tags into human-readable form
%
%   INFO = EXIFTAGSPROCESS(TAGS) processes the cell array TAGS into a
%   structure with name/value pairs.  There will be one structure for
%   each image in the image file.  If one of the tag elements
%   indicates a sub IFD, then the resulting name/value pair will consist
%   of another structure of name/value pairs.
%
%   Unrecognized tags are placed into a field called 'UnknownTags'.
%

%   Copyright 2008 The MathWorks, Inc.


num_ifds = numel(info);
for j = 1:num_ifds
    
    tagnames = fieldnames(info(j));
    
    
    for k = 1:numel(tagnames)
        
        switch ( tagnames{k} )
            
            case 'ExposureProgram'
                info(j).ExposureProgram = process_ExposureProgram(info(j).ExposureProgram);
                
            case 'OECF'
                info(j).OECF = char(info(j).OECF)';
                
            case 'ComponentsConfiguration'
                info(j).ComponentsConfiguration = handleComponentsConfiguration(info(j).ComponentsConfiguration);
                
            case 'MeteringMode'
                info(j).MeteringMode = handleMeteringMode(info(j).MeteringMode);
                
            case 'LightSource'
                info(j).LightSource = handleLightSource(info(j).LightSource);
                
            case 'Flash'
                info(j).Flash = handleFlash(info(j).Flash);
                
            case 'UserComment'
                info(j).UserComment = info(j).UserComment';
                
            case 'FlashPixVersion'
                info(j).FlashPixVersion = handleFlashPixVersion(info(j).FlashPixVersion);
                
            case 'ColorSpace'
                info(j).ColorSpace = handleColorSpace(info(j).ColorSpace);
                
            case 'SensingMethod'
                info(j).SensingMethod = handleSensingMethod(info(j).SensingMethod);
                
            case 'FileSource'
                info(j).FileSource = handleFileSource(info(j).FileSource);
                
            case 'SceneType'
                info(j).SceneType = handleSceneType(info(j).SceneType);
                
            case 'CustomRendered'
                info(j).CustomRendered = handleCustomRendered(info(j).CustomRendered);
                
            case 'ExposureMode'
                info(j).ExposureMode = handleExposureMode(info(j).ExposureMode);
                
            case 'WhiteBalance'
                info(j).WhiteBalance = handleWhiteBalance(info(j).WhiteBalance);
                
            case 'SceneCaptureType'
                info(j).SceneCaptureType = handleSceneCaptureType(info(j).SceneCaptureType);
                
            case 'GainControl'
                info(j).GainControl = handleGainControl(info(j).GainControl);
                
            case 'Contrast'
                info(j).Contrast = handleContrast(info(j).Contrast);
                
            case 'Saturation'
                info(j).Saturation = handleSaturation(info(j).Saturation);
                
            case 'Sharpness'
                info(j).Sharpness = handleSharpness(info(j).Sharpness);
                
            case 'DeviceSettingDescription'
                info(j).DeviceSettingDescription = ...
                    handleDeviceSettingDescription(info(j).DeviceSettingDescription);
                
            case 'SubjectDistanceRange'
                info(j).SubjectDistanceRange = handleSubjectDistanceRange(info(j).SubjectDistanceRange);
                
                
        end % switch
        
    end % loop through current ifd
    
    
end % loop through IFD list

return










%===============================================================================
function y = handleFlash(x)

%
% did the flash fire
if bitand(x,1)
    y = 'Flash fired, ';
else
    y = 'Flash did not fire, ';
end

%
% status of return light
switch bitshift ( bitand(x,6), -1 )
case 0
    y = [y 'no strobe return detection function, ']; %#ok<I18N_Concatenated_Msg>
case 1
    y = [y 'reserved, '];
case 2
    y = [y 'strobe return light not detected, ']; %#ok<I18N_Concatenated_Msg>
case 3
    y = [y 'strobe return light detected, ']; %#ok<I18N_Concatenated_Msg>
end

%
% camera flash mode
switch bitshift ( bitand(x,24), -3 )
case 0
    y = [y 'unknown flash mode, ']; %#ok<I18N_Concatenated_Msg>
case 1
    y = [y 'compulsory flash firing, ']; %#ok<I18N_Concatenated_Msg>
case 2
    y = [y 'compulsory flash suppression, ']; %#ok<I18N_Concatenated_Msg>
case 3
    y = [y 'auto flash mode, ']; %#ok<I18N_Concatenated_Msg>
end

%
% presence of flash function
if bitshift ( bitand(x,32), -4 )
    y = [y 'no flash function, ']; %#ok<I18N_Concatenated_Msg>
else
    y = [y 'flash function present, ']; %#ok<I18N_Concatenated_Msg>
end

%
% red-eye mode
switch bitshift ( bitand(x,64), -5 )
case 0
    y = [y 'no red-eye reduction mode or unknown.']; %#ok<I18N_Concatenated_Msg>
case 1
    y = [y 'red-eye reduction mode supported.']; %#ok<I18N_Concatenated_Msg>
end

%===============================================================================
function y = handleComponentsConfiguration(x)
%
% x is a series of integers, such as [4 5 6 0], which means RGB.

if (any(x<0) || any(x>6))
    warning (message('MATLAB:imagesci:tifftagsprocess:invalidComponentsConfiguration'));
	y = x;
	return;
end

%
% remove any zeros
x(x==0) = [];

components(1,1:2) = 'Y ';
components(2,1:2) = 'Cb';
components(3,1:2) = 'Cr';
components(4,1:2) = 'R ';
components(5,1:2) = 'G ';
components(6,1:2) = 'B ';

y = components(x,1:2)';
y(y==' ') = [];

%
% Believe it or not that was a lot faster than
%
%for j = 1:numel(x)
%	y = [y components{x(j)}];
%end
%
% or 
%
% strcat



%===============================================================================
function y = process_ExposureProgram(x)

%
% Have seen at least one image where ExposureProgram was incorrect (more than a single
% value).  Rather than abort, just return the value as is.
if numel(x) > 1
    y = x;
    return;
end

switch ( x )
    case 0
        y = 'Not defined';
    case 1
        y = 'Manual';
    case 2
        y = 'Normal program';
    case 3
        y = 'Aperture priority';
    case 4
        y = 'Shutter priority';
    case 5
        y = 'Creative program (biased toward depth of field)';
    case 6
        y = 'Action program (biased toward fast shutter speed)';
    case 7
        y = 'Portrait mode (for closeup photos with the background out of focus)';
    case 8
        y = 'Landscape mode (for landscape photos in the background in focus)';
    otherwise
        warning (message('MATLAB:imagesci:tifftagsprocess:invalidExposureProgramValue'));
        y = x;
end



%===============================================================================
function y = handleMeteringMode(x)
    switch ( x )
        case 0
            y = 'unknown';
        case 1
            y = 'Average';
        case 2
            y = 'CenterWeightedAverage';
        case 3
            y = 'Spot';
        case 4
            y = 'Multispot';
        case 5
            y = 'Pattern';
        case 6
            y = 'Partial';
        case 255
            y = 'other';
        otherwise
            y = x;
    end

%===============================================================================
function y = handleLightSource(x)
switch ( x )
    case 0
        y = 'unknown';
    case 1
        y = 'Daylight';
    case 2
        y = 'Fluorescent';
    case 3
        y = 'Tungsten (incandescent light)';
    case 4
        y = 'Flash';
    case 9
        y = 'Fine weather';
    case 10
        y = 'Cloudy weather';
    case 11
        y = 'Shade';
    case 12
        y = 'Daylight fluorescent (D 5700 - 7100K)';
    case 13
        y = 'Daylight fluorescent (N 4600 - 5400K)';
    case 14
        y = 'Daylight fluorescent (W 3900 - 4500K)';
    case 15
        y = 'Daylight fluorescent (WW 3200 - 3700K)';
    case 17
        y = 'Standard light A';
    case 18
        y = 'Standard light B';
    case 19
        y = 'Standard light C';
    case 20
        y = 'D55';
    case 21
        y = 'D65';
    case 22
        y = 'D75';
    case 23
        y = 'D50';
    case 24
        y = 'ISO studio tungsten';
    case 255
        y = 'other light source';
    otherwise
        y = x;
end
%===============================================================================
function y = handleFlashPixVersion(x)
if strcmp(char(x'),'0100')
    y = 'Flashpix Format Version 1.0';
else
    y = x';
end
%===============================================================================
function y = handleColorSpace(x)
switch ( x )
    case 1
        y = 'sRGB';
    case 65535
        y = 'Uncalibrated';
    otherwise
        y = x;
end

%===============================================================================
function y = handleSensingMethod(x)
switch ( x )
    case 1
        y = 'Not defined';
    case 2
        y = 'One-chip color area sensor';
    case 3
        y = 'Two-chip color area sensor';
    case 4
        y = 'Three-chip color area sensor';
    case 5
        y = 'Color sequential area sensor';
    case 7
        y = 'Trilinear sensor';
    case 8
        y = 'Color sequential linear sensor';
    otherwise
        y = x;
end

%===============================================================================
function y = handleFileSource(x)
 switch ( x )
     case 3
         y = 'DSC';
     otherwise
         y = x;
 end

%===============================================================================
function y = handleSceneType(x)
switch ( x )
    case 1
        y = 'A directly photographed image';
    otherwise
        y = x;
end

%===============================================================================
function y = handleCustomRendered(x)
switch ( x )
    case 0
        y = 'Normal process';
    case 1
        y = 'Custom process';
    otherwise
        y = x;
end

%===============================================================================
function y = handleExposureMode(x)
switch ( x )
    case 0
        y = 'Auto exposure';
    case 1
        y = 'Manual exposure';
    case 2
        y = 'Auto bracket';
    otherwise
        y = x;
end

%===============================================================================
function y = handleWhiteBalance(x)
switch ( x )
    case 0
        y = 'Auto white balance';
    case 1
        y = 'Manual white balance';
    otherwise
        y = x;
end

%===============================================================================
function y = handleSceneCaptureType(x)
switch ( x )
    case 0
        y = 'Standard';
    case 1
        y = 'Landscape';
    case 2
        y = 'Portrait';
    case 3
        y = 'Night scene';
    otherwise
        y = x;
end

%===============================================================================
function y = handleGainControl(x)
switch ( x )
    case 0
        y = 'None';
    case 1
        y = 'Low gain up';
    case 2
        y = 'High gain up';
    case 3
        y = 'High gain down';
    otherwise
        y = x;
end

%===============================================================================
function y = handleContrast(x)
switch ( x )
    case 0
        y = 'Normal';
    case 1
        y = 'Soft';
    case 2
        y = 'Hard';
    otherwise
        y = x;
end

%===============================================================================
function y = handleSaturation(x)
switch ( x )
    case 0
        y = 'Normal';
    case 1
        y = 'Low Saturation';
    case 2
        y = 'High Saturation';
    otherwise
        y = x;
end

%===============================================================================
function y = handleSharpness(x)
switch ( x )
    case 0
        y = 'Normal';
    case 1
        y = 'Soft';
    case 2
        y = 'Hard';
    otherwise
        y = x;
end

%===============================================================================
function y = handleDeviceSettingDescription(x)
switch ( class(x) )
    case 'uint16'
        y = x';
    otherwise
        y = unicode2native(char(x));
end

%===============================================================================
function y = handleSubjectDistanceRange(x)
switch ( x )
    case 0
        y = 'unknown';
    case 1
        y = 'Macro';
    case 2
        y = 'Close view';
    case 3
        y = 'Distant view';
    otherwise
        y = x;
end




%===============================================================================
function GPSInfo = gpstagsprocess ( GPSInfo )
% GPSTAGSPROCESS processes GPS tags into human-readable form.
%
%   INFO = GPSTAGS(TAGS) transforms an array of raw TIFF
%   tags TAGS into a name/value structure of tag values.
%
%   See also TIFFTAGSREAD, IMFINFO

%   Copyright 2008 The MathWorks, Inc.

%
% For some tags, we take no action.

tagnames = fieldnames(GPSInfo);
for j = 1:numel(tagnames)
	x = GPSInfo.(tagnames{j});
    switch ( tagnames{j} )
        case 1
			GPSInfo.(tagnames{j}) = handleGPSLatitudeRef(x);

        case 2
            GPSInfo.(tagnames{j}) = x';

        case 3
			GPSInfo.(tagnames{j}) = handleGPSLongitudeRef(x);

        case 4
            GPSInfo.(tagnames{j}) = x';

        case 5
			GPSInfo.(tagnames{j}) = handleGPSAltitudeRef(x);

        case 7
            GPSInfo.(tagnames{j}) = x';

        case 9
			GPSInfo.(tagnames{j}) = handleGPSStatus(x);

        case 10
			GPSInfo.(tagnames{j}) = handleGPSMeasureMode(x);

        case 12
			GPSInfo.(tagnames{j}) = handleGPSSpeedRef(x);

        case 14
			GPSInfo.(tagnames{j}) = handleGPSTrackRef(x);

        case 16
			GPSInfo.(tagnames{j}) = handleGPSImgDirectionRef(x);

        case 19
			GPSInfo.(tagnames{j}) = handleGPSDestLatitudeRef(x);

        case 20
            GPSInfo.(tagnames{j}) = x';

        case 21
			GPSInfo.(tagnames{j}) = handleGPSDestLongitudeRef(x);

        case 22
            GPSInfo.(tagnames{j}) = x';

        case 23
			GPSInfo.(tagnames{j}) = handleGPSDestBearingRef(x);

        case 25
			GPSInfo.(tagnames{j}) = handleGPSDestDistanceRef(x);

        case 27
            GPSInfo.(tagnames{j}) = x';
        case 28
            GPSInfo.(tagnames{j}) = x';

        case 30
			GPSInfo.(tagnames{j}) = handleGPSDifferential(x);


    end
end



%===============================================================================
function y = handleGPSLatitudeRef(x)
switch ( deblank(x) )
    case 'N'
        y = 'North latitude';
    case 'S'
        y = 'South latitude';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSLongitudeRef(x)
switch ( deblank(x) )
    case 'E'
        y = 'East longitude';
    case 'W'
        y = 'West longitude';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSAltitudeRef(x)
switch ( x )
    case 0 
        y = 'Sea level';
    case 1
        y = 'Sea level reference (negative value)';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSStatus(x)
switch ( deblank(x) )
    case 'A'
        y = 'Measurement in progress';
    case 'V'
        y = 'Measurement interoperability';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSMeasureMode(x)
switch ( deblank(x) )
    case '2'
        y = '2-dimensional measurement';
    case '3'
        y = '3-dimensional measurement';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSSpeedRef(x)
switch ( deblank(x) )
    case 'K'
        y = 'Kilometers per hour';
    case 'M'
        y = 'Miles per hour';
    case 'N'
        y = 'Knots';
    otherwise 
        y = x;
end

%===============================================================================
function y = handleGPSTrackRef(x)
switch ( deblank(x) )
    case 'T'
        y = 'True direction';
    case 'M'
        y = 'Magnetic direction';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSImgDirectionRef(x)
switch ( deblank(x) )
    case 'T'
        y = 'True direction';
    case 'M'
        y = 'Magnetic direction';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSDestLatitudeRef(x)
switch ( deblank(x) )
    case 'N'
        y = 'North latitude';
    case 'S'
        y = 'South latitude';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSDestLongitudeRef(x)
switch ( deblank(x) )
    case 'E'
        y = 'East longitude';
    case 'W'
        y = 'West longitude';
    otherwise 
		y = x;
end

%===============================================================================
function y = handleGPSDestBearingRef(x)
switch ( deblank(x) )
    case 'T'
        y = 'True direction';
    case 'M'
        y = 'Magnetic direction';
    otherwise 
        y = x;
end

%===============================================================================
function y = handleGPSDestDistanceRef(x)
switch ( deblank(x) )
    case 'K'
        y = 'Kilometers';
    case 'M'
        y = 'Miles';
    case 'N'
        y = 'Knots';
    otherwise 
        y = x;
end

%===============================================================================
function y = handleGPSDifferential(x)
switch ( x )
    case 0
        y = 'Measurement without differential correction';
    case 1
        y = 'Differential correction applied';
    otherwise
        y = x;
        
end

