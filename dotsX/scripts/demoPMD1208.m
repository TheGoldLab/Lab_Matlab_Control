% use HIDx to demonstrate functionality, especially analog input and
% HIDx "channelizer" filtering of waveforms.

% 2007 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT
rInit('debug')

% scan time
secs = 10;

% % sample frequency
f = 1000;

% read pin 1 minus pin 2 differential
chans = 8:10;
nc = length(chans);

% gain and range modes for PMD channels
gains = [1 2 4 5 8 10 16 20];
ranges = [20 10 5 4 2.5 2 1.25 1];

modes = ones(size(chans))*2;

% setup reports
[load, loadID] = formatPMDReport('AInSetup', chans, modes-1);
[scan, scanID] = formatPMDReport('AInScan', chans, f);
[stop, stopID] = formatPMDReport('AInStop');

cc = num2cell(chans);
[channel(1:nc).ID]      = deal(cc{:});

gc = num2cell(0.01./gains(modes));
[channel(1:nc).gain]	= deal(gc{:});

[channel(1:nc).offset]	= deal(0);
[channel(1:nc).high]	= deal(nan);
[channel(1:nc).low]     = deal(nan);
[channel(1:nc).delta]	= deal(0);
[channel(1:nc).freq]	= deal(f);

rAdd('dXPMDHID', 1, 'HIDChannelizer', channel, ...
    'loadID', loadID, 'loadReport', load, ...
    'startID', scanID, 'startReport', scan, ...
    'stopID', stopID, 'stopReport', stop);

ROOT_STRUCT.dXPMDHID = reset(ROOT_STRUCT.dXPMDHID);

% make lines for fast plotting
clf(figure(44));
for ii = 1:nc
    ax(ii) = subplot(nc, 1, ii);
    maxV(ii) = ranges(modes(ii));
    retard = dec2bin(ii,3)=='0';
    l(ii) = line(nan, nan, 'Parent', ax(ii), ...
        'Color', retard(1:3), ...
        'LineStyle', 'none', ...
        'Marker', '.');
    set(ax(ii), 'XLim', [0,secs*1.1], 'YLim', [-1, 1]*1.1*max(maxV));
    ylabel(ax(ii), sprintf('%d', chans(ii)));
end
drawnow

start = GetSecs;
while GetSecs < start + secs
    WaitSecs(.002);
    HIDx('run');
    val = get(ROOT_STRUCT.dXPMDHID, 'values');
    if ~isempty(val)
        for ii = 1:nc
            ch = val(:,1)==(chans(ii));
            set(l(ii), 'XData', val(ch,3), 'YData', val(ch,2));
        end
        drawnow
    end
end
rDone;