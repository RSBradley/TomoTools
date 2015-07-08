TomoTools
=========

  TomoTools is a Matlab based GUI for processing of x-ray tomography data. You can open and view data such as raw projections, sinograms and reconstruction slices. It features a plugin architecture for extensibility of supported file types and processing tools.

## Current plugins
### 1. Export
  Export data to tiff images, raw binary files, or Avizo am files. Apply greylevel scaling, cropping and change data type. The histogram peak fitting tool can be used to aid rescaling. 

### 2. Phase retrieval
  Apply phase retrieval to radiographs containing inline phase contrast. Currently supported algorithms are TIE-HOM (Paganin) and Phase-Attenuation Duality (PAD). Phase retrieval can be incorporated into reconstruction, see below

### 3. Reconstruction
  A plugin for the ASTRA reconstruction toolbox. It features pre-processing such as finding the centre of rotation, ring artefact reduction, hot-pixel removal and sinogram padding. Parallel beam and cone beam geometries are supported. Filtered backprojection or iterative algorithms can be selected. 

  Tested with ASTRA version 1.5 and 1.6

### 4. Alignment
  Correct sample drift in long scans by comparing projections to those in a short scan (e.g. 21 projections). Rigid transformations are supported and a semi-automatic mode can be selected.

 Requirements: image processing toolbox in R2015a or greater.

## Currently supported file types
  1. Zeiss Xradia TX(R)M file format (windows only)
  2. Nikon Xtek raw data format (sample shifts/dithering to be added in future)
  3. Volume Graphics VGI format
  4. NeXus file format
  5. Tiff stacks
   
## License

TomoTools is open source under the GPLv3 license.

## Author

Dr Rob S Bradley
Henry Moseley X-ray Imaging Facility, The University of Manchester

email:
website: www.mxif.manchester.ac.uk

Copyright: 2013-2015, R. S. Bradley
