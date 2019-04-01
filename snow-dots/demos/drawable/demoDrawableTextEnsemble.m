% Demonstrate drawing strings of text, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableTextEnsemble(remoteArgs)

if nargin < 1 || isempty(remoteArgs)
    % These need to be set on the remote machine
    clientIP = '192.168.1.1';
    clientPort = 40000;
    serverIP = '192.168.1.2';
    serverPort = 40001;
    % Package arguments in a cell array
    remoteArgs = {true, clientIP, clientPort, serverIP, serverPort};
end

% Make the screen object using dotsEnsembleUtilties, which handles
% local/remote details
screen = dotsTheScreen.theObject();
screen.displayIndex = 1;
screenEnsemble = dotsEnsembleUtilities.makeEnsemble('screen', remoteArgs{:});
screenEnsemble.addObject(screen);

% Get a drawing window
screenEnsemble.callObjectMethod(@open);

% Create two text objects
tx1 = dotsDrawableText();
tx1.y = 5;
tx1.string = 'Juniper juice';
tx1.color = [0 128 64];

tx2 = dotsDrawableText();
tx2.string = 'hello';
tx2.color = [250 25 250];

% Make a drawable ensemble
drawableEnsemble = dotsEnsembleUtilities.makeEnsemble('texts', remoteArgs{:});

% Add the objects
ind1 = drawableEnsemble.addObject(tx1);
ind2 = drawableEnsemble.addObject(tx2);

% Draw them once.
drawableEnsemble.callObjectMethod(@mayDrawNow);
screenEnsemble.callObjectMethod(@nextFrame);

% Wait
pause(1);

% Change some properties
drawableEnsemble.setObjectProperty('string', 'Guava goop', ind1);
drawableEnsemble.setObjectProperty('string', 'Goodbye', ind2);

% Draw again
drawableEnsemble.callObjectMethod(@mayDrawNow);
screenEnsemble.callObjectMethod(@nextFrame);

% Wait again
pause(1);

% close the OpenGL drawing window
screenEnsemble.callObjectMethod(@close);
