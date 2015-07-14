/*
 * freadss.cpp - Reads stream data and/or stream names from Structured Storage,
 *               e.g Compound Files, a format created by Microsoft.
 *
 * [SDATA, ERR, ERRMSG, SERR, SERRMSG] = FREADSS(FNAME, SNAMES, SCLASS)
 *
 * FNAME   - Filename (char)
 * SNAMES  - Stream/storage names (cellstr)
 * SCLASS  - (Optional) Stream classes (cellstr, same size as SNAMES or 1x1)
 *           specifying what kind of array the stream data is returned in. Each
 *           cell may be 'uint8', 'int8', 'uint16', 'int16', 'uint32', 'int32',
 *           'int64', 'uint64', 'single', 'double', 'char', or 'unicode'. If
 *           SCLASS is a scalar, the same class will be used for all streams.
 *           If SCLASS is not specified, streams will be returned in UINT8
 *           arrays. Lists of stream/storage names are always returned as
 *           cell array regardless of the SCLASS option. 'unicode' returns
 *           a character arrays, but while interpreting the stream as Unicode.
 *
 * SDATA   - Stream data or cellstr of stream/storage names. Storage names are
 *           prefixed with a back slash to distinguish them from stream names.
 *           (cell, same size as SNAMES)
 * ERR     - Zero indicate file was opened successfully and is a structured
 *           storage file; otherwise a Windows error code.
 * ERRMSG  - Empty string if file was opened successfully; otherwise Windows
 *           error message.
 * SERR    - Vector (Same size as SNAMES) where zero indicates the corresponding
 *           stream/storage was read successfully and non-zero is an error code.
 * SERRMSG - Cell array (Same size as SNAMES). where an empty string indicates
 *           the corresponding stream/storage was read successful and a nonempty
 *           string is an error message.
 *
 * Structured Storage is a format created by Microsoft that is somewhat akin
 * to having a filesystem in a single file where Storages and Streams play
 * the role of folders and files respectively. These are some time called
 * Compound Files, through strictly speaking a Compound File is subclass of
 * a Structure Storage.
 *
 * Streams must be specified by the full "path" to the streams, separating each
 * storage by a backslash, i.e.
 *
 *   '{storage1}\{storage2}\...\{storageN}\{stream}'
 *
 * Storages must be specified by the full "path" to the storage, i.e.
 *
 *   '{storage1}\{storage2}\...\{storageN}'
 * 
 * Note: An empty string designates the root storage.
 * 
 * Error codes usually correspond to Windows errors as defined in WinError.h.
 * For the most common ones, the error message is a meaningful translation of
 * the error code. The code 0xE0000008 (-536870904) is returned if there are
 * memory memory allocation problems.
 *
 * Since a stream might contain multiple data types, there may not be an ideal
 * stream class option. In this case use UINT8 and parse the data by piecing
 * the bytes into words and long words as necessary. If the stream includes a
 * mix of floating and non floating point numbers, it may be easist to write
 * the uint8 data to a file with fwrite() and then read it back piece by piece
 * with fread().
 *
 * Note: This function supports reading of multiple streams to eliminate the
 * overhead of multiple structured file open/close operations.
 *
 * Example (read Picture stream from a PowerPoint file)
 * 
 *   sdata = freadss('foo.ppt', {'Pictures'}, {'uint8'});
 *
 * To compile under Microsoft Visual C/C++ (MSVC)
 *   mex -setup  (one time setup)
 *   mex freadss.cpp ole32.lib
 *
 * It is also possible to compile using the free Microsoft Visual C++ Toolkit
 * 2003, if you also download the free Microsoft Platform SDK to pick up all
 * missing header files, and download the free Microsoft Visual Studio .NET
 * 2003 to pickup missing libraries, particularly MSVCRT.LIB and MSVCRTD.LIB
 * (the debug version). Finally one needs to create MSVCPRT.LIB. See:
 * http://www.delta3d.org/article.php?story=20050721180227305&mode=print
 * 
 * Send feedback and bug reports to the spam obfuscated e-mail below.
 * matthew (underscore) kidd at ghctechnologies dot com
 *              
 * 15-Aug-2005 - Original code by Matthew J. Kidd (GHC Technologies)
 * 31-Aug-2005 - Last modification date
 *
 */

#define UNICODE
#include <stdio.h>
#include <windows.h>
#include <wchar.h>
#include "mex.h"

#define VERBOSE 0

HRESULT readStream(IStorage *pStgRoot, wchar_t *strmName, char *className,
		   mxArray **ppMX);

HRESULT readStreamNames(IStorage *pStg, mxArray **ppMX);

void
mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
  // Matlab datatypes that streams can be converted to.
  char *MX_CLASS_NAMES[] = {"uint8", "int8", "uint16", "int16", "uint32",
			    "int32", "int64", "uint64", "single", "double",
			    "char", "unicode"};
  const int nClasses = sizeof(MX_CLASS_NAMES) / sizeof(char *);

  int i, j;
  int stest;
  int nStreams, nsClass;
  char className[16] = "uint8";
  const int dims00[] = {0, 0};
  const int dims11[] = {1, 1};
  double *pserr;
  int buflen;
  wchar_t *fname, *strmName;
  HRESULT hr;
  IStorage *pStgRoot;
  char errmsg[512], *cfname;
  mxArray *pMX;

  // Check input arguments.  
  if (nrhs < 2 || nrhs > 3)
    mexErrMsgTxt("Function requires two or three arguments.\n");
  if ( !mxIsChar(prhs[0]) )
    mexErrMsgTxt("First argument must be a character string.");
  if ( !mxIsCell(prhs[1]) )
    mexErrMsgTxt("Second argument must be a cellstr array.");
  nStreams = mxGetNumberOfElements(prhs[1]);
  for (i=0; i<nStreams; i++) {
    pMX = mxGetCell(prhs[1],i);
    if ( pMX == NULL || !mxIsChar(pMX) )
      mexErrMsgTxt("Second argument must be a cellstr array.");
  }
  if (nrhs > 2) {
    if ( !mxIsCell(prhs[2]) )
      mexErrMsgTxt("Third argument must be a cellstr array.");

    nsClass = mxGetNumberOfElements(prhs[2]);
    if (nsClass != nStreams && nsClass != 1)
      mexErrMsgTxt("Third argument must have same number of elements as "
		   "second argument or be a scalar.");
    
    for (i=0; i<nsClass; i++) {
      pMX = mxGetCell(prhs[2], i);
      if ( pMX == NULL || !mxIsChar(pMX) )
	mexErrMsgTxt("Third argument must be a cellstr array.");

      mxGetString(pMX, className, sizeof(className));
      for (j=0; j<nClasses; j++) {
	if ( (stest = strcmp(className, MX_CLASS_NAMES[j])) == 0 )  break;
      }
      if (stest) {
	sprintf(errmsg, "Invalid datatype in element %d of third argument.", i+1);
	mexErrMsgTxt(errmsg);
      }
    }
  }


  if (nlhs > 5)
    mexErrMsgTxt("Function returns at most five arguments.");

  /* Partially initialize some output variables. Must only initialize
     return arguments requested by the caller, except for the first
     output argument which the mex function is always allowed to return. */
  plhs[0] = mxCreateCellMatrix(1,nStreams);
  mxSetDimensions(plhs[0], mxGetDimensions(prhs[1]),
		  mxGetNumberOfDimensions(prhs[1]));

  if (nlhs > 1)
    plhs[1] = mxCreateNumericArray(2, dims11, mxDOUBLE_CLASS, mxREAL);
  if (nlhs > 3) {
    plhs[3] = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[1]), 
				   mxGetDimensions(prhs[1]), mxDOUBLE_CLASS,
				   mxREAL);
    pserr = mxGetPr(plhs[3]);
    for (i=0; i<nStreams; i++) {
      pserr[i] = 0;
    }
  }
  if (nlhs > 4) {
    plhs[4] = mxCreateCellMatrix(1,nStreams);
    mxSetDimensions(plhs[4], mxGetDimensions(prhs[1]),
		   mxGetNumberOfDimensions(prhs[1]));
    for (i=0; i<nStreams; i++) {
      mxSetCell(plhs[4], i, mxCreateCharArray(2, dims00));
    }
  }

  // Make a Unicode terminated (0x0000) string because Matlab strings are
  // terminated. Copy directly rather than use mxGetString() to preserve
  // Unicode name.
  buflen = mxGetNumberOfElements(prhs[0]) + 1;
  fname = (wchar_t *) mxCalloc(buflen, sizeof(wchar_t)) ;
  wmemcpy(fname, (wchar_t *) mxGetPr(prhs[0]), buflen-1);
  fname[buflen-1] = 0x0000;

  // It seems like STGM_READ alone should suffice with STGM_SHARE_DENY_NONE
  // assumed for the sharing group according to the documentation. But unless
  // I add STGM_SHARE_DENY_WRITE, I get back an STG_E_INVALIDFLAG error.
  hr = StgOpenStorageEx(fname, STGM_READ | STGM_SHARE_DENY_WRITE,
			STGFMT_STORAGE, 0, NULL, NULL,
			IID_IStorage, reinterpret_cast<void**>(&pStgRoot) );
  if (VERBOSE) mexPrintf("Tried to open Root Storage with Result: %d.\n", hr);
  mxFree(fname);

  if (nlhs > 1)
    mxGetPr(plhs[1])[0] = (double) hr;

  if ( FAILED(hr) ) {
    /* If user didn't request error message, we are done. */
    if (nlhs <= 2) return;
    
    switch (hr) {
    case STG_E_FILENOTFOUND:
      buflen = mxGetNumberOfElements(prhs[0]) + 1;
      cfname = (char *) mxCalloc(buflen, sizeof(mxChar));
      mxGetString(prhs[0], cfname, buflen);
      strcpy(errmsg, "Filename not found: ");
      strncat(errmsg, cfname, sizeof(errmsg) - strlen(cfname) - 1);
      mxFree(cfname);
      break;
    case STG_E_FILEALREADYEXISTS:
      strcpy(errmsg, "File is not a Structured Storage file."); break;
    case STG_E_INVALIDNAME:
      strcpy(errmsg, "Filename is invalid."); break;
    case STG_E_LOCKVIOLATION:
      strcpy(errmsg, "File is open and locked (probably by another application).");
      break;
    case STG_E_SHAREVIOLATION:
      strcpy(errmsg, "File is open and locked (probably by another application).");
      break;
    case STG_E_ACCESSDENIED:
      strcpy(errmsg, "Access denied. Check file permissions.");
      break;
    default:
      strcpy(errmsg, "Error (decode HRESULT error code manually).");
    }
    plhs[2] = mxCreateString(errmsg);
    return;
  }
  else {
    if (nlhs > 2) {
      plhs[2] = mxCreateString("");
    }
  }

  // Next try to read each stream.
  for (i=0; i<nStreams; i++) {
    pMX = mxGetCell(prhs[1],i);
    buflen = mxGetNumberOfElements(pMX) + 1;
    strmName = (wchar_t *) mxCalloc(buflen, sizeof(wchar_t));
    wmemcpy(strmName, (wchar_t *) mxGetPr(pMX), buflen-1);
    strmName[buflen-1] = 0x0000;

    if (nrhs > 2) {
      if ( mxGetNumberOfElements(prhs[2]) == 1)
	mxGetString( mxGetCell(prhs[2],0), className, sizeof(className));
      else
	mxGetString( mxGetCell(prhs[2],i), className, sizeof(className));
    }        

    hr = readStream(pStgRoot, strmName, className, &pMX);
    mxFree(strmName);
    
    // Assign stream data or cellstr of stream names to cell.
    if (pMX) mxSetCell(plhs[0], i, pMX);
    
    // Only record stream error status if requested by user.
    if (nlhs <= 3) continue;
    pserr = mxGetPr(plhs[3]);
    pserr[i] = (double) hr;

    // Only record stream error message if request by user.
    // Ignore non failures because Matlab output is already initialized
    // for successful result.
    if (nlhs <= 4 || !FAILED(hr) ) continue;
    
    switch (hr) {
    case STG_E_FILENOTFOUND:
      strcpy(errmsg, "Storage or stream does not exist."); break;
    case STG_E_ACCESSDENIED:
      strcpy(errmsg, "Access denied."); break;
    case STG_E_INSUFFICIENTMEMORY:
      strcmp(errmsg, "Insufficient memory to open stream."); break;
    case STG_E_INVALIDNAME:
      strcmp(errmsg, "Invalid storage or stream name."); break;
    case STG_E_TOOMANYOPENFILES:
      strcmp(errmsg, "Too many open files."); break;
    default:
      strcpy(errmsg, "Error (decode HRESULT error code manually).");
    }

    // Get rid of the empty string placed there when outputs were initialized.
    mxDestroyArray(mxGetCell(plhs[4],i));
    // Drop in the error message.
    mxSetCell(plhs[4], i, mxCreateString(errmsg));
  }

  // Cleanup
  if (NULL != pStgRoot) pStgRoot->Release();

}

HRESULT readStream(IStorage *pStgRoot, wchar_t *strmName, char *className,
		   mxArray **ppMX) {

#define MAX_STORAGES 64

  unsigned int i, j, k, slen, nStorages = 0;
  wchar_t *token;
  IStorage *pStg[MAX_STORAGES+1];
  IStream  *pStm;
  STATSTG  Stat;
  HRESULT hr;
  char warnmsg[256], stmp[256];
  ULONG cbRead;
  unsigned long bRead;
  mxClassID mxclass;
  int mxsize, nelem, isunicode;
  int dims1n[] = {1, 0};
  void *pstrmData;
  char *pData, *pChar;
  
  // Return NULL pointer if problem is encountered.
  *ppMX = NULL;

  // Empty stream means enumerate Streams and Storages below root Storage.
  if ( wcslen(strmName) == 0 ) { 
    hr = readStreamNames(pStgRoot, ppMX);
    return hr;
  }

  // Count number of storages (which are like directories) along the
  // way to the final stream or storage.
  slen = wcslen(strmName);
  for (i=0; i<slen; i++) {
    if ( strmName[i] == L'\\' )  nStorages++;
  }

  // Made up error code with C (Customer) bit set. Use MAX_STORAGES-1 because
  // although final token is usually a Stream, it may be a Storage, whose
  // Streams the caller wants enumerated.
  if (nStorages > MAX_STORAGES-1) { return CO_E_PATHTOOLONG + 0x20000000; }

  // Navigate down Storages.
  pStg[0] = pStgRoot;
  token = wcstok(strmName, L"\\");

  for (i=0; i<nStorages; i++) {
    
    hr = pStg[i]->OpenStorage(token, NULL, STGM_READ | STGM_SHARE_EXCLUSIVE,
		     NULL, 0, &pStg[i+1] );
    if (VERBOSE) {
      WideCharToMultiByte(CP_ACP, NULL, token, -1, stmp, sizeof(stmp), 
			  NULL, NULL);
      mexPrintf("Tried to open Storage: \"%s\" with Result: %d\n", stmp, hr);
    }

    if ( FAILED(hr) ) {
      for (j=i; j>0; j--) pStg[j]->Release(); return hr;
    }

    // On final loop this will pick up the Stream name.
    token = wcstok(NULL, L"\\");
  }

  // Try to open the Stream.
  hr = pStg[nStorages]->OpenStream(token, NULL, STGM_READ | STGM_SHARE_EXCLUSIVE,
				   0, &pStm );
  if (VERBOSE) {
    WideCharToMultiByte(CP_ACP, NULL, token, -1, stmp, sizeof(stmp), 
			NULL, NULL);
    
    mexPrintf("Tried to open Stream: \"%s\" with Result: %d\n", stmp, hr);
  }

  if ( FAILED(hr) ) {
    if (hr != STG_E_FILENOTFOUND) {
      for (j=nStorages; j>0; j--) pStg[j]->Release(); return hr;
    }
    else {
      // Maybe user passed a Storage name rather than a Stream name. If so
      // return all the Stream names in the storage as a cellstr array.
      hr = pStg[nStorages]->OpenStorage(token, NULL,
					STGM_READ | STGM_SHARE_EXCLUSIVE,
					NULL, 0, &pStg[nStorages+1] );

      if ( hr == S_OK ) {
	hr = readStreamNames(pStg[nStorages+1], ppMX);
	pStg[nStorages+1]->Release();
      }

      for (j=nStorages; j>0; j--) pStg[j]->Release(); return hr;
    }
  }


  // Get STATSTG structure to find out how big the stream is.
  hr = pStm->Stat(&Stat, STATFLAG_NONAME);
  if ( FAILED(hr) ) {
    pStm->Release();
    for (j=nStorages; j>0; j--) pStg[j]->Release(); return hr;
  }

  // Create Matlab array to hold stream data. If unallocable, return error
  // code which is (I believe) consistent with scheme outlined in WinError.h
  // for user errors, i.e. Severity set to 11 (Error) and C (Customer) bit
  // turned on. Similar to ERROR_NOT_ENOUGH_MEMORY (0x8). Note, Stat.cbSize
  // is a ULARGE_INTEGER, a kludgy Microsoft union datatype to represent a
  // 64-bit value. If the stream is >= 2^31, just give up.
  if (Stat.cbSize.HighPart != 0 || Stat.cbSize.LowPart > 0x7FFFFFFF) { 
    pStm->Release(); CoTaskMemFree(Stat.pwcsName);
    for (j=nStorages; j>0; j--) pStg[j]->Release(); return 0xE0000008;
  }
  if (VERBOSE) mexPrintf("Stream Size: %d bytes\n", Stat.cbSize.LowPart);

  if ( strcmp(className, "char") == 0 ) {
    mxsize = 1; mxclass = mxCHAR_CLASS; isunicode = 0; }
  else if ( strcmp(className, "unicode") == 0 ) {
    mxsize = 2; mxclass = mxCHAR_CLASS; isunicode = 1; }
  else if ( strcmp(className, "int8") == 0 ) {
    mxsize = 1; mxclass = mxINT8_CLASS; }
  else if ( strcmp(className, "uint8") == 0 ) {
    mxsize = 1; mxclass = mxUINT8_CLASS; }
  else if ( strcmp(className, "int16") == 0 ) {
    mxsize = 2; mxclass = mxINT16_CLASS; }
  else if ( strcmp(className, "uint16") == 0 ) {
    mxsize = 2; mxclass = mxUINT16_CLASS; }
  else if ( strcmp(className, "int32") == 0 ) {
    mxsize = 4; mxclass = mxINT32_CLASS; }
  else if ( strcmp(className, "uint32") == 0 ) {
    mxsize = 4; mxclass = mxUINT32_CLASS; }
  else if ( strcmp(className, "int64") == 0 ) {
    mxsize = 8; mxclass = mxINT64_CLASS; }
  else if ( strcmp(className, "uint64") == 0 ) {
    mxsize = 8; mxclass = mxUINT64_CLASS; }
  else if ( strcmp(className, "single") == 0 ) {
    mxsize = 4; mxclass = mxSINGLE_CLASS; }
  else if ( strcmp(className, "double") == 0 ) {
    mxsize = 8; mxclass = mxDOUBLE_CLASS; }
  else {
    sprintf(warnmsg, "Unhandled Matlab class (%s) in readStream(). Check code "
	    "for logical consistency", className);
    mexWarnMsgTxt(warnmsg);
    CoTaskMemFree(Stat.pwcsName);
    for (j=nStorages; j>0; j--) pStg[j]->Release(); return 0xE00000001;
  }
  
  // Be careful. Stream size might not be an even multiple of size of the
  // datatype that user is choosing to interpret it as.
  nelem = ( Stat.cbSize.LowPart + (Stat.cbSize.LowPart % mxsize) ) / mxsize;

  if (mxclass == mxCHAR_CLASS) {
    // Special treatment because Matlab strings occupy 2 bytes per character
    // representing Unicode in Matlab 7 (R14) and later and something quirky
    // in earlier versions. Read data into an intermediate buffer and directly
    // populate a Matlab character array (two bytes per character). Don't use
    // mxCreateString() to do the conversion because the conversion stops if
    // it encounters a 0x00, a value that may be present in a stream and which
    // is a legitimate value in a Matlab character array.
    dims1n[1] = nelem;
    *ppMX = mxCreateCharArray(2, dims1n);
    if (*ppMX == NULL) {
      pStm->Release(); CoTaskMemFree(Stat.pwcsName);
      for (j=nStorages; j>0; j--) pStg[j]->Release(); return 0xE0000008;
    }

    pstrmData = mxCalloc(Stat.cbSize.LowPart, 1);
    if (pstrmData == NULL) {
      pStm->Release(); CoTaskMemFree(Stat.pwcsName);
      for (j=nStorages; j>0; j--) pStg[j]->Release(); return 0xE0000008;
    }
    hr = pStm->Read(pstrmData, Stat.cbSize.QuadPart, &cbRead);
    bRead = cbRead % 0x100000000;
    if (bRead != Stat.cbSize.LowPart) {
      sprintf(warnmsg, "Only %d bytes read on a %d byte stream despite request "
	      "to read entire stream.", bRead, Stat.cbSize.LowPart);
      mexWarnMsgTxt(warnmsg);
    }

    pChar = (char *) mxGetPr(*ppMX);
    pData = (char *) pstrmData;
    if ( isunicode ) {
      // Copy Unicode characters. Don't stop at 0x00 (null) as wstrcpy()
      // would, because Matlab permits its strings to contain char(0).
      for (k=0; k<bRead; k++) {
	*pChar = *pData; pChar++; pData++;
      }
    }
    else {
      for (k=0; k<nelem; k++) {
	// Map characters to two byte Unicode equivalent. However, map 0x00
	// (nul) --> 0x100 to work around bizarre Matlab behavior, which maps
	// 0x00 --> 0x20 after exiting the mex function! I don't understand
	// this at all given that Matlab allows 0x00 in character arrays (e.g.
	// s = char(0)) and they show  up as 0x00 if passed to a mex file for
	// examination.
	*pChar = *pData; pChar++; *pChar = (*pData == 0 ? 1 : 0);
	pChar++; pData++;
      }
    }
    mxFree(pstrmData);
  }
  else {
    dims1n[1] = nelem;
    *ppMX = mxCreateNumericArray(2, dims1n, mxclass, mxREAL);
    if (*ppMX == NULL) {
      pStm->Release();
      for (j=nStorages; j>0; j--) pStg[j]->Release(); return 0xE0000008;
    }

    // Read stream. cbRead is a ULONG, the more modern 64-bit integer datatype.
    hr = pStm->Read(mxGetPr(*ppMX), Stat.cbSize.QuadPart, &cbRead);
    bRead = cbRead % 0x100000000;
    if (bRead != Stat.cbSize.LowPart) {
      sprintf(warnmsg, "Only %d bytes read on a %d byte stream despite request "
	      "to read entire stream.", bRead, Stat.cbSize.LowPart);
      mexWarnMsgTxt(warnmsg);
    }
  }

  pStm->Release(); CoTaskMemFree(Stat.pwcsName);
  for (j=nStorages; j>0; j--) pStg[j]->Release(); return hr;
}


HRESULT readStreamNames(IStorage *pStg, mxArray **ppMX) {

  HRESULT hr;
  IEnumSTATSTG *pEnum;
  STATSTG Stat;
  ULONG nFetched;
  int subidx = 0, nSubs = 0;
  int dims1n[] = {1, 0};
  mxArray *pMXchar;
  wchar_t BACKSLASH[] = L"\\";
  wchar_t *pWChar;

  // Not strictly necessary, but good defense.
  *ppMX = NULL;

  hr = pStg->EnumElements(0, NULL, 0, &pEnum);
  if (FAILED(hr)) return hr;

  // Figure out how many sub-Streams and sub-Storages are present.
  while (1) {
    hr = pEnum->Next(1, &Stat, &nFetched);
    if (hr == S_FALSE) break;
    CoTaskMemFree(Stat.pwcsName);
    if (Stat.type == STGTY_STORAGE || Stat.type == STGTY_STREAM)
      nSubs++;
  }
  if (VERBOSE) mexPrintf("Found %d sub Storages and Streams.\n", nSubs);

  // Allocate a cell array to hold the names.
  *ppMX = mxCreateCellMatrix(1,nSubs);
  if (*ppMX == NULL) {
    pEnum->Release(); return 0xE0000008;
  }

  pEnum->Reset();
  while (1) {
    hr = pEnum->Next(1, &Stat, &nFetched);
    if (hr == S_FALSE || subidx == nSubs) break;
    
    if (Stat.type == STGTY_STORAGE)
      dims1n[1] = wcslen(Stat.pwcsName) + 1;
    else if  (Stat.type == STGTY_STREAM)
      dims1n[1] = wcslen(Stat.pwcsName);
    else {
      CoTaskMemFree(Stat.pwcsName); continue;
    }

    // Copy string directly rather than use mxCreateString() in order to
    // preserve the Unicode name. Use wmemcpy() rather than wcscpy() below
    // because Matlab strings are not terminated with 0x0000.
    pMXchar = mxCreateCharArray(2, dims1n);
    if (pMXchar == NULL) {
      CoTaskMemFree(Stat.pwcsName); pEnum->Release(); return 0xE0000008;
    }
    
    pWChar = (wchar_t *) mxGetPr(pMXchar);

    // Prefix Storage name from Stream name by adding a leading forward slash.
    if (Stat.type == STGTY_STORAGE) {
      *pWChar = BACKSLASH[0]; pWChar++;
    }
    wmemcpy(pWChar, Stat.pwcsName, wcslen(Stat.pwcsName));
    mxSetCell(*ppMX, subidx, pMXchar);
    CoTaskMemFree(Stat.pwcsName);
    subidx++;
  }

  pEnum->Release();
  return S_OK;
}
