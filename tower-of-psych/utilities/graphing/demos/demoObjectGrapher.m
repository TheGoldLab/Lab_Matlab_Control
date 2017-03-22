% Try graphing the references among objects in a workspace.
%
% @ingroup topsDemos
function demoObjectGrapher()

% Create some objects that refer to each other, from the "spots" demo task.
[tree, list] = configureSpotsTask();

% Create the grapher object and configure it to look nice.
og = ObjectGrapher;
og.dataGrapher.listedEdgeNames = true;
og.dataGrapher.floatingEdgeNames = false;
og.dataGrapher.graphVisAlgorithm = 'dot';

% Tell the grapher object from which object to start looking for object
% references.
og.addSeedObject(list);

% Parse the object references and generate the object reference graph
og.traceLinksForEdges;
og.writeDotFile;
og.generateGraph;