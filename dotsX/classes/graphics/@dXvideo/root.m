function v_ = root(v_, varargin)
% v_ = root(v_, varargin)
%
% Overloaded root method for class dXscreen:
%   set up or clean up system resources for a dXscreen object
%
% Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets up and cleans up a 'dXVideo' object.
%----------Special comments-----------------------------------------------

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

if isempty(varargin) || ~(ischar(varargin{1}) && strcmp(varargin{1}, 'clear'))

    % delegate to set method
    v_ = set(v_, varargin{:});

else

    %%
    % CLEAN UP
    % if there is an open window
    if ROOT_STRUCT.screenMode == 1 && ~isnan(v_.moviePtr)

        % release the last frame
        if any(v_.currentTexture == Screen('Windows'))
            Screen('Close', v_.currentTexture);
        end

        % release the whole video
        Screen('CloseMovie', v_.moviePtr);
        v_.moviePtr = nan;
    end
end