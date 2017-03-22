function [slope, intercept] = clockDriftPMD(reps)

% measure the timing drift between the clock in this computer and the clock
% in the attached PMD1208-FS or USB1208-FS digital-analog converter.

clf
global ROOT_STRUCT

% sample frequency
some = logspace(0, 4, 10);
f = repmat(some, 1, reps);
for ii = 1:length(f)
    
    rInit('debug')

    % setup the PMD
    chan = 0;
    mode = 7;
    [load, loadID] = formatPMDReport('AInSetup', chan, mode);
    [scan, scanID] = formatPMDReport('AInScan', chan, f(ii));
    [stop, stopID] = formatPMDReport('AInStop');

    % setup HIDx data processing
    channel.ID      = chan;
    channel.gain    = 1;
    channel.offset	= 0;
    channel.high	= nan;
    channel.low     = nan;
    channel.delta	= 0;
    channel.freq	= f(ii);

    % initialize the HIDx and the PMD
    rAdd('dXPMDHID', 1, 'HIDChannelizer', channel, ...
        'loadID', loadID, 'loadReport', load, ...
        'startID', scanID, 'startReport', scan, ...
        'stopID', stopID, 'stopReport', stop);

    p_ = rGet('dXPMDHID');

    % start the clock on the PMD
    ROOT_STRUCT.dXPMDHID = reset(ROOT_STRUCT.dXPMDHID);
    start_time = get(ROOT_STRUCT.dXPMDHID, 'startScanTime');

    % wait for the first report to arrive
    v = get(ROOT_STRUCT.dXPMDHID, 'values');
    while isempty(v);
        HIDx('run');
        v = get(ROOT_STRUCT.dXPMDHID, 'values');
    end
    end_time = GetSecs;

    rDone;

    pmdTime(ii) = 31/f(ii);
    CPUTime(ii) = end_time-start_time;
end

% plot the time measurements and fit a line
%   y-intercept is a (constant) offset between the CPU time axis and the
%   PMD time axis, which is hard to avoid
%   slope is the difference in counting rates of the two digital clocks,
%   which we hope is unity.

% plot unity slope with 0 intercept
domain = [0, max(pmdTime)];
line(domain, domain, 'Color', [1 0 0]);

% plot the real data and fit a line
line(pmdTime, CPUTime, 'Color', [0 0 1], ...
    'Marker', '.', 'LineStyle', 'none')
lin = lsline;
lsX = get(lin, 'XData');
lsY = get(lin, 'YData');
slope = diff(lsY)/diff(lsX);
intercept = lsY(1);
% disp([slope, intercept])