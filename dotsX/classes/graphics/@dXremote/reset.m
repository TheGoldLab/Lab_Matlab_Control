function r_ = reset(r_, start_time)
%reset method for class dXremote: return to virgin state
%   r_ = reset(r_, start_time)
%
%   Some DotsX classes can revert to a consistent state, as though just 
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded reset method for class dXremote
%-%
%-% Note: this routine always returns the object
%-% in case it was changed
%----------Special comments-----------------------------------------------
%
%   See also reset dXremote

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

% Send a message to the remote client
%   to synchronize timestamps

msgSend('start_time = GetSecs;');