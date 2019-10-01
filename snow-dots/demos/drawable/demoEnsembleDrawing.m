% Demonstrate object grouping and remote behavior with ensembles.
% @param delay how long to show the demo graphics
% @param isClient whether or not to draw graphics remotely
% @details
% This demo will display a short text greeting inside an ornamented picture
% frame.  It can display the greeting locally, in this Matlab instance, or
% remotely, in another Matlab instance through a network connection.
% @details
% The demo highlights the two key features of ensemble objects.  First,
% ensembles can group together similar objects.  This allows for convenient
% syntax.  In this example, it takes one line to tell a whole ensemble of
% objects to "draw", as opposed to taking several lines to iterate over an
% array of objects, telling each one to draw.
% @details
% Second, ensembles can operate locally or remotely, and the function calls
% look the same either way.  The utility method
% dotsEnsembleUtilities.makeEnsemble() can create either type of ensemble:
% if @a isClient is true, it creates a dotsClientEnsemble object which
% can delegate behaviors to a remote Matlab instance; if @a isClient is
% false it creates a topsEnsemble object which does behaviors here in this
% Matlab instance.
% @details
% The two types of ensemble can "drop in" as replacements for one another,
% so the local vs. remote behavior can change, but the code stays the same.
% @details
% Note that remote behaviors require a little configuration.  See
% dotsTheMessenger and dotsTheMachineConfiguration for more about choosing
% default network addresses.
% @details
% Also, in order to see remote behaviors, an instance of dotsEnsembleServer
% must be running before starting this demo .  See
% dotsEnsembleServer.runNewServer() and the shell script
% launchDotsEnsembleServer, which is in the utilities/ folder.
% @details
% By default, demoEnsembleDrawing() sets @a isClient to true, to attempt to
% do remote behaviors.  If no dotsEnsembleServer is found, it defaults to
% local behaviors.
%
% @ingroup dotsDemos
function demoEnsembleDrawing(delay, isClient)

if nargin < 1
    delay = 2;
end

if nargin < 2
    isClient = true;
end

%% Create a handful of objects to draw
greeting = dotsDrawableText();
greeting.string = 'Yo.';

ornaments = dotsDrawableTargets();
ornaments.xCenter = [0 5 0 -5];
ornaments.yCenter = [5 0 -5 0];
ornaments.colors = [1 1 0];

frame = dotsDrawableLines();
frame.xFrom = [5 5 -5 -5];
frame.xTo = [5 -5 -5 5];
frame.yFrom = [5 -5 -5 5];
frame.yTo = [-5 -5 5 5];

%% aggregate all these drawable objects into a single ensemble
%   the type of ensemle returned depends on isClient
drawables = dotsEnsembleUtilities.makeEnsemble('drawables', isClient);
drawables.addObject(frame);
drawables.addObject(ornaments);
drawables.addObject(greeting);

% tell the drawables ensemble how to open and close a drawing window
drawables.addCall({@dotsTheScreen.openWindow}, 'open');
drawables.addCall({@dotsTheScreen.closeWindow}, 'close');

% tell the drawables ensemble how to draw a frame of graphics
%   the static drawFrame() takes a cell array of objects
isCell = true;
drawables.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

%% Draw the graphics as a batch
%   this code looks the same for local or remote behaviors

% Open an OpenGL window
drawables.callByName('open');

% Let each drawable object draw in the window
drawables.callByName('draw');
pause(delay);

% Clean up
drawables.callByName('close');