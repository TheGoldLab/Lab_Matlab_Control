% Try graphing some arbitrary Matlab data with Graphviz.
%
% @ingroup topsDemos
function demoDataGrapher()

% Create the grapher object.
%   configure it to make a nice-looking graph.
dg = DataGrapher;
dg.listedEdgeNames = true;
dg.floatingEdgeNames = true;

% Make some arbitrary data in the form of node names and edges between
% nodes.
data(1).name = 'a or A';
data(1).edge = 2;
data(2).name = 'b';
data(2).edge = 3;
data(3).name = 'c';
data(3).edge = [1 2];
dg.inputData = data;

% Generate a graph of the arbitrary data.
dg.writeDotFile;
dg.generateGraph;