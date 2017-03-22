% compute the inverse of a CRT gamma characteristic in lookup table format.
% a companion to measureGammaJ17.m, which provides:
%   grays   a list of digital gray values samples, in [0 2^16-1]
%   data    several luminance samples per grays value, in [0, Lmax]
%   host    name of computer that gets these gamma tables

% interpolate a 16-bit, one-channel gamma table
% pull out an 8-bit, three-channel gamma table with identical rgb

% measured lum responses
Lcharacteristic = mean(data');
Lmax = Lcharacteristic(end);

% clip lameo data
Lclip = Lcharacteristic;
Lclip(1:find(Lcharacteristic > .1, 1)) = 0;

% desired linearly spaced lum responses
Lline = linspace(0, Lmax, 256);

% lookup/interpolate linearly to find the CRT gun intensities in 
% [0, 2^16-1] that correspond to linear lum responses in [0, Lmax]

% % MATLAB's interp1 whines about duplicate values in Lcharacteristic (at
% % undetectably low luminances), so I'll interpolate it my damn self.
% gamma16bit = zeros(1, 2^16);
% for ii = 2:size(gamma16bit, 2)
%     Lind = find(Lclip >= Lline(ii), 1);
%     dL = Lcharacteristic(Lind) - Lclip(Lind-1);
%     dleft = (Lline(ii) - Lclip(Lind-1))/dL;
%     dright = (Lclip(Lind) - Lline(ii))/dL;
%     gamma16bit(ii) = grays(Lind-1)*dright + grays(Lind)*dleft;
% end
% 
% % pull out 256 equally-spaced values for an 8-bit gamma table
% %   scale to [0, 1]
% gamma8bit = repmat((gamma16bit(1:257:end)')/(2^16-1), 1, 3);

% MATLAB's interp1 whines about duplicate values in Lcharacteristic (at
% undetectably low luminances), so I'll interpolate it my damn self.
gamma8bit = zeros(256,1);
for ii = 2:length(gamma8bit)
    Lind = find(Lclip >= Lline(ii), 1);
    dL = Lcharacteristic(Lind) - Lclip(Lind-1);
    dleft = (Lline(ii) - Lclip(Lind-1))/dL;
    dright = (Lclip(Lind) - Lline(ii))/dL;
    gamma8bit(ii) = [grays(Lind-1)*dright + grays(Lind)*dleft]/255;
end
gamma8bit = repmat(gamma8bit, 1, 3);

% fake 16-bit table
gamma16bit = linspace(0, (2^16)-1, 2^16);

% save gamma tables to disk
%   change the name of the file to match the remote client.
hndot = find(host == '.');
gammaFile = ['Gamma_', host(1:hndot), 'mat'];
pth = mfilename('fullpath');
pi = strfind(pth, '/utilities/');
save(['/Users/lab/GoldLab/Matlab/mfiles_lab/DotsX/classes/graphics,gammaFile'], ...
    'gamma16bit', 'gamma8bit', 'grays', 'data', 'host');

