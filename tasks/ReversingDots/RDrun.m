% Script to run reversing dots task
function RDrun

DIPSLAY_INDEX = 0;
USE_REMOTE = false;
UI = 'dotsReadableEyeMouseSimulator';

% Make the top Node
topNode = topsTreeNodeTopNode('dotsReversal');
      
% Use the GUI
topNode.runGUIname = 'eyeGUI';

% Turn off file saving
topNode.filename = [];

% Add the screen and text ensemble
topNode.addDrawables(DIPSLAY_INDEX, USE_REMOTE, false);

% Add the user interface device(s)
topNode.addReadables(UI);

% Get the dots Reveral Task
task = topsTreeNodeTaskReversingDots.getStandardConfiguration('NN', 10);

% Add as child to the maintask. 
topNode.addChild(task);

% Run it!
topNode.run();

