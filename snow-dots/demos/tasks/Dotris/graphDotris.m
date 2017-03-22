% Generate graphs about how the dotris game is put together.
clear
clear classes
clc

workingFolder = fullfile('~', 'Desktop', 'datagraph', 'dotris');
[tree, list] = configureDotris;

%% Graph the funciton calls during game configuration
pg = ProfilerGrapher;
pg.dataGrapher.workingPath = workingFolder;
pg.includePaths = {'/Users/ben/Desktop/Labs/Snow_Dots'};
pg.toDo = 'configureDotris;';
pg.runProfiler;
pg.writeDotFile;
pg.generateGraph;

%% Graph the objects and how they refer to each other
og = ObjectGrapher;
og.ignoredClasses = {'dotsFiniteDimension', 'dotsPhenomenon'};
og.dataGrapher.workingPath = workingFolder;
og.addSeedObject(list);
og.traceLinksForEdges;
og.writeDotFile;
og.generateGraph;

%% Graph the states and transitions
sg = StateDiagramGrapher;
sg.dataGrapher.workingPath = workingFolder;
sg.stateMachine = list{'control objects'}{'game machine'};

% what are the outputs from the game logic object?
gameLogic = list{'control objects'}{'game logic'};
sg.addInputHint('may fall', gameLogic.outputTickTimeUp);
sg.addInputHint('may fall', gameLogic.outputTickOK);
sg.addInputHint('ratchet', gameLogic.outputRatchetLanded);
sg.addInputHint('ratchet', gameLogic.outputRatchetOK);
sg.addInputHint('judgement', gameLogic.outputJudgeGameOver);
sg.addInputHint('judgement', gameLogic.outputJudgeOK);

% what are the outputs from the gamepad or keyboard?
readable = list{'input objects'}{'using'};
classGroup = readable.classifications{'dotris'};
classStruct = [classGroup{:}];
sg.addInputHint('may move', {classStruct.output});
sg.addInputHint('may move', readable.unavailableOutput);
sg.addInputHint('may move', {'left', 'right'});

classGroup = readable.classifications{'pause'};
classStruct = [classGroup{:}];
sg.addInputHint('pause', {classStruct.output});

sg.parseStates;
sg.writeDotFile;
sg.generateGraph;