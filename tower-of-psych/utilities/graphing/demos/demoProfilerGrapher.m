% Try graphing the output of the Matlab profiler.
%
% @ingroup topsDemos
function demoProfilerGrapher()

% Create the grapher object.
%   generate profiler data for built-in polnomial fitting
pg = ProfilerGrapher();
pg.toDo = '[p,S,mu] = polyfit(rand(1,10),rand(1,10),3);';

% Generate the profiler data and graph it!
pg.run();
pg.writeDotFile();
pg.generateGraph();