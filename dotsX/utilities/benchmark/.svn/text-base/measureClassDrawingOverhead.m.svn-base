function fig_ = measureDotDensityPerformance
% DotsX drawing time grows with the number of objects being drawn.  It also
% grows with the number of different class types being drawn becuase class
% types are iterated in a loop.

% How do these growth factors compare?  Compare draw times for, N objects
% of the same type vs N objects of mixed types.

% Copyright 2007 Benjamin Heasly, University if Pennsylvania
clear all
clear Screen
global ROOT_STRUCT

disp('Measuring overhead in calling draw() for multiple classes')

try
    reps = 100;
    num_obj = 50;
    xs = num2cell(linspace(-8, 8, num_obj));

    rInit('local')
    wn = rWinPtr;
    fr = rGet('dXscreen', 1, 'frameRate');

    % dXtarget and dXtargets are probably the classes that are most alike
    rAdd('dXtarget', num_obj, 'y', 2, 'x', xs);
    rAdd('dXtargets', num_obj, 'y', -2, 'x', xs);

    % draw all dXtarget objects
    rSet('dXtarget', 1:num_obj, 'visible', true);
    rSet('dXtargets', 1:num_obj, 'visible', false);
    preDrawsT = nan*ones(1, reps);
    preFlipsT = nan*ones(1, reps);
    postFlipsT = nan*ones(1, reps);
    for rr = 1:reps
        preDrawsT(rr) = GetSecs;

        % rRemoteClient and dXstate/loop use a similar loop
        for dr = {'dXtarget'}
            ROOT_STRUCT.(dr{1}) = draw(ROOT_STRUCT.(dr{1}));
        end

        preFlipsT(rr) = GetSecs;
        %Screen('DrawingFinished', wn);
        Screen('Flip', wn);
        postFlipsT(rr) = GetSecs;
    end

    % draw all dXtargets objects
    rSet('dXtarget', 1:num_obj, 'visible', false);
    rSet('dXtargets', 1:num_obj, 'visible', true);
    preDrawsTs = nan*ones(1, reps);
    preFlipsTs = nan*ones(1, reps);
    postFlipsTs = nan*ones(1, reps);
    for rr = 1:reps
        preDrawsTs(rr) = GetSecs;

        % rRemoteClient and dXstate/loop use a similar loop
        for dr = {'dXtargets'}
            ROOT_STRUCT.(dr{1}) = draw(ROOT_STRUCT.(dr{1}));
        end

        preFlipsTs(rr) = GetSecs;
        %Screen('DrawingFinished', wn);
        Screen('Flip', wn);
        postFlipsTs(rr) = GetSecs;
    end

    % draw half the dXtarget and half the dXtargets objects
    rSet('dXtarget', 1:2:num_obj, 'visible', false);
    rSet('dXtargets', 2:2:num_obj, 'visible', false);
    rSet('dXtarget', 2:2:num_obj, 'visible', true);
    rSet('dXtargets', 1:2:num_obj, 'visible', true);
    preDrawsB = nan*ones(1, reps);
    preFlipsB = nan*ones(1, reps);
    postFlipsB = nan*ones(1, reps);
    for rr = 1:reps
        preDrawsB(rr) = GetSecs;

        % rRemoteClient and dXstate/loop use a similar loop
        for dr = {'dXtarget', 'dXtargets'}
            ROOT_STRUCT.(dr{1}) = draw(ROOT_STRUCT.(dr{1}));
        end

        preFlipsB(rr) = GetSecs;
        %Screen('DrawingFinished', wn);
        Screen('Flip', wn);
        postFlipsB(rr) = GetSecs;
    end
catch
    evalin('base', 'e = lasterror');
    rDone
end
rDone


fig_ = figure(51);
clf(fig_);
set(fig_, 'Name', 'class overhead');
axa = axes;
xlabel(axa, 'repetitions')
ylabel(axa, 'draw time (ms)')
ylim(axa, [0 7])
title(axa, sprintf( ...
    'draw times for %d objects of like and unlike classes', num_obj));

line(1:reps, 1000*(preFlipsT-preDrawsT), ...
    'Color', [1 0 0], 'Parent', axa);
line(1:reps, 1000*(preFlipsTs-preDrawsTs), ...
    'Color', [0 .8 0], 'Parent', axa);
line(1:reps, 1000*(preFlipsB-preDrawsB), ...
    'Color', [0 0 0], 'Parent', axa);

yness = get(axa, 'YTick');
text(reps*.8, yness(end-1), 'dXtarget', 'Color', [1 0 0])
text(reps*.8, yness(end-1)*.9, 'dXtargets', 'Color', [0 .8 0])
text(reps*.8, yness(end-1)*.8, 'half and half', 'Color', [0 0 0])
