function data_out = rle_decode(data_in, sz_out)


%Decodes AmiraMesh 8-bit RLE format


%Preallocate output data
data_out = zeros(sz_out, 'uint8');

%Loop over data_in
n_max = numel(data_in);

ind = 1;
n = 0;
while n<=n_max-2
  n = n+1;
  curr_val1 = double(data_in(n));
  if curr_val1<=129
      %Denotes number of consequentive values that are equal
      n = n+1;
      curr_val2 = data_in(n);
      ind_end = ind+curr_val1-1;      
      %try
      data_out(ind:ind_end) = curr_val2;
      %catch
      %    n
      %  break   
      %end    
      ind = ind_end+1;
      
  else    
     %Stretch of non-repetitive numbers
     m_vals = double(curr_val1-128);
     
     n_start = n+1;
     n_end = n_start+m_vals-1;
     
     ind_end = ind+m_vals-1;
     %data_in(n_start:n_end)
     %n
     %ind
     %ind_end
     %class(ind)
     %class(ind_end)
     %size(data_out(ind:ind_end))
     data_out(ind:ind_end) = data_in(n_start:n_end);
     %pause
     ind = ind_end+1;
     n = n_end;
     
     %for m = 1:m_vals
     %    n = n+1;
     %    data_out(ind) = data_in(n);
     %    ind = ind+1;
    
    % end
  end  
    
    
end    




end