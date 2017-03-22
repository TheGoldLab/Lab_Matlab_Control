function kb_ = root(kb_, varargin)
% kb_ = root(kb_, varargin)
%
% Overloaded root method for class dXasl:
%   set up or clean up system resources for a dXasl object
%
% Updated class instances are always returned.
%
% Usage:
%   root(a, 'clear')  cleans up
%   root(a, varargin) optional list of args to send to set
%----------Special comments-----------------------------------------------
%-%
%-% Sets up and cleans up a 'dXkbHID' object, typically
%-%   called by rAdd, rClear or rDone.
%----------Special comments-----------------------------------------------
%

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

kb_.available = exist('HIDx', 'file');
if ~kb_.available
    return
end

% root(kb_, 'clear') means clean up
%   otherwise initialize
if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))

    %%
    % INITIALIZE
    % make it active by adding to HIDx
    kb_.active = false;
    [kb_.HIDIndex, kb_.HIDDeviceInfo, kb_.HIDElementsInfo] = ...
        HIDx('add', kb_.HIDClass, 1, kb_.HIDCriteria);
    varargin = cat(2, varargin, {'active', ~isnan(kb_.HIDIndex)});

    % call set with args
    kb_ = set(kb_, varargin{:});

else

    %%
    % CLEAN UP
    if ~isnan(kb_.HIDIndex) && HIDx('status')
        kb_.HIDIndex = HIDx('remove', kb_.HIDIndex);
    else
        kb_.HIDIndex = nan;
    end
    kb_.active = false;
end