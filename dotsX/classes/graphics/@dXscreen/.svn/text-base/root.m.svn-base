function g_ = root(g_, varargin)
% g_ = root(g_, varargin)
%
% Overloaded root method for class dXscreen:
%   set up or clean up system resources for a dXscreen object
%
% Updated class instances are always returned.
%
% Usage:
%   root(a, 'clear')  cleans up
%   root(a, varargin) optional list of args to send to set
%----------Special comments-----------------------------------------------
%-%
%-% Sets up and cleans up a 'dXscreen' object, typically
%-%   called by rAdd, rClear or rDone.
%----------Special comments-----------------------------------------------
%

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% root(g, 'clear') means clean up
%   otherwise initialize
if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))

    %%
    % INITIALIZE
    ROOT_STRUCT.screenMode   = -1;  % -1=not set; 0=debug; 1=Screen; 2=remote
    ROOT_STRUCT.windowNumber = 0;   % arg to Screen

    % call set with args
    g_ = set(g_, 'windowNumber', -1, varargin{:});

    % re-set window number in all objects with draw methods
    %   use root group to prevent double resets
    if ~strcmp(g_.screenMode, 'remote')
        args = {'windowNumber', g_.windowNumber, 'screenRect', g_.screenRect, ...
            'pixelsPerDegree', g_.pixelsPerDegree, 'frameRate', g_.frameRate};
        rGroup('root');
        for cl = ROOT_STRUCT.classes.names
            if any(strcmp(ROOT_STRUCT.classes.(cl{:}).methods, 'draw'))
                if ~isempty(ROOT_STRUCT.classes.(cl{:}).objects)
                    ROOT_STRUCT.classes.(cl{:}).objects = set( ...
                        ROOT_STRUCT.classes.(cl{:}).objects, args{:});
                end
                if ~isempty(ROOT_STRUCT.(cl{:}))
                    ROOT_STRUCT.(cl{:}) = set( ...
                        ROOT_STRUCT.(cl{:}), args{:});
                end
            end
        end
    end

else

    %%
    % CLEAN UP
    % if there is an open window
    if ROOT_STRUCT.screenMode == 1

        % restore an old gamma table?
        if g_.loadGamma8bit || g_.loadGammaBitsPlus
            Screen('LoadNormalizedGammaTable', ...
                g_.windowNumber, g_.gamma8bitOld);
        end

        % close all windows and textures
        Screen('CloseAll');

        % show the cursor
        ShowCursor;

        % re-set priority
        if g_.priority ~= 0
            Priority(0);
        end

        % clear window
        g_.windowNumber          = -1;
        ROOT_STRUCT.windowNumber = -1;
        ROOT_STRUCT.screenMode   = -1;
    end
end
