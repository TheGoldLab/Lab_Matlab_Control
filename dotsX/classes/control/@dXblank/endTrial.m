function bk_ = trial(bk_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXblank: do computations between trials
%   bk_ = trial(bk_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% endTrial method for class dXblank. Called automatically after trials
%-% 
%-% Arguments:
%-%   bk_              ... array of dXblank objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXblank

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% does nothing
