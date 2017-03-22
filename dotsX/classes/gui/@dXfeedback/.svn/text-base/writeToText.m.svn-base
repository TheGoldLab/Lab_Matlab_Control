function [fb_, num_showing] = writeToText(fb_, dXp, num_showing, taskName, mins)
%For a given task name, write dXfeedback text into dXtext instances
%   [fb_, num_showing] = writeToText(fb_, num_showing)
%
%   fb_ is one instanves of dXfeedback which is passed in and passed back.
%
%   dXp is a struct copy of the current dXparadigm which endTrial already
%   rGot.
%
%   num_showing is the number of fedback texts being used for feedback
%   about the current trial and the total of all trials.  Passed in and
%   passed back to accomodate successive calls.
%
%   taskName is the name of the task for which to show feedback, or the
%   string 'total', which means show feedback for the whole paradigm.
%
%   A private function of dXfeedback.

% Copyright 2006 Benjamin Heasly, University of Pennsylvania

% need to access info from current dXtask, or from dXparadigm if
% the task name is 'total', indicating the sum across all tasks in
% the paradigm.
if strcmp(taskName, 'total')
    t = dXp;
else
    t = rGetTaskByName(taskName);
end

% all possible feedback text for the current task (or total)
if t.feedbackSelect.showPctGood
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('%% complete: %1.0f%%', 100*t.goodTrials/(eps+t.totalTrials)));
end
if t.feedbackSelect.showNumGood
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('# complete: %d', t.goodTrials));
end
if t.feedbackSelect.showGoodRate
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('complete rate: %1.1f/min', t.goodTrials/(eps+mins)));
end
if t.feedbackSelect.showPctCorrect
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('%% correct: %1.0f%%', 100*t.correctTrials/(eps+t.goodTrials)));
end
if t.feedbackSelect.showNumCorrect
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('# correct: %d', t.correctTrials));
end
if t.feedbackSelect.showCorrectRate
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('correct rate: %1.1f/min', t.correctTrials/(eps+mins)));
end
if t.feedbackSelect.showTrialCount
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        sprintf('total trials: %d', t.totalTrials));
end
if t.feedbackSelect.showMoreFeedback
    num_showing = num_showing + 1;
    rSet('dXtext', fb_.dXtextInstances(num_showing), 'string', ...
        t.moreFeedback);
end