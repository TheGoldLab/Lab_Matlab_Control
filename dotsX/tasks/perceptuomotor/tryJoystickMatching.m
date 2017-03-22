% Use a joystick connected to the PMD/USB 1208FS to vary some stimulus,
% like a contrast patch or whatever, to match some reference.
%   Two dimensions of Joystick...two dimensions of stimulus?
%   How about a 2D red-blue color field.  Then, position and color are
%   linked.  Find the matching color, with or without feedback.

% 2008 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT
rInit('debug')

% get a success sound
yay = rAdd('dXsound', 1, 'mute', false, 'rawSound', 'Coin.wav');

% sample frequency
f = 1000;

% voltage range
maxV = 5;
minV = 0;
midV = mean([minV,maxV]);

% tolerance on voltage match
tolV = .3;

% threshold for trigger
trigV = 1;

% read pins 1, 2, and 4 vs. ground (pin 3)
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

% make a plot area
f = figure(46);
clf(f);
ax = axes('Parent', f, ...
    'XLim', [0 maxV], ...
    'YLim', [0 maxV], ...
    'XTick', [], ...
    'YTick', [], ...
    'DataAspectRatio', [1 1 1]);

% make a reference patch
xRef = rand*maxV;
yRef = rand*maxV;
ref = patch([0 1 1 0]*maxV, [0 0 1 1]*maxV, ([xRef 0 yRef]-minV)/(maxV-minV), ...
    'Parent', ax, ...
    'EdgeColor', 'none');

% make an probe patch
probe = patch([0 1 1 0]*tolV+midV-tolV/2, [0 0 1 1]*tolV+midV-tolV/2, [0 0 0], ...
    'Parent', ax, ...
    'EdgeColor', [1 1 1], ...
    'FaceColor', 'none', ...
    'LineWidth', 1);

drawnow

% press F3 to error/quit
try
    while true

        % get HID events
        WaitSecs(.002);
        HIDx('run');
        val = get(ROOT_STRUCT.dXPMDHID, 'values');

        if ~isempty(val)

            % update probe position
            x = val(find(val(:,1)==chans(1), 1, 'last'), 2);
            y = val(find(val(:,1)==chans(2), 1, 'last'), 2);

            % set(probe, ...
            %     'XData', [0 1 1 0]*tolV + x*(maxV-tolV)/maxV, ...
            %     'YData', [0 0 1 1]*tolV + y*(maxV-tolV)/maxV);
            % set(probe, 'FaceColor', ([x 0 y]-minV)/(maxV-minV));

            % detect trigger press
            trig = any(val(val(:,1)==chans(3), 2) < trigV);
            if trig

                % reveal probe color
                set(probe, 'FaceColor', ([x 0 y]-minV)/(maxV-minV));

                % check for match
                if abs(x-xRef) <= tolV && abs(y-yRef) <= tolV
                    rPlay('dXsound', yay);
                end

                pause(1)

                % hold unil release
                while trig
                    WaitSecs(.002);
                    HIDx('run');
                    val = get(ROOT_STRUCT.dXPMDHID, 'values');
                    if ~isempty(val)
                        trig = any(val(val(:,1)==chans(3), 2) < trigV);
                        ROOT_STRUCT.dXPMDHID = ...
                            set(ROOT_STRUCT.dXPMDHID, 'values', []);
                    end
                end

                % pick new reference target
                xRef = rand*maxV;
                yRef = rand*maxV;
                set(ref, 'FaceColor', ([xRef 0 yRef]-minV)/(maxV-minV))

                % hide probe color
                set(probe, 'FaceColor', 'none');
            end

            % done with these values
            ROOT_STRUCT.dXPMDHID = set(ROOT_STRUCT.dXPMDHID, 'values', []);

            drawnow
        end
    end
end
rDone;
close(f)