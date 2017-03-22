function fb_ = trial(fb_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXfb: do computations between trials
%   fb_ = endTrial(fb_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% endTrial method for class dXfeedback.  Shows performance info to
%-% subject using dXtext and updates the experimenter's trialHistrory GUI.
%-%
%-% Arguments:
%-%   fb_              ... one dXfeedback instance
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%-%
%-% Returns:
%-%   fb_              ... updated array of tafc objects
%-%
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXfeedback

% Copyright 2006 by Bemjamin Heasly
%   University of Pennsylvania

% show feedback to subject now?
switch fb_.doEndTrial

    case 'never'

        return

    case 'block'

        taski = rGet('dXparadigm', 1, 'taski');
        t = rGet('dXtask', taski);
        if t.showFeedback && ~t.isAvailable

            % end of a block, so show feedback
            drawnow;
            fb_ = show(fb_, true, false);
        end

    case 'trial'

        taski = rGet('dXparadigm', 1, 'taski');
        t = rGet('dXtask', taski);
        if t.showFeedback

            drawnow;
            fb_ = show(fb_, true, false);
        end
end