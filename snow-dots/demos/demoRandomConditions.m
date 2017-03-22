% Use topsConditions to traverse random stimulus conditions.
%
% @ingroup dotsDemos
function demoRandomConditions()

% create a stimulus object, a random dots kinetogram
stimulus = dotsDrawableDotKinetogram();
stimulus.y = -3;

% create a label for the stimulus
label = dotsDrawableText();
label.string = 'matching color';
label.y = 3;

% aggregate the objects into one ensemble
drawables = topsEnsemble('drawables');
drawables.addObject(stimulus);
drawables.addObject(label);

% automate the task of animation with named method calls
drawables.automateObjectMethod('draw', @draw);
drawables.addCall({@nextFrame, dotsTheScreen.theObject()}, 'flip');
drawables.addCall({@disp, 'cheese'}, 'cheese');

%% create sets of values for several simulus properties
conditions = topsConditions;
conditions.addParameter('color', {[255 0 0], [0 128 0] [255 255 255]});
conditions.addParameter('coherence', {0, 100});
conditions.addParameter('angle', {0, 180});

%% assign the parameters to properties of the stimulus and label
%   each parameter can have multple assignments
%   the parameter assignment target don't have to have the same name
conditions.addAssignment('color', stimulus, '.', 'colors');
conditions.addAssignment('color', label, '.', 'color');
conditions.addAssignment('coherence', stimulus, '.', 'coherence');
conditions.addAssignment('angle', stimulus, '.', 'direction');

% traverse parameter combinations bu shuffling them
% after setting new combinations, show off the graphics
conditions.setPickingMethod('shuffled');
conditions.name = 'pick conditions';

%% use a "tree node" to organize a mini-experiment
%   most steps below build up a "recipe" for the experiment
%   the final step executes the experiment with run()
runTree = topsTreeNode();
runTree.name = 'mini experiment:';

% first of all, open a drawing window
runTree.startFevalable = {@open, dotsTheScreen.theObject()};

% then try to run() the conditions object and animator infinity times...
% ...but the conditions object will tell its "caller", the runTree, to stop
% running after traversing the finite number of conditions.
runTree.addChild(conditions);
runTree.addChild(drawables);
runTree.iterations = inf;

% finally, close the drawing window
runTree.finishFevalable = {@close, dotsTheScreen.theObject()};

%% Run the mini-experiment
runTree.run;

%% Overview of the mini-experiment
%runTree.gui;