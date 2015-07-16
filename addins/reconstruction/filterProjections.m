function [p,H] = filterProjections(p_in, filter, R12, pixel_size, angles, detector_offsets, CS, d)


%assume p_in is cols x angles x rows
%R12 = StoRA + DtoRA distances
%detectors offsets = x offset, y offset in same units as pixel_size

p = p_in;

if nargin<8
    d=1;
end
if nargin<7
    CS = 0;
end
if nargin<6
    detector_offsets = [0 0];
end
if nargin<5
    ang_span = 2*pi();
else
    if isempty(angles)
        ang_span = 2*pi();
    else
        ang_span = max(angles(:))-min(angles(:)); 
    end
end

if nargin<3
    R12 = Inf;
    pixel_size = 1;
end


% Design the filter
len = size(p,1);
H = designFilter(filter, len, CS, d);

p(length(H),1)=0;  % Zero pad projections

if ~isinf(R12)
   
    %FDK weight
    [U V] = ndgrid(1:size(p,1), 1:size(p,3));
    Uo = (U-(size(p,1)-1)/2)*pixel_size(1)+detector_offsets(1);
    V = (V-(size(p,3)-1)/2)*pixel_size(2)+detector_offsets(2);
    
    Umin = min(U(:));
    Umax = max(U(:));
    
    U = permute(repmat(Uo.^2, [1 1 size(p,2)]), [1 3 2]);
    V = permute(repmat(V.^2, [1 1 size(p,2)]), [1 3 2]);
    
    p = p.*R12./sqrt(R12^2+U+V);
    
    if ang_span<2*pi()-2*pi()/180
        
        %Apply Parker reweight
        tmp = @(x) sin(pi()*x/4).^2;
        fan_angle = min(atan(abs(Umin)/R12),atan(abs(Umax)/R12));
        angles = repmat(angles(:)'+min(angles(:))-fan_angle, [size(p,1) 1]);
        
        
        gamma =  repmat(atan(Uo(:,1)/R12), [1 size(p,2)]);
        
        size(gamma)
        size(angles)
        size(fan_angle)
        
        wtm = ones(size(gamma));
        
        test1 = angles<=fan_angle-2*gamma;
        wtm(test1) = tmp((angles(test1)+fan_angle)./(fan_angle-gamma(test1)));        
        test2 = angles>pi()-fan_angle-2*gamma & angles<=pi()+fan_angle;
        wtm(test2) = tmp((pi()-angles(test2)+fan_angle)./(fan_angle+gamma(test2))); 
        
        test3 = angles>pi()+fan_angle;
        wtm(test3) = 0;
        
        wtm = repmat(wtm, [1 1 size(p,3)]);
        p = p.*wtm;
        
    end
end




% In the code below, I continuously reuse the array p so as to
% save memory.  This makes it harder to read, but the comments
% explain what is going on.

p = fft(p).*repmat(H, [1 size(p,2) size(p,3)]);    % p holds fft of projections

%for i = 1:size(p,2)
%    p(:,i) = p(:,i).*H; % frequency domain filtering
%end

p = real(ifft(p));     % p is the filtered projections
p(len+1:end,:,:) = [];   % Truncate the filtered projections
%----------------------------------------------------------------------

%======================================================================
function filt = designFilter(filter, len, CS, d)
% Returns the Fourier Transform of the filter which will be
% used to filter the projections
%
% INPUT ARGS:   filter - either the string specifying the filter
%               len    - the length of the projections
%               d      - the fraction of frequencies below the nyquist
%                        which we want to pass
%
% OUTPUT ARGS:  filt   - the filter to use on the projections


order = max(64,2^nextpow2(2*len));

%if strcmpi(filter, 'none')
%    filt = ones(1, order);
    %return;
%end

% First create a bandlimited ramp filter (Eqn. 61 Chapter 3, Kak and
% Slaney) - go up to the next highest power of 2.

n = 0:(order/2); % 'order' is always even. 
filtImpResp = zeros(1,(order/2)+1); % 'filtImpResp' is the bandlimited ramp's impulse response (values for even n are 0)
filtImpResp(1) = 1/4; % Set the DC term 
filtImpResp(2:2:end) = -1./((pi*n(2:2:end)).^2); % Set the values for odd n
filtImpResp = [filtImpResp filtImpResp(end-1:-1:2)]; 
filt = 2*real(fft(filtImpResp)); 
filt = filt(1:(order/2)+1);

w = 2*pi*(0:size(filt,2)-1)/order;   % frequency axis up to Nyquist

switch lower(filter)
    case 'ram-lak'
        % Do nothing
    case 'shepp-logan'
        % be careful not to divide by 0:
        filt(2:end) = filt(2:end) .* (sin(w(2:end)/(2*d))./(w(2:end)/(2*d)));
    case 'cosine'
        filt(2:end) = filt(2:end) .* cos(w(2:end)/(2*d));
    case 'hamming'
        filt(2:end) = filt(2:end) .* (.54 + .46 * cos(w(2:end)/d));
    case 'hann'
        filt(2:end) = filt(2:end) .*(1+cos(w(2:end)./d)) / 2;
    case 'none'
        filt(:) = 1;
    otherwise
        error(message('images:iradon:invalidFilter'))
end

filt(w>pi*d) = 0;                      % Crop the frequency response
filt = [filt' ; filt(end-1:-1:2)'];    % Symmetry of the filter
%----------------------------------------------------------------------

nr = size(filt,1);
Nr = ifftshift([-fix(nr/2):ceil(nr/2)-1])';


filt = filt.*exp(1i*2*pi()*CS*Nr/nr);
