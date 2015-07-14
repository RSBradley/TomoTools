function data_out = rle_decode2(data_in, sz_out)


%Decodes AmiraMesh 8-bit RLE format

% Robert S Bradley (c) 2014

split_no = 128;

split_inds = find(data_in>split_no);

if ~isempty(split_inds)
    data = cell(numel(split_inds)+1,1);
    cell_ind = 1;
    
    %Section before 1st split
    if split_inds(1)>1
        curr_rng = [1 split_inds(1)-1];
        reps = double(data_in(curr_rng(1):2:curr_rng(2)-1));
        vals = (data_in(curr_rng(1)+1:2:curr_rng(2)));
        i = cumsum([ 1 reps(:)' ]);
        j = zeros(1, i(end)-1);
        j(i(1:end-1)) = 1;
        data{cell_ind} = vals(cumsum(j));
        cell_ind = cell_ind+1;
    end
    
    %Loop over splits
    for n = 1:numel(split_inds)
       cs = split_inds(n); 
       end_rng = cs+1+double(data_in(cs))-128-1;
       data{cell_ind} = data_in(cs+1:end_rng);
       cell_ind = cell_ind+1;
       
       %Section in between splits
       if n==numel(split_inds)
           curr_rng = [end_rng+1 numel(data_in)];
       else
           curr_rng = [end_rng+1 split_inds(n+1)-1];
       end
        
       if curr_rng(2)-curr_rng(1)>0           
            reps = double(data_in(curr_rng(1):2:curr_rng(2)-1));
            vals = data_in(curr_rng(1)+1:2:curr_rng(2));
            i = cumsum([ 1 reps(:)' ]);
            j = zeros(1, i(end)-1);
            j(i(1:end-1)) = 1;
            data{cell_ind} = vals(cumsum(j'));
            cell_ind = cell_ind+1;
       end
       
    end
    
    data_out = cat(1,data{:});

    
else
    
    reps = double(data_in(1:2:end-1));
    vals = data_in(2:2:end);
    i = cumsum([ 1 reps(:)' ]);
    j = zeros(1, i(end)-1);
    j(i(1:end-1)) = 1;
    data_out = vals(cumsum(j));
    
    
end


%Reshape data
data_out = reshape(data_out, sz_out);





