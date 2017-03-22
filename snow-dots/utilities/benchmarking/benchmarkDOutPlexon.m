% Measure intervals between strobed words sent to Plexon.
% @param dOutObject dotsAllDOutObjects object to send words to Plexon
% @param ensemble ensemble object to access Plexon machine
% @param words values to ouput from @a dOutObject
% @param intervals delays between repetition of each word
% @details
% @a dOutObject must be an object that inherits the dotsAllDOutObjects
% superclass.  It will send strobbed digital words to Plexon.
% @details
% @a ensemble may be used to access a remote instance of Matlab, where the
% Plexon Matlab client SDK is running.  If provided, @a ensemble should be
% connected to a dotsEnsembleServer runnon on the same Matlab instance as
% the Plexon Matlab client SDK.  By default, tries to access the Plexon
% Matlab client SDK in the local Matlab instance.  See
% fetchIntervalPlexon.m.
% @details
% @a words may specify which unique word values to send to Plexon.  The
% default words are 8-bit (0:255).  @a intervals may specify unique delays
% to wait between pairs of words.  The default @a intervals are linspace(0, 1, 10).
% <b>The Test</b>
% @details
% Uses @a dOutObject to output m x n pairs of strobed words, separated
% by various delays.  m is the number of @a intervals and n is the number
% of @a words.  Since a pair of words surrounds each interval, each unique
% word is output 2*m times.
% @details
% Outputs each pair of strobed words with the following sequence:
%   - uses @a dOutObject to output the first of a word and gets a "before
%   timestamp"
%   - uses mglGetSecs() to get a "before clock time"
%   - uses mglWaitSecs() to delay for a given "nominal interval"
%   - uses @a dOutObject to output the last word and gets an "after
%   timestamp"
%   - uses mglGetSecs() to get an "after clock time"
%   - evaluates the before-after interval as "seen" by the Plexon Matlab
%   client SDK
%   .
% Each "nominal interval" is be compared to three other measurements
% of the same interval: the interval between @a dOutObject timestamps, the
% interval between mglGetSecs() timestamps, and the interval between
% Plexon strobbed word timestamps.
% @details
% <b>The Results</b>
% @details
% Ideally, all three interval measurements would match the nominal
% interval.  But in practice, each function call takes a finite, random
% time to complete.  Furthermore, the a local clock and plexon clock might
% count at different rates.  So the measured intervals may differ from
% nominal, and from one another.
% @details
% benchmarkDOutPlexon() makes three plots to compare interval
% measurements.  The top plot assesses basic agreement among the nominal
% intervals and the three measured intervals.  It's internded as a raw
% "smell test" of the raw measured intervals: its time scale is coarse and
% each data point may hide a cluster of data points.
% @details
% The bottom two plots focus on how well the intervals between @a
% dOutObject timestamps agree with the intervals as as "seen" from Plexon.
% @details
% For the bottom left plot, intervals from @a dOutObject and Plexon are
% grouped by nominal interval.  The mean of each group is subtracted, so
% that all the intervals cluster near 0.  The mean-subtracted @a dOutObject
% and Plexon intervals are plotted against each other.  If the measurements
% from each source agree, all the points will fall near the unity line
% (i.e. x=y).
% @details
% For the bottom right plot, intervals from @a dOutObject and Plexon are
% each transformed by linear regression into the time frame of
% mglWaitSecs() (the nominal delay).  The residual "jitteriness", not
% accounterd for by the regression, is plotted.  As above, the points
% should fall along the unity line.  See clockDriftEstimate() for more
% about transforming time values as "seen" from different clocks.
% @details
% Returns a struct with 5 fields:
%   - @b words the given @a words, or defaults
%   - @b intervals the given delay @a intervals, or defaults
%   - @b dOutResiduals m x n matrix of jitter residuals, as "seen" by @a
%   dOutObject timestamps.  m is the number of @a intervals and n is the
%   number of @a words
%   - @b plexonResiduals mxn matrix of jitter residuals, as "seen" by
%   Plexon
%   - @b clockResiduals mxn matrix of jitter residuals, as "seen"
%   from mglGetSecs()
%   .
%
% @ingroup dotsUtilities
function data = benchmarkDOutPlexon(dOutObject, ensemble, words, intervals)

data = [];

if nargin < 1 || ~isobject(dOutObject)
    name = dotsTheMachineConfiguration.getDefaultValue('dOutClassName');
    dOutObject = feval(name);
end

if nargin < 2 || isempty(ensemble)
    ensemble = topsEnsemble('benchmark dOut');
end

if nargin < 3 || isempty(words)
    words = 0:255;
end

if nargin < 4 || isempty(intervals)
    intervals = linspace(0, 1, 10);
end

% estimate test duration
disp(sprintf('Expected test duration: %.0f seconds', ...
    sum(intervals)*numel(words)));

% add the fetch funciton to the ensemble for remote access
ensemble.addCall({@fetchIntervalPlexon, 'init'}, 'init');
ensemble.addCall({@fetchIntervalPlexon}, 'fetch');
ensemble.addCall({@fetchIntervalPlexon, 'close'}, 'close');
ensemble.alwaysRunning = false;

n = numel(words);
m = numel(intervals);
dOutIntervals = zeros(m,n);
clockIntervals = zeros(m,n);
plexonIntervals = zeros(m,n);

% send word pairs and collect timestamps
%   duplicate the first word to make sure functions are loaded
ensemble.callByName('init');
for jj = [1 1:n]
    for ii = [1 1:m]
        dOutPre = dOutObject.sendStrobedWord(words(jj), 0);
        clockPre = mglGetSecs();
        mglWaitSecs(intervals(ii));
        clockPost = mglGetSecs();
        dOutPost = dOutObject.sendStrobedWord(words(jj), 0);
        
        dOutIntervals(ii,jj) = dOutPost - dOutPre;
        clockIntervals(ii,jj) = clockPost - clockPre;
        plexonIntervals(ii,jj) = ensemble.callByName('fetch');
    end
end
ensemble.callByName('close');

% organize data to be returned
data.words = words;
data.intervals = intervals;
data.waitFunction = @mglWaitSecs;
data.clockFunction = @mglGetSecs;

nominalIntervals = repmat(intervals', 1, n);

% For each interval measurement, compute the simple regression to map
% measured intervals into the frame of reference of the nominal intervals
% and compute the residuals jitter not accounted for by the regression
dOutToNominal = clockDriftEstimate( ...
    dOutIntervals, nominalIntervals);
dOutFit = clockDriftApply( ...
    dOutIntervals, dOutToNominal);
data.dOutResiduals = nominalIntervals - dOutFit;
data.dOutIntervals = dOutIntervals;

clockToNominal = clockDriftEstimate( ...
    clockIntervals, nominalIntervals);
clockFit = clockDriftApply( ...
    clockIntervals, clockToNominal);
data.clockResiduals = nominalIntervals - clockFit;
data.clockIntervals = clockIntervals;

plexonToNominal = clockDriftEstimate( ...
    plexonIntervals, nominalIntervals);
plexonFit = clockDriftApply( ...
    plexonIntervals, plexonToNominal);
data.getplexonResiduals = nominalIntervals - plexonFit;
data.plexonIntervals = plexonIntervals;

%% plot strobed word data
f = figure(100);
clf(f);
set(f, 'Name', mfilename, 'NumberTitle', 'off');

% the top axes show raw data
spacer = min(diff(intervals));
rawAx = subplot(2,1,1, ...
    'Parent', f, ...
    'XLim', [min(intervals)-spacer, max(intervals)+spacer], ...
    'XTick', unique(sort(intervals)), ...
    'XGrid', 'on', ...
    'YLim', [min(intervals)-spacer, max(intervals)+spacer], ...
    'YTick', unique(sort(intervals)), ...
    'YGrid', 'on');
title(rawAx, 'strobe pair delay intervals')
ylabel(rawAx, 'measured interval')
xlabel(rawAx, ...
    sprintf('nominal interval from %s', func2str(@mglGetSecs)))

% the bottom left axes show mean-subtracted data for local and Plexon
% estimates of the interval between digital outputs
lims = [-.002 .002];
ticks = -.002:.001:.002;
subtractAx = subplot(2,2,3, ...
    'XLim', lims, ...
    'XTick', ticks, ...
    'XGrid', 'on', ...
    'YLim', lims, ...
    'YTick', ticks, ...
    'YGrid', 'on', ...
    'Parent', f);
title(subtractAx, 'mean-subtracted')
xlabel(subtractAx, 'dOutIntervals')
ylabel(subtractAx, 'plexonIntervals')

% the bottom left axes show regression residuals for local and Plexon
% estimates of the interval between digital outputs
residualAx = subplot(2,2,4, ...
    'XLim', lims, ...
    'XTick', ticks, ...
    'XGrid', 'on', ...
    'YLim', lims, ...
    'YTick', ticks, ...
    'YGrid', 'on', ...
    'Parent', f);
title(residualAx, 'fit-to-nominal residual')
xlabel(residualAx, 'dOutIntervals')
ylabel(residualAx, 'plexonIntervals')

intervalNames = { ...
    'clockIntervals', 'dOutIntervals', 'plexonIntervals'};

nNames = numel(intervalNames);
cols = lines(nNames);
offOn = {'off', 'on'};
for ii = 1:m
    for jj = 1:nNames
        intervalTimes = data.(intervalNames{jj});
        placement = zeros(1,n)+(intervals(ii)+((jj-nNames/2)*(spacer/10)));
        line(placement, intervalTimes(ii,:), ...
            'Parent', rawAx, ...
            'HandleVisibility', offOn{1+(ii==1)}, ...
            'Marker', '+', ...
            'LineStyle', 'none', ...
            'Color', cols(jj,:));
    end
    
    line(data.dOutIntervals(ii,:) - mean(data.dOutIntervals(ii,:)), ...
        data.plexonIntervals(ii,:) - mean(data.plexonIntervals(ii,:)), ...
        'Parent', subtractAx, ...
        'Marker', '+', ...
        'LineStyle', 'none', ...
        'Color', [0 0 0]);
    
    line(data.dOutResiduals(ii,:), data.getplexonResiduals(ii,:), ...
        'Parent', residualAx, ...
        'Marker', '+', ...
        'LineStyle', 'none', ...
        'Color', [0 0 0]);
end
legend(rawAx, intervalNames{:}, 'Location', 'best')