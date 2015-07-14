function t = tform2D_cropadj(t, cropX, cropY)



dX = cropX-1;
dY = cropY-1;

t.T(3,1) = t.T(3,1)-t.T(2,1)*dY +dX*(1-t.T(1,1));
t.T(3,2) = t.T(3,2)-t.T(1,2)*dX +dY*(1-t.T(2,2));



end