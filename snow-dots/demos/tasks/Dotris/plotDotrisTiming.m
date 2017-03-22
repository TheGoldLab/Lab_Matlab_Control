%% find times for different events in dotris:
%   - window open and close
%   - new pieces
%   - gamepad or keyboard presses
%   - dropped graphics frames
%   - transaction lifetimes
theLog = topsDataLog.theDataLog;

% the topsTreeNode named "dotris" reported window open and close
gameStart = theLog.getAllItemsFromGroupAsStruct('dotris:start');
gameEnd = theLog.getAllItemsFromGroupAsStruct('dotris:end');
times.drawingWindow = [gameStart.mnemonic, gameEnd.mnemonic];

% the topsStateMachine named "dotris" reported new pieces
newPiece = theLog.getAllItemsFromGroupAsStruct('dotris.launch:enter');
times.newPiece = [newPiece.mnemonic];

% HID gamepad or HID keyboard logged all its data
if theLog.containsGroup('dotsReadableHIDGamepad')
    gamepadData = theLog.getAllItemsFromGroupAsStruct( ...
        'dotsReadableHIDGamepad');
    times.gamepad = gamepadData.item(:,3);
    
elseif theLog.containsGroup('dotsReadableHIDKeyboard')
    keyboardData = theLog.getAllItemsFromGroupAsStruct( ...
        'dotsReadableHIDKeyboard');
    times.keyboard = keyboardData.item(:,3);
end

% dotsTheDrawablesManager kept track of
%   - dropped frames
dm = dotsTheDrawablesManager.theObject;
if dm.droppedFrameList.length > 0
    drops = dm.droppedFrameList.getAllItemsFromGroupAsStruct('dotris');
    times.frameDrops = [drops.mnemonic];
end
%   - transactions
if dm.transactions.length > 0
    txnCell = dm.transactions.values;
    txns = [txnCell{:}];
    times.transactionOpen = [txns.startTime];
    times.transactionClose = [txns.finishTime];
end

%% plot all the times found above
f = figure(66);
clf(f);
set(f, ...
    'MenuBar', 'none', ...
    'ToolBar', 'figure', ...
    'NumberTitle', 'off', ...
    'Name', 'dotris timing');

% show timing like a raster
timeNames = fieldnames(times);
nNames = length(timeNames);
ax = axes( ...
    'Parent', f, ...
    'YLim', [0 nNames + 1], ...
    'YTick', 1:nNames, ...
    'YTickLabel', timeNames, ...
    'YDir', 'reverse');
clockName = summarizeValue(theLog.clockFunction);
xlabel(ax, sprintf('time from %s', clockName));

cMap = lines(nNames);
for ii = 1:nNames
    t = times.(timeNames{ii});
    row = ii*ones(size(t));
    line(t, row, ...
        'Parent', ax, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', cMap(ii,:))
end