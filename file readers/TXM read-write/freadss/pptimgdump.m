function varargout = pptimgdump(pptfname, gunzp)
% PPTIMGDUMP - Dumps images from a PowerPoint presentation
%
% [FNAMES, ERR, ERRMSG] = PPTIMGDUMP(PPTFNAME, GUNZP)
%
% PPTFNAME - PowerPoint filename (char)
% GUNZP    - (Optional logical) If true, compressed WMF and EMF files will be
%            uncompressed. Default is true on Matlab 7 (R14) or higher. Forced
%            to false in earlier versions, because gunzip() is not included in
%            Matlab until Matlab 7.
%
% FNAMES   - Filenames of extracted images (cellstr)
% ERR      - Zero indicates success
% ERRMSG   - Error message
%
% Dumps images from a PowerPoint presentation in the directory containing
% the PowerPoint presentation. For example, if the file is named Foo.ppt,
% the output files will be:
%
%   Foo - 001.jpg, Foo - 002.png, etc
%
% This function reads the 'Pictures' Structured Storage stream in the PowerPoint
% file to extract the images exactly as they are stored in PowerPoint. The internal
% image format will not always match the original imported image. When a BMP, GIF,
% or TIFF images is loaded into PowerPoint, it is converted to a PNG. This is a
% lossless operation except (1) The PNG format does not support a transparent
% color (as GIF does) and (2) for multipage TIFF files, i.e. those that contain
% multiple images, PowerPoint only loads the first image. When an EPS is imported,
% PowerPoint converts it to to Windows Metafiles (WMF), a vector format to vector
% format conversion. JPEG images are imported as is.
%
% One way to extract images from PowerPoint as they are internally stored is
% to right click on an image in PowerPoint and choose 'Save as Picture'. The
% output format will default to the format that PowerPoint is using to store
% the image internally. By choosing this format, the output is not degraded in
% quality (e.g. saving a PNG as a JPG), unnecessarily expanded in size (e.g.
% saving a JPG as a PNG), or unnecessarily converted from a vector format to
% a bitmap format (e.g. EMF to PNG). However this is not a programatic solution.
%
%     Technically, there are two types of Windows Enhanced Metafiles, EMF and
%     EMF+. PowerPoint exports to the newer EMF+ format. This function extracts
%     the original EMF. Also, PowerPoint exports WMF as Placeable WMF files.
%     These contain an additional 22 byte header describing the position of the
%     drawing on a printed page.
%
% http://skp.mvps.org/pptxp002.htm documents another method of programatically
% exporting PowerPoint images using an undocumented Export() method on the Shape
% object in VB/Active-X. The drawback of that technique versus this function is
% that an export format must be specified, possibly leading to loss of quality
% or unnecessarily large exported images.
% 
% Note #1: This function does not dump figures that consist of PowerPoint
% graphics primitives, for example, lines, boxes, circles, text boxes, etc,
% but rather dumps images that are part of the PowerPoint presentation.
%
% Note #2: WMF has several variants: standard, placeable, and clipboard.
% Standard WMF file lack page placement infomation. This can confuse programs
% like the Windows Picture and Fax Viewer. When PowerPoint exports a WMF file
% it adds the 22-byte placeable header. The current function does not do this
% because it amounts to figuring out a 'bounding box' which is complicated.
%
% Note #3: In XP, the .wmz file extension is designated as a Windows Media
% Player Compressed Skin File rather than a compressed WMF. Nevertheless, if
% you insert a picture into Microsoft PowerPoint or Word, the "Files of type"
% pulldown menu offers the choice 'Compressed Windows Metafile (.wmz)'
%
% Note #4: This function dumps the original image even if it has been cropped
% in PowerPoint unless the cropped areas have been discarded, for example via
% the "Delete cropped areas of pictures" checkbox under the Compress Pictures
% dialog in PowerPoint.
%
% Note #5: Movies are not dumped; however the first frame of each movie
% is dumped because PowerPoint stores a separate copy of it in the 'Pictures'
% stream.
%
% See also SENDTOPPT.

% 22-Aug-2005 - Original code by Matthew Kidd
% 01-Sep-2005 - Last modification

% Definitions taken from WinError.h
STG_E_FILEALREADYEXISTS = hex2dec('80030050') - 2^32;
STG_E_FILENOTFOUND      = hex2dec('80030002') - 2^32;
% Arbitary value
NOT_A_POWERPOINT_FILE   = hex2dec('C0000001');

error(nargchk(1,2,nargin));

if ~ischar(pptfname), error('PPTFNAME must be a character string.'); end
if ~exist('gunzp', 'var') || isempty(gunzp)
	gunzp = true;
elseif (~islogical(gunzp) && ~isnumeric(gunzp)) || length(gunzp) ~= 1
	error('GUNZP must be a logical (or numeric) scalar.');
end
vstr = version;
if str2double(vstr(1:3)) < 7.0, gunzp = false; end

% Initial list of filenames created.
if (nargout > 0), varargout{1} = {}; end

[sdata, err, errmsg, serr, serrmsg] = freadss(pptfname, {'', 'Pictures'}, {'uint8'});
if err
	if (err == STG_E_FILEALREADYEXISTS)
		% File is not a Structured Storage file and therefore not a PowerPoint file.
		errmsg = 'File is not a PowerPoint file.';
	end
	if (nargout == 0),	error(errmsg); end
	if (nargout > 1),  varargout{2} = err; end
	if (nargout > 2),  varargout{3} = errmsg; end
	return
end

if ~ismember('PowerPoint Document', sdata{1})
	% If 'PowerPoint Document' stream does not exist, it is not a PowerPoint
	% Document. Note: We queried for the list of root streams above to check
	% the existence of the 'PowerPoint Document' stream, rather than trying to
	% read the stream since it can be large.
	if (nargout == 0)
		fprintf('File is not a PowerPoint file.\n'); return
	end
	if (nargout > 1), varargout{2} = NOT_A_POWERPOINT_FILE; end
	if (nargout > 2), varargout{3} = 'File is not a PowerPoint file.'; end
elseif (serr(2) == STG_E_FILENOTFOUND)
	if (nargout == 0)
		fprintf('No images stored in PowerPoint file.\n'); return
	end
	% Not an error, but note condition in error message.
	if (nargout > 1), varargout{2} = 0; end
	if (nargout > 2), varargout{3} = 'No images stored in PowerPoint file.'; end
else
	if (nargout > 1),  varargout{2} = serr(2); end
	if (nargout > 2),  varargout{3} = serrmsg{2}; end
	if any(serr)
		if (nargout == 0), error(errmsg); end; return
	end
end

[pdir, pfname] = fileparts(pptfname);
if isempty(pdir), pdir = pwd; end

% Each image is proceeded by a 25 byte header whose format is not entirely
% known. However, the second long word gives length of remaining header +
% the image. The first word gives the picture type (00 6E = png, A0 46 = jpg,
% 60 21 = wmz (compressed WMF), 40 3D = emz (compressed EMF).
%
% PowerPoint 2003 converts BMP, GIF and TIFF images to PNG images and EPS to WMZ
% when an images are loaded, so the check below for GIF and TIF image headers is
% probably useless.
%
% Compressed Windows Metafiles (WMZ) and Compressed Windows Enhanced Metafiles
% are basically gzipped WMF and EMF files respectively at maxium (-9) compression,
% though there seem to be very subtle differences in the compressed block data
% between what is produced by PowerPoint and gzip -9. Information on the GZIP
% format can be found at the URL below.
%
% ftp://ftp.uu.net/graphics/png/documents/zlib/zdoc-index.html

jpgHeader = [255, 216];
pngHeader = [char(137), 'PNG', char(13), char(10), char(26), char(10)];
gifHeader = 'GIF';
tifHeader = [73 73];

idata = sdata{2};
imgcnt = 0;
ip = 1;
while ( ip < length(idata) )
	imgcnt = imgcnt + 1;
	imsize = double(idata(ip+4)) + 2^8 * double(idata(ip+5)) + ...
		2^16 * double(idata(ip+6)) + 2^24 * double(idata(ip+7)) - 17;
	imp = ip+25;
	
	% Determine image type by examining start of image. Could also look at
	% first word of header file.
	if isequal(idata(imp:imp+1), jpgHeader)
		% Found JPEG "Start of Image" (SOI) marker
		ext = '.jpg';
	elseif isequal(idata(imp:imp+7), pngHeader)
		ext = '.png';
	elseif isequal(idata(imp:imp+2), gifHeader)
		ext = '.gif';
	elseif isequal(idata(imp:imp+1), tifHeader)
		ext = '.tif';
	elseif isequal(idata(ip:ip+1), [96 33])
		% Compressed Windows Metafile
		ext = '.wmz';
	elseif isequal(idata(ip:ip+1), [64 61])
		% Compressed Windows Enhanced Metafile
		ext = '.emz';
	else
		% Don't know what to do with it.
		ext = '.dat';
	end
	
	if ismember(ext, {'.wmz', '.emz'})
		if gunzp
			if strcmp(ext, '.wmz')
				imgFname = sprintf('%s\\%s - %03d%s', pdir, pfname, imgcnt, '.wmf.gz');
			else
				imgFname = sprintf('%s\\%s - %03d%s', pdir, pfname, imgcnt, '.emf.gz');
			end
		else
			imgFname = sprintf('%s\\%s - %03d%s', pdir, pfname, imgcnt, ext);
		end
		fd = fopen(imgFname, 'wb');
		if (fd == -1), error('Unable to open/write: %s', imgFname); end
		
		% The start of the image data contains 35 bytes before the compressed
		% block of the GZIP streams starts. These 35 bytes don't match the
		% normal GZIP header (0x1f, 0x8b, ...), so discard them and write
		% out a conformant GZIP header. 8 -> standard "deflate" compression
		% method; 0 -> No fields (except the compressed stream); 2 -> Maximal
		% compression was used; 11 -> Compression took place on a Windows OS.
		gzipHeader1 = [31 139 8 0];
		gzipHeader2 = [2 11];
		fwrite(fd, gzipHeader1, 'uint8');
		fwrite(fd, UnixTime(now), 'uint32');
		fwrite(fd, gzipHeader2, 'uint8');
		fwrite(fd, idata(imp+35:imp+imsize-1), 'uint8');
		fclose(fd);
				
		if gunzp
			% gunzip() is buggy in R14 SP2. The output directory for the unzipped
			% must be explicitly specified; otherwise the unzipped file will end
			% up in the current working directory rather than in the directory
			% containing the gzipped file (contrary to the gzunzip() help).
			gzOutDir = fileparts(imgFname);
			try
				gunzip(imgFname, gzOutDir);
			catch
				% gunzip() will exit with an error after the Java gzip parser returns
				% java.io.IOException: 'Corrupt GZIP trailer' because we didn't write
				% the GZIP trailer, which consists of a 32-bit CRC and the 32-bit
				% length of the original file (LSB 32-bits if bigger). Unfortunately
				% we don't know these values (unless they are stored somewhere in the
				% 35-byte header that we are ignoring).
			end
			delete(imgFname);
			if (nargout > 0), varargout{1}{end+1} = imgFname(1:end-3); end
		else
			if (nargout > 0), varargout{1}{end+1} = imgFname; end
		end

	else
		imgFname = sprintf('%s\\%s - %03d%s', pdir, pfname, imgcnt, ext);
		fd = fopen(imgFname, 'wb');
		if (fd == -1), error('Unable to open/write: %s', imgFname); end

		fwrite(fd, idata(imp:imp+imsize-1), 'uint8');
		fclose(fd);
		
		if (nargout > 0), varargout{1}{end+1} = imgFname; end
	end
	ip = imp + imsize;
end


function uxtime = UnixTime(t)
% Converts a time to Unix time, i.e. seconds since 00:00:000 GMT, Jan 1, 1970.

daydiff = datenum(t) - datenum(1970, 1, 1, 0, 0, 0);
uxtime = 24 * 60 * 60 * daydiff;
