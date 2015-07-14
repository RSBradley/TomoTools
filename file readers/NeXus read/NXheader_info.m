function info = NXheader_info

info.path = 'entry1.tomo_entry';

info.names = {'Title', 'title.value'; 'Facility', 'name.value'; 'FacilityType', 'type.value';...
            'IonCurrent', 'control.data.value'; 'Energy', 'energy.value';'Current', 'current.value';...
            'R2', 'distance.value';'PixelSize', 'pixel_size.value';'ExposureTime', 'count_time.value'; 'Angles', 'rotation_angle.value';...
            'ImageKey', 'image_key.value';'DataFile', 'data.data'; };

info.imagekey.blackrefs = 2;        
info.imagekey.whiterefs = 1;
info.imagekey.images = 0;

end