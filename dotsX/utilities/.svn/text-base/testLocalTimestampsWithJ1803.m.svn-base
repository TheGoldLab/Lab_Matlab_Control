function testLocalTimestampsWithPhotodiode
% draw a patch in the corner of the screen to trigger a photodiode.  Redraw
% many times and record phododiode response with the PMD1208fs.

% 2007 by Benjamin Heasly
%   University of Pennsylvania

% start HIDx, etc
clear all
global ROOT_STRUCT val local vbl
rInit('local')
wn = rWinPtr;

% scan time
secs = 10;

% remote refresh rate
Hz = rGet('dXscreen', 1, 'frameRate');

% PMD sample frequency
f = 4000;

% record channel 0 (pin 1 minus pin2 differential mode)
chan = 0;

% record at in the +/- 1mV range
mode = 7;

% setup reports
[load, loadID] = formatPMDReport('AInSetup', chan, mode);
[scan, scanID] = formatPMDReport('AInScan', chan, f);
[stop, stopID] = formatPMDReport('AInStop');

% for processing (or not) raw channel data
channel.ID      = chan;
channel.gain    = 1;
channel.offset	= 0;
channel.high	= nan;
channel.low     = nan;
channel.delta	= 0;
channel.freq	= f;

% initialize the DAQ
rAdd('dXPMDHID', 1, 'HIDChannelizer', channel, ...
    'loadID', loadID, 'loadReport', load, ...
    'startID', scanID, 'startReport', scan, ...
    'stopID', stopID, 'stopReport', stop);

% to trigger the photodiode
rAdd('dXcorner', 1, 'color', [1 1 1]*255, 'color2', [1 1 1]*255, ...
    'visible', true, 'location', 3, 'size', 2);

% to show a potentially useful stimulus
rAdd('dXdots', 1, 'diameter', 7, 'density', 6, 'visible', true);
% rGraphicsDraw(inf);
% rDone


% allocate a big array for photodiode data
val = zeros(secs*f*1.1, 3);
ii = 0;

% and biggish arrays for timestamps
extra = 2;
frames = secs*Hz*extra;
local = zeros(round(frames), 1);
vbl = zeros(round(frames), 1);
onset = zeros(round(frames), 1);
flip = zeros(round(frames), 1);

% get out the first time jitters for loop functions
a = draw(ROOT_STRUCT.dXdots);
a = draw(ROOT_STRUCT.dXcorner);
HIDx('run');
a = get(ROOT_STRUCT.dXPMDHID, 'values');
a = set(ROOT_STRUCT.dXPMDHID, 'values', []);
[a, a, a] = Screen('Flip', wn);
[a, a, a] = Screen('Flip', wn);
WaitSecs(1);
local(1) = GetSecs;

% record a zero time and start the PMD scanning
jj = 1;
ROOT_STRUCT.dXPMDHID = reset(ROOT_STRUCT.dXPMDHID);
local(1) = GetSecs;
while local(jj) < local(1) + secs

    % wait first for vblank
    [vbl(jj), onset(jj), flip(jj)] = Screen('Flip', wn);
    
    % draw one frame
    ROOT_STRUCT.dXdots = draw(ROOT_STRUCT.dXdots);
    ROOT_STRUCT.dXcorner = draw(ROOT_STRUCT.dXcorner);

    % get new values
    %   do not grow the values array of dXPMDHID
    HIDx('run');
    v = get(ROOT_STRUCT.dXPMDHID, 'values');
    ROOT_STRUCT.dXPMDHID = set(ROOT_STRUCT.dXPMDHID, 'values', []);
    l = size(v, 1);
    if l>0
        val(ii+1:ii+l, :) = v;
        ii = ii+l;
    end

    jj = jj+1;
    local(jj) = GetSecs;
end

% clear up
[vbl(jj), onset(jj), flip(jj)] = Screen('Flip', wn);
jj = jj+1;
[vbl(jj), onset(jj), flip(jj)] = Screen('Flip', wn);

% harvest trailing values
for kk = 1:3
    WaitSecs(.01);
    HIDx('run');
    v = get(ROOT_STRUCT.dXPMDHID, 'values');
    ROOT_STRUCT.dXPMDHID = set(ROOT_STRUCT.dXPMDHID, 'values', []);
    l = size(v, 1);
    if l>0
        val(ii+1:ii+l, :) = v;
        ii = ii+l;
    end
end

% clear out
rDone;

% make fresh figure, axes
clf(figure(42));

% trace the raw photodiode data
ax(1) = subplot(3,1,1, 'XLim', [0,secs*1.1]);
ylabel(ax(1), sprintf('channel %d', chan));
xlabel(ax(1), 'time (sec)');
[times, order] = sort(val(:,3));

% align photodiode times with GetSecs/Flip times
PMDOffset = get(ROOT_STRUCT.dXPMDHID, 'startScanTime') - local(1);
times = times + PMDOffset;

photo = val(order, 2);
pl = line(times, photo, 'Parent', ax(1), ...
    'Color', [0 1 0], ...
    'LineStyle', '-', ...
    'Marker', 'none');

% find all peakVals below some threshiold
%   show distribution of peak values
%   should be bimodal and well-separated
thEasy = -18;
dPhoto = diff(photo);
peakInds = find(...
    photo(1:end-1) <= thEasy ...
    & dPhoto >= 0 ...
    & circshift(dPhoto, 1) < 0 ...
    & circshift(dPhoto, 2) < 0);
peakVals = photo(peakInds);
peakLine = line(times(peakInds), peakVals, 'Parent', ax(1), ...
    'Color', [0 0 0], ...
    'LineStyle', 'none', ...
    'Marker', '*');

ax(3) = subplot(3,1,3);
edges = -40:0;
peakValHist = histc(peakVals, edges);
bar(edges, peakValHist);
xlabel(ax(3), 'photodiode peak value (approx mV)');
ylabel(ax(3), 'instance count');

% find pairs of frames
%   alternating gray and white circle, and Screen return times
thGray = max(peakVals) + 1;
thWhite = mean(peakVals);
% whiteTimes = times(peakInds(peakVals <= thWhite));
% fw = line(whiteTimes, thWhite*ones(size(whiteTimes)), 'Parent', ax(1), ...
%     'Color', [0 0 1], ...
%     'LineStyle', 'none', ...
%     'Marker', '*');
grayTimes = times(peakInds(peakVals <= thGray));
fg = line(grayTimes, thGray*ones(size(grayTimes)), 'Parent', ax(1), ...
    'Color', [0 1 1], ...
    'LineStyle', 'none', ...
    'Marker', '*');

% mark the Screen timestamps from remote machine
%   on the raw data plot
% line(local(1:jj)-local(1), thGray*ones(1,jj), 'Parent', ax(1), ...
%     'Color', [0 0 0], ...
%     'LineStyle', 'none', ...
%     'LineWidth', 1, ...
%     'Marker', '.');
line(vbl(1:jj)-local(1), thGray*ones(1,jj), 'Parent', ax(1), ...
    'Color', [1 0 0], ...
    'LineStyle', 'none', ...
    'LineWidth', 1, ...
    'Marker', '.');
% line(onset(1:jj)-local(1), thGray*ones(1,jj), 'Parent', ax(1), ...
%     'Color', [1 1 0], ...
%     'LineStyle', 'none', ...
%     'LineWidth', 1, ...
%     'Marker', '.');
line(flip(1:jj)-local(1), thGray*ones(1,jj), 'Parent', ax(1), ...
    'Color', [0 0 1], ...
    'LineStyle', 'none', ...
    'LineWidth', 1, ...
    'Marker', '.');


% show all interframe intervals
%   for gray and white separately
ax(2) = subplot(3,1,2, 'XLim', [0,secs*1.1], 'YLim', [0.01, 0.02]);
% line(whiteTimes(2:end), diff(whiteTimes), ...
%     'color', [0 0 1], 'Parent', ax(2));
line(grayTimes(2:end), diff(grayTimes), ...
    'color', [0 1 1], 'Parent', ax(2));
line(vbl(2:jj)-local(1), diff(vbl(1:jj)), ...
    'color', [1 0 0], 'Parent', ax(2));
% line(onset(2:jj)-local(1), diff(onset(1:jj)), ...
%     'color', [1 1 0], 'Parent', ax(2));
line(flip(2:jj)-local(1), diff(flip(1:jj)), ...
    'color', [0 0 1], 'Parent', ax(2));
xlabel('"frame" time')
ylabel('inter"frame" interval (sec)')