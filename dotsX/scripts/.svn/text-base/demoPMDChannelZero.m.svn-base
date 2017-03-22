% test data aqcuisition on channel 0 of the PMD1208FS
%   (possibly with the J1803 Luminance Head)

% 2007 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT
rInit('debug')

% scan time
secs = 1;

% sample frequency
f = 4000;

% setup the PMD
chan = 0;
mode = 7;
[load, loadID] = formatPMDReport('AInSetup', chan, mode);
[scan, scanID] = formatPMDReport('AInScan', chan, f);
[stop, stopID] = formatPMDReport('AInStop');

% setup HIDx data processing
channel.ID      = chan;
channel.gain    = 1;
channel.offset	= 0;
channel.high	= nan;
channel.low     = nan;
channel.delta	= 0;
channel.freq	= f;

% initialize the HIDx and the PMD
rAdd('dXPMDHID', 1, 'HIDChannelizer', channel, ...
    'loadID', loadID, 'loadReport', load, ...
    'startID', scanID, 'startReport', scan, ...
    'stopID', stopID, 'stopReport', stop);

% start acquiring data
val = zeros(secs*f*1.1, 3);
ii = 0;
ROOT_STRUCT.dXPMDHID = reset(ROOT_STRUCT.dXPMDHID);
start = get(ROOT_STRUCT.dXPMDHID, 'startScanTime');
while GetSecs < start + secs
    WaitSecs(.002);
    
    % move new values from HIDx buffer to the MATLAB workspace
    %   without growing the 'values' array of dXPMDHID
    HIDx('run');
    v = get(ROOT_STRUCT.dXPMDHID, 'values');
    ROOT_STRUCT.dXPMDHID = set(ROOT_STRUCT.dXPMDHID, 'values', []);
    l = size(v, 1);
    if l>0
        val(ii+1:ii+l, :) = v;
        ii = ii+l;
    end
end
rDone;

% make fresh figure, axes
ax(1) = axes('XLim', [0,secs*1.1]);
ylabel(ax(1), sprintf('channel %d', chan));
xlabel(ax(1), 'time (sec)');

% make sure samples are sorted by serial number
[times, order] = sort(val(:,3));
signal = val(order, 2);

% trace the raw signal
pl = line(times, signal, 'Parent', ax(1), ...
    'Color', [0 1 0], ...
    'LineStyle', '-', ...
    'Marker', 'none');