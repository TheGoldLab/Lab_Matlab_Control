function biasSetDirections(taskName)
% get 2 direction values from two dXtc objects and set the dirDomain
% property of the current dXdots object.
%
% taskName is the name of the current task (20C or 180C)

% only operate on the real test task (20C and 180C)
if any(strcmp(taskName, {'BiasLever_20C', 'BiasLever_180C'}))

    % dXtc #1 is the test direction
    testDir = rGet('dXtc', 1, 'value');

    % dXtc#2 is the subthreshold, biasing direction
    biasDir = rGet('dXtc', 2, 'value');

    % dXtc#3 is the nominal coherence
    %   gives the number of dots moving in the test direction
    testCoh = rGet('dXtc', 3, 'value');

    % get the subthreshold dot coherence
    biasCoh = rGet('dXdots', 1, 'userData');

    % pass new coherence and direction info to dXdots
    %   set direction as a hint to dXlr
    rSet('dXdots', 1, ...
        'direction',    testDir, ...
        'dirDomain',    [testDir, biasDir], ...
        'dirCDF',       cumsum([testCoh, biasCoh]), ...
        'coherence',    sum([testCoh, biasCoh]));
end