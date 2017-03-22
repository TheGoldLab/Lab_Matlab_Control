function cohTimeLearn_repeatCohQuest(varargin)
%Tell dXparadigm to repeat the task called taskCohTimeLearn_cohQuest
%
%   cohTimeLearn_repeatCohQuest(varargin)
%
%   Get the task list from the current dXparadigm, and find in it the task
%   named CohTimeLearn_cohQuest.  Set the corresponding task proportions to
%   be 1, so that CohTimeLearn_cohQuest will run again.
%
%   cohTimeLearn_repeatCohQuest should be called by the current task,
%   which should be named CohTimeLearn_timeQuest.  The idea is to run
%   CohTimeLearn_cohQuest, to get a coherence threshold measurement, then
%   run CohTimeLearn_timeQuest, to get a related viewing time measurement,
%   and then rerun the CohTimeLearn_cohQuest to make sure that the
%   coherence threshold didn't really change.
%
%   varargin is ignored.

% Copyright 2008 by Benjamin Heasly, University of Pennsylvania

% the task to repeat
taskn = 'taskCohTimeLearn_cohQuest';

tl = rGet('dXparadigm', 1, 'taskList');
tp = rGet('dXparadigm', 1, 'taskProportions');

% find the task of interest in the paradigm's task list
taski = 0;
for ii = 1:length(tl)

    % find the task names among other elements of the task list
    if ischar(tl{ii})
        taski = taski + 1;

        % is this the task of interest?
        if strcmp(taskn, tl{ii});

            disp(sprintf('repeating %s (taski=%d)', taskn, taski))

            % set the task proportion for the task of interest
            tp(taski) = 1;
            rSet('dXparadigm', 1, 'taskProportions', tp);
            break
        end
    end
end