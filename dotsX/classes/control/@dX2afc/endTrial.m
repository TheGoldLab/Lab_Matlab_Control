function [afs_, remain_] = trial(afs_, goodTrialFlag, statelistOutcome)
%endTrial method for class dX2afc: do computations between trials
%   [afs_, remain_] = trial(afs_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% trial method for class afs_
%-%
%-% Arguments:
%-%   afs_             ... array of 2afc objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%-%
%-% Returns:
%-%   afs_             ... updated array of tafc objects
%-%   remain_          ... number of remaining trials (ignored)
%----------Special comments-----------------------------------------------
%
%   See also endTrial dX2afc

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% defaults
[afs_.outcomeVal] = deal(nan);
[afs_.rt1Val]     = deal(nan);
[afs_.rt2Val]     = deal(nan);
remain_           = [];

if goodTrialFlag
    for ii = 1:length(afs_)

        % outcome is {<state1> <val1>; <state2> <val2>; ...}
        % look for state name in statelistOutcome
        if ~isempty(afs_(ii).outcome)
            Lout = ismember(afs_(ii).outcome(:,1), statelistOutcome(:,1));
            if sum(Lout) == 1
                afs_(ii).outcomeVal = afs_(ii).outcome{Lout, 2};
            end
        end

        % rt1
        if ~isempty(afs_(ii).rt1)
            Lout = strcmp(afs_(ii).rt1, statelistOutcome(:,1));
            if sum(Lout) == 1
                if isempty(statelistOutcome{Lout, 6})
                    ind = find(Lout);
                    if ind < size(statelistOutcome, 1)
                        afs_(ii).rt1Val = statelistOutcome{ind+1, 3};
                    else
                        afs_(ii).rt1Val = statelistOutcome{ind, 3};
                    end
                else
                    afs_(ii).rt1Val = statelistOutcome{Lout, 6};
                end
            end
        end

        % rt2
        if ~isempty(afs_(ii).rt2)
            Lout = strcmp(afs_(ii).rt2, statelistOutcome(:,1));
            if sum(Lout) == 1
                if isempty(statelistOutcome{Lout, 6})
                    ind = find(Lout);
                    if ind < size(statelistOutcome, 1)
                        afs_(ii).rt2Val = statelistOutcome{ind+1, 3};
                    else
                        afs_(ii).rt2Val = statelistOutcome{ind, 3};
                    end
                else
                    afs_(ii).rt2Val = statelistOutcome{Lout, 6};
                end
            end
        end
    end
end