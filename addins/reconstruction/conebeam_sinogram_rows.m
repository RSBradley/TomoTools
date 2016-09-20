function [row_range, slice_delta] = conebeam_sinogram_rows(R12, pixel_size, nrcols,slices)


upper_slice = max(abs((slices(:))-(nrcols(1)/2))); %changed nrcols(2) to nrcols(2) - number of rows!
delta = nrcols(2)*pixel_size(1)/2;


slice_delta = ceil(abs(upper_slice*(delta/(R12(1)-delta))));



row_range = min(slices(:))-slice_delta:max(slices(:))+slice_delta;

end