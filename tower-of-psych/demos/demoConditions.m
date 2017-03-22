% Demonstrate some key behaviors of the topsConditions class.
%
% @ingroup topsDemos
function demoConditions()

% Create the conditions object
c = topsConditions('demo');

% add a several parameters, each of which may take different values
%   the conditions object can traverse all combinations of parameter values
%   it keeps track of each combination with a "contition" number
parameter = 'textures';
values = {'smooth', 'bumpy', 'wrinkled', 'knitted', 'woodwind'};
c.addParameter(parameter, values);

parameter = 'numbers';
values = {42, pi, 11};
c.addParameter(parameter, values);

parameter = 'shapes';
values = {'square', 'circle', 'triangle', 'pear'};
c.addParameter(parameter, values);

% Create some arbitrary objects that can use the parameter values
%   one gets named after a texture word
%   one gets named after *both* a number and a shape word, using Matlab's
%   subsasign syntax
likesTextures = topsFoundation;
c.addAssignment('textures', likesTextures, '.', 'name');

likesShapesAndNumbers = topsFoundation;
c.addAssignment('numbers', likesShapesAndNumbers, '.', 'name', '{}', {1});
c.addAssignment('shapes', likesShapesAndNumbers, '.', 'name', '{}', {2});

% run though combinations of parameters picking from a coin toss, with
% replacement of conditions.  Proceed for 10 total conditions.
c.setPickingMethod('coin-toss');
c.maxPicks = 10;

% run through some conditions and see the object names change
%   each call to run() sets one new condition
keepGoing = true;
while keepGoing
    c.run();
    disp(likesTextures.name);
    disp(likesShapesAndNumbers.name);
    keepGoing = ~c.isDone;
end

% look at the randomly picked condition numbers
disp(c.previousConditions);

% reset to the condition number 1, for no good reason
c.setCondition(1);