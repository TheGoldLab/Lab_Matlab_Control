function ta_ = reset(ta_, force_reset)
%reset method for class dXtask: return to virgin state
%   ta_ = reset(ta_, force_reset)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Reset the trials for a task.  Probably delegate to 'control' helper(s).
%-%
%-% In:
%-%   ta_         ... an instance of dXtask
%-%   force_reset ... control helpers may need 'guidance' in this matter
%-%
%-% Out:
%-%   ta_ ... the updated instance of dXtask
%----------Special comments-----------------------------------------------
%
%   See also reset dXtask

% 2006 by Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT

% only call reset on the helpers for THIS task
rGroup(ta_.name);

% let 'control' helpers like dXtc reset themselves
if isfield(ROOT_STRUCT.methods, 'control') ...
        && ~isempty(ROOT_STRUCT.methods.control)

    if nargin < 2
        force_reset = false;
    end
    
    % Reset, but fear The Loop
    %   Pass in a copy of task, with most recent property values, which
    %   might not have returned yet from dXtask/set and therefore wouldn't
    %   be 'rGet'able from within control/reset
    if size(ROOT_STRUCT.methods.control, 2) == 1
        ROOT_STRUCT.(ROOT_STRUCT.methods.control{1}) = ...
            reset(ROOT_STRUCT.(ROOT_STRUCT.methods.control{1}), force_reset, ta_);
    else
        for ci = 1:size(ROOT_STRUCT.methods.control, 2)
            ROOT_STRUCT.(ROOT_STRUCT.methods.control{ci}) = ...
                reset(ROOT_STRUCT.(ROOT_STRUCT.methods.control{ci}), force_reset, ta_);
        end
    end
end

% The moment we forget these lessons,
%   we shall be doomed to repeat them.
ta_.isAvailable   = true;
ta_.totalTrials   = 0;
ta_.goodTrials    = 0;
ta_.correctTrials = 0;
ta_.outcome       = {};