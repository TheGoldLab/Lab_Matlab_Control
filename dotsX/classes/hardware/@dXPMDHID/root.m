function p_ = root(p_, varargin)
% p_ = root(p_, varargin)
%
% Overloaded root method for class dXPMDHID:
%   set up or clean up system resources for a dXPMDHID object
%
% Updated class instances are always returned.
%
% Usage:
%   root(a, 'clear')  cleans up
%   root(a, varargin) optional list of args to send to set
%----------Special comments-----------------------------------------------
%-%
%-% Sets up and cleans up a 'dXPMDHID' object, typically
%-%   called by rAdd, rClear or rDone.
%----------Special comments-----------------------------------------------
%

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

p_.available = exist('HIDx');
if ~p_.available
    p_.active = false;
    return
end

% root(g, 'clear') means clean up
%   otherwise initialize
if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))
    %%
    % INITIALIZE
    %   PMD needs to be customizable.
    %   so do HIDx setup after setting arguments
    p_.active = false;
    varargin = cat(2, {'active', p_.available}, varargin);
    p_ = set(p_, varargin{:});

else
    %%
    % CLEAN UP

    if ~isnan(p_.HIDIndex) && HIDx('status')

        % stop scanning
        if ~isempty(p_.stopID) && ~isempty(p_.stopReport) ...
                && isa(p_.stopReport, 'uint8')
            HIDx('setReport', p_.HIDIndex, p_.stopID, p_.stopReport);
        end
        p_.HIDIndex = HIDx('remove', p_.HIDIndex);
        p_.active = false;
    end
end