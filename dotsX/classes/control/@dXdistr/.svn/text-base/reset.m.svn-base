function d_ = reset(d_, force, varargin)
%reset method for class dXdistr: return to virgin state
%   d_ = reset(d_, force_reset, varargin)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Resets dXdistr for fresh and clean, clean trials and indices.
%-%
%-% When e.g. task properties change, do a non-forced reset--double check
%-% whether a reset is needed.  Other cases may call for a forced reset.
%-%
%-% e.g. dXtask/reset may pass in a working copy of that dXtask instance.
%----------Special comments-----------------------------------------------
%
%   See also reset dXdistr

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% defaults for starting over...
[d_.numTrials]= deal(0);
[d_.subBlockTrial]= deal(0);
[d_.override]= deal([]);

% restart metadistributions
m = d_.metaD;
[m.count] = deal(1);
d_.metaD = m;

% pick two new values (value and nextValue)
%   don't double-trigger the "subBlockMethod", 
%   which happens when subBlockTrial = 0.
d_ = endTrial(d_, false, {'resetMethod'});
d_.subBlockTrial = nan;
d_ = endTrial(d_, false, {'resetMethod'});
d_.subBlockTrial = 0;