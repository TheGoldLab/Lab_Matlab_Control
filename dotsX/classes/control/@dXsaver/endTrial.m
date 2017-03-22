function sas_ = trial(sas_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXsaver: do computations between trials
%   sas_ = trial(sas_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% trial method for class saver. Called
%-% automatically at the end of a statelist/loop (trial)
%-% 
%-% Arguments:
%-%   sas_             ... array of saver objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXsaver

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% does nothing
