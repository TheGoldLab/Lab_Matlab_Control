function lrs_ = endTrial(lrs_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXlr: do computations between trials
%   lrs_ = trial(lrs_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% trial method for class dXlr (left/right). Called
%-% automatically at the end of a statelist/loop (trial)
%-% 
%-% Arguments:
%-%   lrs_             ... array of dXlr objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXlr

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% does nothing
