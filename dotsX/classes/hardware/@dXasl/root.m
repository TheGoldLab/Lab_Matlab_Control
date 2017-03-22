function a_ = root(a_, varargin)
% a_ = root(a_, varargin)
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
%-% Sets up and cleans up a 'dXasl' object, typically
%-%   called by rAdd, rClear or rDone.
%----------Special comments-----------------------------------------------
%

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

if ~a_.available
    return
end

% root(a, 'clear') means clean up
%   otherwise initialize
if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))

    %%
    % INITIALIZE
    % make it active by adding 'active' arg, unless
    %   it's already there
    clear as
    a_.active = -1;
    % activate the asl data stream at load time
    %   but be sure to reset it at runTasks time.

    varargin = cat(2, {'active', true}, varargin);
    
    % call set with args
    a_ = set(a_, varargin{:});
    
    % call reset to update plots
    a_ = reset(a_);

else

    %%
    % CLEAN UP
    % close as mex utility
    if a_.active > 0
        a_.active = as('close');
    end

    % close figure window and forget graphics handles
    if (a_.showPlot)
        if ishghandle(a_.fig)
            close(a_.fig);
        end
        a_.fig = [];
        a_.ax = [];
        a_.plt = [];
    end
end