function ta_ = root(ta_, varargin)
% ta_ = root(ta_, varargin)
%
% Overloaded root method for class dXtask:
%   set up or clean up system resources for a dXasl object
%
% Updated class instances are always returned.
%
% Usage:
%   root(a, 'clear')  cleans up
%   root(a, varargin) optional list of args to send to set
%----------Special comments-----------------------------------------------
%-%
%-% Sets up and cleans up a 'dXtask' object, typically
%-%   called by rAdd, rClear or rDone.
%----------Special comments-----------------------------------------------
%

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% root(a, 'clear') means clean up
%   otherwise initialize
if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))

    %%
    % INITIALIZE
    % call set with args
    ta_ = set(ta_, varargin{:});
end
