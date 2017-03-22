function g_ = root(g_, varargin)
% g_ = root(g_, varargin)
%
% Overloaded root method for class dXgameHID:
%   set up or clean up system resources for a dXgameHID object
%
% Updated class instances are always returned.
%
% Usage:
%   root(g, 'clear')  cleans up
%   root(g, varargin) optional list of args to send to set
%----------Special comments-----------------------------------------------
%-%
%-% Sets up and cleans up a 'dXgameHID' object, typically
%-%   called by rAdd, rClear or rDone.
%-%   dXgameHID has no cleanup to do since USB is managed well by OS.
%----------Special comments-----------------------------------------------
%

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

g_.available = exist('HIDx')==3;
if ~g_.available
    g_.active = false;
    return
end

% root(g, 'clear') means clean up
%   otherwise initialize
if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))
    %%
    % INITIALIZE
    %   gamepad needs to be customizable.
    %   so do HIDx setup after setting arguments
    g_.active = false;
    varargin = cat(2, {'active', g_.available}, varargin);
    g_ = set(g_, varargin{:});

else
    %%
    % CLEAN UP
    if ~isnan(g_.HIDIndex) && HIDx('status')
        g_.HIDIndex = HIDx('remove', g_.HIDIndex);
    else
        g_.HIDIndex = nan;
    end
    g_.active = false;
end