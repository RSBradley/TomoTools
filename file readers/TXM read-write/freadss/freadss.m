% FREADSS - Reads stream data and/or stream names from Structured Storage.
% 
% [SDATA, ERR, ERRMSG, SERR, SERRMSG] = FREADSS(FNAME, SNAMES, SCLASS)
%
% FNAME   - Filename (char)
% SNAMES  - Stream and/or storage names (cellstr)
% SCLASS  - (Optional) Stream classes (cellstr, same size as SNAMES or 1x1)
%           specifying what kind of array the stream data is returned in. Each
%           cell may be 'uint8', 'int8', 'uint16', 'int16', 'uint32', 'int32',
%           'int64', 'uint64', 'single', 'double', 'char', or 'unicode'. If
%           SCLASS is a scalar, the same class will be used for all streams.
%           If SCLASS is not specified, streams will be returned in UINT8
%           arrays. Lists of stream/storage names are always returned as
%           cell array regardless of the SCLASS option. 'unicode' returns
%           a character array but while interpreting the stream as Unicode.
%
% SDATA   - Stream data or cellstr of stream/storage names. When reading a
%           Storage, (sub) Storage names are prefixed with a backslash to
%           distinguish them from stream names. (cell, same size as SNAMES)
% ERR     - Zero indicates file was opened successfully and is a structured
%           storage file; otherwise it contains a Windows error code.
% ERRMSG  - Empty string if file was opened successfully; otherwise Windows
%           error message.
% SERR    - Vector (Same size as SNAMES) where zero indicates the corresponding
%           stream/storage was read successfully and non-zero is an error code.
% SERRMSG - Cell array (Same size as SNAMES), where an empty string indicates
%           the corresponding stream/storage was read successful and a nonempty
%           string is an error message.
%
% Structured Storage is a format created by Microsoft that is somewhat akin
% to having a filesystem in a single file where Storages and Streams play
% the role of folders and files respectively. These are sometimes called
% Compound Files, through strictly speaking a Compound File is a Structure
% Storage with additional restrictions.
%
% A stream is specified by the full "path" to the stream, separating each
% storage by a backslash, i.e.
%
%   '{storage1}\{storage2}\...\{storageN}\{stream}'
%
% A storage is specified by the full "path" to the storage, i.e.
%
%   '{storage1}\{storage2}\...\{storageN}'
% 
% Note: the root storage is specified by an empty string.
%
% Reading a storage is akin to listing the contents of a folder. Therefore,
% the corresponding cell of SDATA is always a cellstr regardless of the
% datatype specified in SCLASS.
%
% Since a stream might contain multiple data types, there may not be an ideal
% stream class option. In this case use UINT8 and parse the data by piecing
% the bytes into other data types. In Matlab R2006a or later this can be 
% done conveniently with cast(). In earlier Matlab versions uint8 byte data
% can be easily combined into uint16 or uint32 if the stream is just a mix of
% uint8/16/32 data types. However,iIf the stream includes a mix of floating
% and non floating point numbers, the easist approach is probably to write
% the uint8 data to a file with fwrite() and then read it back piece by piece
% with fread().
%
% Note: This function supports reading of multiple streams/storages to
% eliminate the overhead of multiple structured storage file open/close
% operations.
%
% Error codes usually correspond to Windows errors as defined in WinError.h.
% For the most common ones, the error message is a meaningful translation of
% the error code. The code 0xE0000008 (-536870904) is returned if there are
% memory memory allocation problems.
%
% Example (read Picture stream from a PowerPoint file)
% 
%   sdata = freadss('foo.ppt', {'Pictures'}, {'uint8'});
%
% See also FREAD, FOPEN.

% 15-Aug-2005 - Original code by Matthew Kidd
% 20-Apr-2006 - Cleaned up help
