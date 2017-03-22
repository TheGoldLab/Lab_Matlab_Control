function fc_ = endTrial(fc_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXfunctionCaller: do computations between trials
%   fc_ = endTrial(fc_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% end of trial method for class dXfunctionCaller.
%-%
%-% does nothing by default, but can optionally trigger its call method,
%-% allowing arbitrary function calls between trials.
%-%
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXfunctionCaller

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% do some logical indexing instead of looping over instances
fBook = struct(fc_);
doIt = logical([fBook.doEndTrial]);
if any(doIt)
    fc_(doIt) = call(fc_(doIt));
end