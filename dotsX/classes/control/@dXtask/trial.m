function [ta_, good_trial, correct_trial, outcome] = trial(ta_, debug)
% function [ta_, good_trial, outcome] = trial(ta_)
%
% Arguments:
%   ta_     ... dXtask object
%   debug   ... flag for debugging loop: false or figure handle
%
% Returns:
%   ta_             ... dXtask object
%   good_trial      ... boolean, was the trial completed acceptably?
%   correct_trial   ... boolean, did subject get the right answer?
%   outcome         ... cell array of timing for states entered during trial

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania
global ROOT_STRUCT

% clear the list of errors from the last trial
ROOT_STRUCT.error = {};

% ask paradigm if FIRA is happening
if isfield(ROOT_STRUCT, 'dXparadigm') ...
        && get(ROOT_STRUCT.dXparadigm, 'saveToFIRA')

    % allocate/increment before executing a trial so that FIRA events can
    % be saved during the course of the trial
    buildFIRA_addTrial('add');

    doFIRA = true;
else
    doFIRA = false;
end

% Activate objects/methods for this group, if needed
if ~strcmp(ROOT_STRUCT.groups.name, ta_.name)
    rGroup(ta_.name);
end

% enact an actual trial based on the state objects in this group
%   copy this local task instance to the global task instance to
%   give task access to methods called in loop
ROOT_STRUCT.dXtask(rTaskIndex(ta_.name)) = ta_;
if debug

    % use slower but more informative loop
    outcome = debugLoop(ROOT_STRUCT.dXstate, ta_.timeout, debug);
else

    % use fast loop
    outcome = loop(ROOT_STRUCT.dXstate, ta_.timeout);
end
% copy the global task instance back to this local instance
%   in case loop methods made changes to it
ta_ = ROOT_STRUCT.dXtask(rTaskIndex(ta_.name));

% (possibly) blank the screen
if ta_.blankFlag
    rGraphicsBlank;
end

% update trial count
ta_.totalTrials = ta_.totalTrials + 1;

% get wrt time
if ~isempty(ta_.wrtState)
    wrti = find(strcmp(ta_.wrtState, outcome(:,1)), 1, 'first');
    if ~isempty(wrti) == 1
        % if found, first try "flip" time, otherwise just state time
        if ~isempty(outcome{wrti, 4})
            outcome{1, 3} = outcome{wrti, 4}; % flip time
        elseif ~isempty(outcome{wrti, 3})
            outcome{1, 3} = outcome{wrti, 3}; % time after feval
        elseif ~isempty(outcome{wrti, 2})
            outcome{1, 3} = outcome{wrti, 2}; % time of entry into state
        end
    end
end

% check for "good trial" using anyStates, allStates and noStates
if (isempty(ta_.anyStates) || ~isempty(intersect(ta_.anyStates, outcome(:,1)))) && ...
        (isempty(ta_.allStates) || isempty(setdiff(ta_.allStates, outcome(:,1)))) && ...
        (isempty(ta_.noStates)  || isempty(intersect(ta_.noStates, outcome(:,1))))

    % good trial
    ta_.goodTrials = ta_.goodTrials + 1;
    good_trial = true;

else
    % not good trial
    good_trial = false;
end

% For now, define a correct as a good trial
%   that also entered the 'correct' state.
if good_trial && any(strcmp(outcome(:,1), 'correct'));
    ta_.correctTrials = ta_.correctTrials + 1;
    correct_trial = true;
else
    correct_trial = false;
end

% Make times wrt to wrt and in ms
% Remember that the columns of outcome_ are:
%   1 .. name (not changed)
%   2 .. time just before feval (changed)
%   3 .. time just after feval (changed)
%   4 .. time after first draw (changed)
%   5 .. time after query return
%           (changed below because already wrt start_time)
%   6 .. list of times with skipped frames
for i = 2:size(outcome, 1)
    for j = 2:4
        if ~isempty(outcome{i, j})
            outcome{i, j} = round((outcome{i, j} - outcome{1, 3}) * 1000);
        end
    end
end

% query returns are wrt triel start time, not wrtState time
%   add the offset
start_wrt_offset = outcome{1,3} - outcome{1,2};
for i = 2:size(outcome, 1)
    if ~isempty(outcome{i, 5})
        outcome{i, 5} = round((outcome{i, 5} - start_wrt_offset)*1000);
    end
end

% save the outcome in the ta_ struct
ta_.outcome = outcome;
disp(outcome(2:end,:))

% (possibly) restore all objects
if ta_.restoreFlag
    rGroup;
end

% save trial data to FIRA
%   -a standard set of ecodes
%   -any state timestamps specified in dXtask.statesToFIRA
%   -delegate to any objects in dXtask.saveToFIRA with saveToFIRA()
if doFIRA

    % record any errors this trial
    isErr = ~isempty(ROOT_STRUCT.error);
    buildFIRA_addTrial('errors', {ROOT_STRUCT.error});

    % save a standard set of ecodes with operational data
    taski = get(ROOT_STRUCT.dXparadigm, 'taski');
    vals  = [isErr,         ta_.goodTrials, outcome{1,2},   GetSecs,     outcome{1,3},  good_trial,     taski];
    names = {'trial_error', 'trial_num',    'trial_begin',  'trial_end', 'trial_wrt',   'good_trial',  'task_index'};
    types = {'id',          'value',        'time',         'time',      'time',        'id',          'id'};

    % add timestamp ecodes for any states listed in dXtask.statesToFIRA
    for ii = 1:size(ta_.statesToFIRA,1)
        si = find(strcmp(ta_.statesToFIRA{ii, 1}, outcome(:,1)), 1, 'first');
        if isempty(si) || isempty(outcome{si, ta_.statesToFIRA{ii, 2}+1})
            vals = cat(2, vals, nan);
        else
            vals = cat(2, vals, outcome{si, ta_.statesToFIRA{ii, 2}+1});
        end
        names = cat(2, names, ta_.statesToFIRA{ii, 1});
        types = cat(2, types, 'time');
    end

    % save arbitrary pointers to FIRA
    for ii = 1:size(ta_.ptrsToFIRA, 1)
        val = get(ROOT_STRUCT.(ta_.ptrsToFIRA{ii,2})(ta_.ptrsToFIRA{ii,3}), ...
            ta_.ptrsToFIRA{ii,4});

        % ecode value must be a scalar
        if ischar(val)
            val = sscanf(val, '%f', 1);
        end
        if isempty(val)
            vals = cat(2, vals, nan);
        else
            vals = cat(2, vals, val);
        end
        names = cat(2, names, ta_.ptrsToFIRA{ii, 1});
        types = cat(2, types, 'value');
    end
    buildFIRA_addTrial('ecodes', {vals, names, types});

    % call saveToFIRA methods for any objects listed in dXtask.saveToFIRA
    for ii = 1:size(ta_.saveToFIRA, 1)
        if isempty(ta_.saveToFIRA{ii, 2})
            saveToFIRA(ROOT_STRUCT.(ta_.saveToFIRA{ii,1}));
        else
            saveToFIRA(ROOT_STRUCT.(ta_.saveToFIRA{ii,1})(ta_.saveToFIRA{ii,2}));
        end
    end
end

% generate any on-the-fly feedback after each trial
%   this may depend on FIRA, which is updated above
if ~isempty(ta_.moreFeedbackFunction)
    ta_.moreFeedback = feval(ta_.moreFeedbackFunction, struct(ta_));
end