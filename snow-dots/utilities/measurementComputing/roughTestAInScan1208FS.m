function roughTestAInScan1208FS()
% Informal test of AInScan1208FS class.
%
%   Want each of its public methods to succeed:
%       constructor
%       close()
%       getScanWaveforms()
%       prepareToScan()
%       startScan()
%       stopScan()
%
%   And want to plot a sensible waveform at the end.

% Construct, looking for any connected 1208FS
aIn = AInScan1208FS();
assert(aIn.isAvailable, '1208FS unavailable')

% choose some differential channels
%   these have configurable gains, making for a fuller test
aIn.channels = [8 9 10 11];
aIn.gains = [0 2 4 6];

% choose other scan parameters arbitrarily
duration = 1;
aIn.frequency = 2000;
aIn.nSamples = ceil(duration*aIn.frequency);

% configure the device
configTime = aIn.prepareToScan();
assert(configTime > 0, '1208FS configuration error')

% do the scan
startTime = aIn.startScan();
assert(startTime > 0, '1208FS scan start error')
endTime = startTime + duration + 1;
while mexHID('check') < endTime
    pause(.01);
end

% stop the scan (should be unnecessary but allowed)
stopTime = aIn.stopScan();
assert(stopTime > 0, '1208FS scan stop error')

% process data into useful waveforms
[chans, volts, times, uints] = aIn.getScanWaveform();
assert(isequal(unique(chans), sort(aIn.channels)), ...
    '1208FS reported incorrect channels');

% release mexHID resources
closeStatus = aIn.close();
assert(closeStatus >= 0, '1208FS close error')

%% phoney up some data
% n = 1:aIn.nSamples;
% chans = aIn.channels(1 + mod(n, numel(aIn.channels)));
% volts = chans .* linspace(0, 1, aIn.nSamples);
% times = linspace(0, duration, aIn.nSamples);
% uints = ceil(volts*100);
% 
% configTime = -0.1*duration;
% startTime = 0;
% stopTime = 1.5*duration;


%% look at waveforms
%   public method timestamps
%   volts(time) line for each channel
%   uints(time) line for each channel
%   unconstrained axes
close all
f = figure();
axVolts = subplot(2, 1, 1, 'Parent', f);
axUints = subplot(2, 1, 2, 'Parent', f);
referenceTime = startTime;
arbitraryY = mean(volts);
l(1) = line(configTime-referenceTime, arbitraryY, ...
    'Parent', axVolts, ...
    'Linestyle', 'none', ...
    'Marker', '*', ...
    'Color', [1 0 0]);
l(2) = line(startTime-referenceTime, arbitraryY, ...
    'Parent', axVolts, ...
    'Linestyle', 'none', ...
    'Marker', '*', ...
    'Color', [0 1 0]);
l(3) = line(stopTime-referenceTime, arbitraryY, ...
    'Parent', axVolts, ...
    'Linestyle', 'none', ...
    'Marker', '*', ...
    'Color', [0 0 1]);
l = copyobj(l([3,2,1]), axUints);
arbitraryY = mean(uints);
set(l, 'YData', arbitraryY);
timestampNames = {'configure scan', 'start scan', 'stop scan'};

nChans = numel(aIn.channels);
chanNames = cell(1, nChans);
for ii = 1:nChans
    c = aIn.channels(ii);
    chanNames{ii} = sprintf('channel %d', c);
    chanColor = dec2bin(ii, 3)=='1';
    channelSelector = chans == c;
    line(times(channelSelector)-referenceTime, volts(channelSelector), ...
        'Parent', axVolts, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', chanColor);
    line(times(channelSelector)-referenceTime, uints(channelSelector), ...
        'Parent', axUints, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', chanColor);
end
legend(axUints, timestampNames{:}, chanNames{:}, 'Location', 'best')

