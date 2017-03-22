% Use a joystick connected to the PMD/USB 1208FS to move a cursor to a
% target.

% 2007 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT
rInit('debug')

% sample frequency
f = 1000;

% voltage range
maxV = 5;
minV = 0;
midV = mean([minV,maxV]);

% ring radius and target tolerance
rV = 1;
wV = .2;

% read pin 1 minus pin 2 differential
chans = 8:9;
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

% make a plot area
f = figure(46);
clf(f);
ax = axes('Parent', f, ...
    'XLim', [minV, maxV]+[-1, 1]*wV, ...
    'YLim', [minV, maxV]+[-1, 1]*wV, ...
    'DataAspectRatio', [1 1 1]);

% make a cursor
l = line(nan, nan, 'Parent', ax, ...
    'Color', [0 0 1], ...
    'LineStyle', 'none', ...
    'Marker', '.');

% make a fixation point
fp = line(midV, midV, 'Parent', ax, ...
    'Color', [0 0 0], ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'MarkerSize', 10);

% make a two targets
tx(1:2) = midV;
ty(1:2) = midV;
goBack = true;
t1 = line(tx(1), ty(1), 'Parent', ax, ...
    'Color', [1 0 0], ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'MarkerSize', 50);

t2= line(tx(2), ty(2), 'Parent', ax, ...
    'Color', [0 1 0], ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'MarkerSize', 50);

% make an exit label
text(maxV, maxV, 'EXIT')

drawnow

while true

    % get HID events
    WaitSecs(.002);
    HIDx('run');
    val = get(ROOT_STRUCT.dXPMDHID, 'values');

    if ~isempty(val)
        x = val(find(val(:,1)==chans(1), 1, 'last'), 2);
        y = val(find(val(:,1)==chans(2), 1, 'last'), 2);
        set(l, 'XData', x, 'YData', y);

        % check for target tag
        if abs(x-tx(1)) <= wV && abs(y-ty(1)) <= wV

            if goBack
                ang = rand(1,2)*2*pi;
                tx(1:2) = midV+rV*cos(ang);
                ty(1:2) = midV+rV*sin(ang);
            else
                tx(1:2) = midV;
                ty(1:2) = midV;
            end
            goBack = ~goBack;

            set(t1, 'XData', tx(1), 'YData', ty(1));
            set(t2, 'XData', tx(2), 'YData', ty(2));

        elseif abs(x-maxV) <= wV && abs(y-maxV) <= wV

            % quit!
            break
        end

        % done with these values
        ROOT_STRUCT.dXPMDHID = set(ROOT_STRUCT.dXPMDHID, 'values', []);

        drawnow
    end
end
rDone;
close(f)