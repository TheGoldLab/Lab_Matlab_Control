function RTDsetVisible(drawables, inds_on, inds_off, datatub, eventTag)
% function RTDsetVisible(ensemble, inds_on, inds_off, datatub, eventTag)
%
% Utility for setting isVisible flag of drawable objects to true/false,
%  then possibly sending a screen flip command
%
% Arguments:
%  drawables    ... ensemble with objects to draw
%  inds_on      ... indices of ensemble objects to set isVisible=true
%  inds_off     ... indices of ensemble objects to set isVisible=false
%  datatub      ... if given, get screen object, draw, and save timing
%  eventTag     ... string used to store timing information in trial struct
%
% Created 5/10/18 by jig

% Turn on
if nargin >= 2 && ~isempty(inds_on)
    drawables.setObjectProperty('isVisible', true, inds_on);
end

% Turn off
if nargin >= 3 && ~isempty(inds_off)
    drawables.setObjectProperty('isVisible', false, inds_off);
end

% Possibly draw now
if nargin >= 4 && ~isempty(datatub)
        
    % Use the screenEmsemble to draw the next frame. This returns a struct
    % with args:
    %   - onsetTime: estimated onset time for this frame, which
    %   might be a time in the future
    %   - onsetFrame: number of frames elapsed between open() and
    %   this frame
    %   - swapTime: estimated time of the last video hardware
    %   refresh (e.g. "vertical blank"), which is alwasy a time in the
    %   past
    %   - isTight: whether this frame and the previous frame were
    %   adjacent (false if a frame was skipped)
    ret = callObjectMethod(drawables, @dotsDrawable.drawFrame, {}, [], true);
    
    % Save timing information in the trial struct, then re-save
    task = datatub{'Control'}{'currentTask'};
    task.nodeData.trialData(task.nodeData.currentTrial).(sprintf('time_%s', eventTag)) = ...
        ret.onsetTime;
end
