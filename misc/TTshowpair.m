function TTshowpair(img1, img2)

f = figure;
a1 = axes;
i1 = imshow(1+img1, 1+[min(img1(:)) max(img1(:))]);
hold on;
a2 = axes;
i2 = imshow(1-img2, 1-[max(img1(:)) min(img1(:))]);


set(a1, 'position', [0.05 0.05 0.9 0.9]);
set(a2, 'position', [0.05 0.05 0.9 0.9]);
set(a1, 'units', 'pixels');
set(a2, 'units', 'pixels');
p = get(a2, 'position');

set(i1, 'AlphaData', 0.5);
set(i2, 'AlphaData', 0.5);

set(f, 'KeyPressFcn', @keypress)

    function keypress(hObject, evt)
        ch = evt.Key;
        p = get(a2, 'position');
        switch ch
            case 'uparrow'
                set(a2, 'position', p+1*[0 1 0 0]);                
           case 'downarrow'
                set(a2, 'position', p-1*[0 1 0 0]);    
           case 'leftarrow'
                set(a2, 'position', p-1*[1 0 0 0]);
           case 'rightarrow'
                set(a2, 'position', p+1*[1 0 0 0]);
        end
    end



end