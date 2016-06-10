function fcn = str2func(str_in)

reps = {'\dx','.*x';...
        'x\^', 'x.^'};
    

for n = 1:size(reps,1)
    str_in = regexprep(str_in, reps{n,1}, reps{n,2});
end

fcn = eval(['@(x) ' str_in ';']);


end