function tcs_ = reset(tcs_, force, varargin)
%reset method for class dXtc: return to virgin state
%   tcs_ = reset(tcs_, force_reset, varargin)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Resets dXtc for fresh and clean, clean trials and indices.
%-%
%-% When e.g. task properties change, do a non-forced reset--double check
%-% whether a reset is needed.  Other cases may call for a forced reset.
%-%
%-% e.g. dXtask/reset may pass in a working copy of that dXtask instance.
%----------Special comments-----------------------------------------------
%
%   See also reset dXtc

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% Get the task associated with this dXtc
if nargin < 3 || ~isa(varargin{1}, 'dXtask')

    global ROOT_STRUCT

    % a name's as good as an index to a task helper.v
    taskCopy = rGetTaskByName(ROOT_STRUCT.groups.name);

    % get real
    if isempty(taskCopy)
        return
    end
else

    % this working copy is more current than the copy in ROOT_STRUCT
    taskCopy = struct(varargin{1});
end

% Listen baby, are you sure you wanna recompute the tuning curve and indices?
%   Well, only if...
%   ... Hell-Yes-Baby,
%   ... new number of indices blocks,
%   ... index exceeds indices, or
%   ... new indices order.

if ~(force ...
        || taskCopy.blockReps ~= tcs_(1).indicesBlocks ...
        || tcs_(1).index > size(tcs_(1).indices, 2) ...
        || any(strcmp([taskCopy.trialOrder, tcs_(1).indicesOrder], ...
        {'randomblock', 'blockrandom'})))

    % Banana split.
    return
end

% Actually do it to it: recompute a tc over all dXtc instances given
num_vars = length(tcs_);

% defaults for starting over...
[tcs_.previousValue]= deal(nan);
[tcs_.lastOutcome]  = deal(nan);
[tcs_.outcomeRun]   = deal(0);
[tcs_.index]        = deal(1);

% define num_vars-dimensional tuning space
tcvals = {tcs_.values};
if num_vars > 1
    grids      = cell(1, num_vars);
    [grids{:}] = ndgrid(tcvals{:});
else
    % avoid squared tuning space when
    %   only one tuning dimension
    grids = tcvals;
end

% generate tuning curve such that
%   each point in tuning space gets one row
%   this accounts for one 'block' of trials
tcv = zeros(size(grids{1}(:), 1), num_vars);
for tci = 1:num_vars
    tcv(:,tci) = grids{tci}(:);
end
[tcs_.tc] = deal(tcv);

% make array of indices into tuning curve
indices = repmat(1:size(tcv, 1), 1, taskCopy.blockReps);
if strcmp(taskCopy.trialOrder, 'random')
    indices = indices(randperm(length(indices)));
    [tcs_.indicesOrder] = deal('random');
else
    [tcs_.indicesOrder] = deal('block');
end
[tcs_.indices] = deal(indices);
[tcs_.indicesBlocks] = deal(taskCopy.blockReps);

% get the first value from tuning curve
valDumb = num2cell(tcv(indices(1), :));
[tcs_.value] = deal(valDumb{:});