% Measure timing of dotsClientEnsemble communications.
% @param showPlot whether or not to plot the timing results
% @param iterations how many transactions to measure
% @param delay delay to wait between transactions
% @details
% benchmarkClientEnsemble() creates a dotsClientEnsemble and performs
% transactions with a dotsEnsembleServer.  The dotsEnsembleServer must be
% running in another instance of Matlab.  This dotsClientEnsemble and the
% dotsEnsembleServer should expect to use the default network addresses
% from dotsTheMessenger.
% @details
% By default, plots the timing results in a new figure.  If @showPlot is
% provided and false, plots nothing.  @a iterations specifies how many
% transactions to exchange between client and server.  The default is 100.
% @a delay specifies how long to pause() between transactions, the default
% is 0.01 seconds.
% @details
% Returns a struct array with timing data for several parts of each
% transaction.
%
% @ingroup dotsUtilities
function data = benchmarkClientEnsemble(showPlot, iterations, delay)

if nargin < 1 || isempty(showPlot)
    showPlot = true;
end

if nargin < 2 || isempty(iterations)
    iterations = 100;
end

if nargin < 3 || isempty(delay)
    delay = 0.01;
end

% connect to a dotsEnsembleServer
ensemble = dotsClientEnsemble();
if ~ensemble.isConnected
    disp('Can not connect to dotsEnsembleServer')
    data = [];
    return;
end

% create a no-op call to execute on the server side
callName = 'no-op';
ensemble.addCall({@eval, '%do nothing'}, callName);

% allocate space for lots of transaction data
dataTemplate = dotsEnsembleUtilities.getTransactionTemplate();
weakData = repmat(dataTemplate, 1, iterations);
strongData = repmat(dataTemplate, 1, iterations);

% execute lots of weakly synchronized transactions with the server
ensemble.isSynchronized = false;
for ii = [1 1:iterations]
    ensemble.callByName(callName);
    weakData(ii) = ensemble.txnData;
    pause(delay);
end

% execute lots of strongly synchronized transactions with the server
ensemble.isSynchronized = true;
for ii = [1 1:iterations]
    ensemble.callByName(callName);
    strongData(ii) = ensemble.txnData;
    pause(delay);
end

if ~showPlot
    return;
end
%%
f = figure( ...
    'NumberTitle', 'off', ...
    'Name', mfilename);

ax = subplot(2,1,1, 'Parent', f);
m = dotsTheMessenger.theObject();
title(ax, sprintf('Weak Synchronization (%s, %s)', ...
    class(ensemble), m.socketClassName));
plotTransactionData(weakData, ax)

ax = subplot(2,1,2, ...
    'Parent', f, ...
    'XLim', [0 iterations+1]);
title(ax, sprintf('Strong Synchronization (%s, %s)', ...
    class(ensemble), m.socketClassName));
plotTransactionData(strongData, ax)


function plotTransactionData(data, ax)
n = numel(data);
set(ax, 'XLim', [0 n+1]);

xAxis = 1:n;
serverAck = [data.startTime] + [data.acknowledgeTime];
serverFinished = ...
    serverAck + [data.serverFinishTime] - [data.serverStartTime];
tZero = [data.startTime];
line(xAxis, [data.startTime] - tZero, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', [0 0 1])
line(xAxis, [data.finishTime] - tZero, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', [0 0 1])
line(xAxis, serverAck - tZero, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', [0 .75 0])

if (data(1).isSynchronized || data(1).isResult)
    line(xAxis, serverFinished - tZero, ...
        'Parent', ax, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', [0.75 0 0])
    legend(ax, 'start', 'finish', 'server ack', 'server finish')
    
else
    legend(ax, 'start', 'finish', 'server ack')
end