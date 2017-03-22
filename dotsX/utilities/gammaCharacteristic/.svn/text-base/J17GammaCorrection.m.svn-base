% J17GammaCorrection.m
%
% A script to measure a gamma characteristic and save gamma tables.
%
%   This script is intended to run with a remote graphics slave, which is
%   the same configuration as the current psychophysics rig.
%
%   It will show a sequence of gray patches on the remote CRT and measure
%   luminances with the J17 photometer, automaticaly, via the serial port.
%   Thus it will obtain the gamma characteristif of the remote CRT.
%
%   Then this script will compute two gamma tables and save them with a
%   naming convention that will allows DotsX to load them automaically
%   during rInit.  The two tables are:
%
%       One normal gamma table in 3x8-bit RGB format, saved in a variable
%       called gamma8bit.  This will contain 256x3 intenstities in the
%       range 0-1.
%
%       One special gamma table for the Bits++ graphics processor in
%       16-bit format, saved in a variable called gamma16bit.  This will
%       contain 65536 integers in the range 0-65535.
%
%   It will save both these gamma tables, along with the raw data used to
%   compute them, in a file called Gamma_hostname.mat.  "hostname" is the
%   name of the local host of the remote graphics slave.
%
%   To access the J17 on the serial port, this script relies on another
%   that I wrote, called J17Read.  In turn, J17Read relies on a
%   Psychtoolbox function called SerialComm.  So you have to get the serial
%   port configred on this macine before you can use this script.
%
%   Here's the basic use case:
%
%   -Connect the J17 photometer to the serial port on this computer, via the
%   converter cable that looks like a serial port on one end and a
%   headphone plug on the other end.
%
%   -Attach the J1805 probe to the J17.  Suction the J1805 to the middle
%   of the CRT of the remote graphics slave.
%
%   -Run this script.  It may take a while, since it makes repeated
%   measurements and takes a little time between them.  You should see a
%   plot develop as the script runs.
%
%   -This script will produce a new file (or overwrite an existing file)
%   which is named after the remote client macine.  You'll need to move
%   this file to the remote client computer.  The best way to do this is to
%   do svnCheck('DotsX', 'in', '...') on this computer, then 
%   svnCheck('DotsX', 'up'), on the client computer.
%
%   Then the new gamma table should be in place on the client computer.  It
%   should load automatically next time you run rInit or rRemoteClient on
%   the client computer!
%
%   See also, J17Read, SerialComm, unix('hostname')

% 2008 by Benjamin Heasly
%   University of Pennsylvania
%   benjamin.heasly@gmail.com

clear all

% connect to client
rInit('remote');

% number of gray values to check (should be 256)
gInt = linspace(0, 255, 256);

% repeated measurements to average
m = 5;

% record of all luminance measurements
L = zeros(m,256);

% screen background should be similar to experimental conditions
bgColor = [1 1 1]*128;

% set a trivial gamma table on the remote graphics card
%   this way, gamma table intensities are predictable
sendMsgH('global oldGamma identityGamma; identityGamma = repmat(linspace(0,1,256)'', 1, 3);oldGamma = Screen(''LoadNormalizedGammaTable'',rWinPtr, identityGamma);');

% show all measurements as they come in
figure(444)
s = surf(gInt, 1:m, L);
title(sprintf('%d luminances measures each, at %d grayscale integers', m, 256))
ylabel('measurement #')
ylim([1,m])
xlabel('grayscale integer')
xlim(gInt([1 end]))
zlabel('CRT luminance')
view(0, 0)

% measure CRT luminance response to each gray
try

    % round patch for showign grays
    rAdd('dXtarget', 1, ...
        'visible', true, ...
        'diameter', 9);

    % open the serial comm port to the J17
    d = J17Read(1,true);
    if ~isempty(d)
        for ii = 1:256

            % increment grayscale integer
            rSet('dXtarget', 1, 'color', [1 1 1]*gInt(ii));
            rGraphicsDraw;

            % give time for the J1805 to equilibrate
            WaitSecs(1);

            % record the luminance reponse
            [d, units, t] = J17Read(m, true, true);
            L(:,ii) = d;

            % update -- this could take a while
            disp(sprintf('%d/%d at %s', ii, 256, datestr(now)))

            % update the plot
            set(s, 'ZData', L);
            drawnow;
        end
    end
catch
    e = lasterror
    disp(e.message)
end
rDone
J17Read(0, false, true);

% Compute the gamma table from the measured characteristic

% mean luminance responses
Lmean = mean(L);
Lmax = max(Lmean);

% the ideal, proportional responses
Lprop = linspace(0, Lmax, 256);

% calculate the normal, RGBgamma table
%   interpolate for the 16-bit table
gamma8bit = zeros(256,3);
gamma16bit = zeros(2^16,1);
gamma8bit(1) = 0;
for ii = 2:256

    % 8-bit: intensity lookup from the gamma characteristic
    jj = find(Lmean >= Lprop(ii), 1, 'first');
    gamma8bit(ii,:) = gInt(jj)/255;

    % 16-bit: linear interpolation from the 8-bit table, and rescaling
    interp = linspace(gamma8bit(ii-1,1), gamma8bit(ii,1), 256);
    gamma16bit((1:256) + (ii-2)*256) = ceil((2^16-1)*interp);
end
interp = linspace(gamma8bit(255,1), gamma8bit(256,1), 256);
gamma16bit((1:256) + (255)*256) = ceil((2^16-1)*interp);

% get the remote client's hostname, to name these gamma tables, and
% save gammaTables in Data/Calibration/MonitorGamma/
sendMsgH('[s,h]=unix(''hostname'');sendMsg(h)')
host = getMsg(1000);
dot  = find(host == '.');
save(fullfile(ROOT_STRUCT.dataDir, 'Calibration', 'MonitorGamma', ...
    ['Gamma_', host(1:dot), 'mat']), ...
    'gamma8bit', 'gamma16bit', 'L', 'gInt', 'bgColor', 'host');
