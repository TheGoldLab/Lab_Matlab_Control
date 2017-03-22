function v_ = draw(v_)
%draw method for class dXvideo: prepare graphics for display
%   v_ = draw(v_)
%
%   All DotsX graphics classes have draw methods.  These prepare class
%   instances for displaying graphics upon the next dXscreen 'flip'.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% draw each sound-synced video frame to a Screen window
%----------Special comments-----------------------------------------------
%
%   See also draw dXdots

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

vis = [v_.visible];
for ii = find(vis)

    % release the last frame
    if any(v_(ii).currentTexture == Screen('Windows'))
        Screen('Close', v_(ii).currentTexture);
    end

    % get the current frame
    v_(ii).currentTexture = ...
        Screen('GetMovieImage', v_(ii).windowNumber, v_(ii).moviePtr);

    % get the current frame
    if v_(ii).currentTexture > 0
        Screen('DrawTexture', v_(ii).windowNumber, v_(ii).currentTexture);
    end
end