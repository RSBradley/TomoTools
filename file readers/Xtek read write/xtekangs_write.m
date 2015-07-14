function xtekangs_write(directory, angles, times)

%Create _ctdata.txt file for writing angles an times of the corresponding
%projection images
filename = [directory '\_ctdata.txt'];
fid = fopen(filename, 'w+');

%Write first line headings
headings = char([80 114 111 106 9 65 110 103 108 101 40 100 101 103 41 9 84 105 109 101 40 115 41 13 10]);
fwrite(fid, headings, 'char');


%Write data
n_projs = numel(angles);
times = cumsum(times);

for n = 1:n_projs
    str = [num2str(n) char(9) sprintf('%3.3f', angles(n)) char(9) sprintf('%3.3f',times(n)) char(13) char(10)];
    fwrite(fid, str, 'char');
end

fclose(fid);
    


end