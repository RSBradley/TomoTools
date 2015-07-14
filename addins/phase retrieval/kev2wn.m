function wn = kev2wn(kev)


%Converts energy in keV to corresponding wave number

wn = 1000*kev*1.60217733e-19*2*pi()/(6.6260755e-34 * 2.99792458e8); 



end