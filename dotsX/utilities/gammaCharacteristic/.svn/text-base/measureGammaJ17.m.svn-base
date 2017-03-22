% measureGammaJ17
%
% OBSOLETE script for measuring Gamma. see J17GammaCorrection
%   for the latest.
%
% step through 256 linearly spaced gray values ranging from 0 to 255 and
% measure screen luminance with J17 light meter, over serial port.
%
% I set the J17 to use manual range.  It has 8 ranges.  The 7th range
% captures the most detail at the higher luminances.  The 8th range
% captures slightly more detail at the lower luminances, but it clips in
% the higher range.  Measurements using both ranges agree very well in the
% middle luminance range.  I'm sticking with the 7th range, since the low
% range detail is not that important (our stimuli are relative to gray, not
% black)
%
% Bright regions on the CRT compete for electron gun power.  So a white
% circle will be very briht against a black bg (maybe 120 cd/m^2) and
% dimmer against a light-gray bg (maybe only 100 cd/m^2).  This spatial
% luminiance interdependence makes calibration tricky.  See
%   "Testing a calibration method for colour monitors.  A method to
%   characterize the extent of spatial interdependence and channel
%   interdependence", Bodrogi and Schnada, 1995.
% So, save a lot of headache by calibrating under conditions similar to the
% experiment in question--especially using the same bg during calibration
% as will be used during the experiment.

% If you're measuring the gamma characteristic for the first time, make
% sure the machine in question is using a linear gamma table.  i.e., on the
% machine in question, delte or rename, or move out of the MATLAB path,
%   DotsX/classes/graphics/Gamma_foo.mat,
% wherDonere foo is the hostname of the machine in question.  This will cause
% dXscreen to default to a linear gamma table.

% If you're verifying an existing gamma table, make sure
%   DotsX/classes/graphics/Gamma_foo.mat
% is on the MATLAB path, so that dXscreen load the table for the machine in
% question.

% connect to client
rInit('remote');

% repeat measurements to get a mean
num_measurements = 5;

% define 'gray' for particular configuration:
num_conditions = 255;
data = zeros(num_conditions, num_measurements);

% for regular 8-bit rgb graphics cards:
%   r=g=b
r = linspace(0, 255, num_conditions);
g = linspace(0, 255, num_conditions);
b = linspace(0, 255, num_conditions);
bgColor = [0 0 0];
grays = linspace(0, 255, num_conditions);
% sendMsgH('global oldGamma identityGamma');
% sendMsgH('identityGamma = repmat((0:255)/255, 3, 1)'';');
% sendMsgH('oldGamma = Screen(''LoadNormalizedGammaTable'',rWinPtr, identityGamma);');

% for 8-bit rgb graphics card driving mono++ box:
%   There are 2^16 digital gray settings.
%   Measure luminance at increments of 257 digital grays
%   set overlay channel (blue) to 0
% r = linspace(0, 255, num_conditions);
% g = linspace(0, 255, num_conditions);
% b = zeros(1, num_conditions);
% grays = 256*r + g;

% set bg color to 30 lumens
% (found by trial and error because we don't know the gamma table yet)
bgColor = [1 1 1]*159;

% set the experiment-like bg luminance/color
rSet('dXscreen', 1, 'bgColor', bgColor);
sendMsgH('draw_flag = 5;');

rAdd('dXtarget', 1, ...
    'visible', true, ...
    'diameter', 9, ...
    'color', [1,1,1]*0);
% sendMsgH('rSet(''dXscreen'',1,''loadGammaBitsPlus'', true);');

% show all measurements as they come in
figure(444)
s = surf(1:num_measurements, grays, data)
title(sprintf(...
    'gamma characteristic: %d luminance measures at %d digital gray values', ...
    num_measurements, num_conditions))
xlabel('measurement #', 'FontSize', 20)
xlim([1,num_measurements])
ylabel('digital gray value', 'FontSize', 20)
ylim([grays(1), grays(end)])
zlabel(sprintf('CRT response (%s)', 'units'), 'FontSize', 20)
view(90, 0)
drawnow

% measure CRT luminance response to all grays
try
    % open/test the serial comm port to the J17
    d = J17Read(1,true);
    d = true
    if ~isempty(d)
        for ii = 1:num_conditions

            % increment digital gray value (or whatever)
            rSet('dXtarget', 1, 'color', [r(ii), g(ii) b(ii)]);
            %rSet('dXtarget', 1, 'color', grays(ii)/(2^16 -1));
            sendMsgH('draw_flag = 3;');

            % give time for the light meter to equilibrate
            WaitSecs(1);

            % measure luminance reponse
            [d, units, t] = J17Read(num_measurements, true, true);
            data(ii,:) = d;

            % this could take a while
            %disp(sprintf('%.1f%% done measuring gamma!',100*ii/num_conditions))
            disp(sprintf('%d/%d at %s',ii, num_conditions, datestr(now)))

            % update the plot
            set(s, 'ZData', data);
            zlabel(sprintf('CRT response (%s)', units{1}), 'FontSize', 20)
            drawnow;
        end
    end
catch
    e = lasterror
    e.message
    rDone
    J17Read(0, false, true);
end
rDone
J17Read(0, false, true);

% get the remote hostname
sendMsgH('[s,h]=unix(''hostname'');sendMsg(h)')
host = getMsg(1000);

% compute and save a gamma lookup based on these measurements
%makeGammaTable