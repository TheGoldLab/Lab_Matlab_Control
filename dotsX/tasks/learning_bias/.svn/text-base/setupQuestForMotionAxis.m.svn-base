function setupQuestForMotionAxis(taskIndex)
%Reconfigure taskBiasLever_20Q or taskBiasLever_180Q for a new quest run

% benjamin.heasly@gmail.com
%   4 July, 2009 Seattle, WA

% pull out the next motion orientation from task user data.
motionAxes = rGet('dXtask', taskIndex, 'userData');
if length(motionAxes)
    motionAxis = motionAxes(1);
    rSet('dXtask', taskIndex, 'userData', motionAxes(2:end));
else
    disp(sprintf('task %s has no more motion axes to use', ...
        rGet('dXtask', taskIndex, 'name')))
    return
end

% configure the dot direction tuning curve with the new orientation
%   preserve whatever spacing (coarse, fine, whatever) between directions
oldOrients = rGet('dXtc', 1, 'values');
spacing = abs(diff(oldOrients));
newOrients = spacing*[-0.5, .5] + motionAxis;
rSet('dXtc', 1, 'values', newOrients);

% interetation of "left" and "right" depends on motionAxis.
%   in top half of circle, rotate angles up to 90 deg.
%   in bottom half of circle, rotate down to 270 deg.
%   that way, dXlr can compare cosine of a stimulus angle to 0.
if sind(motionAxis) >= 0
    intercept = 90 - motionAxis;
else
    intercept = 270 - motionAxis;
end
rSet('dXlr', 1, 'intercept', intercept*pi/180);

% force reset the task after all these changes to its helpers
%   must be sure to use the active global instance of this task
global ROOT_STRUCT
ROOT_STRUCT.dXtask(taskIndex) = ...
    reset(ROOT_STRUCT.dXtask(taskIndex), true);

% display new labeled motion directions to subject
%	should be able to use this task's graphics objects
isRight = cosd(newOrients+intercept) >= 0;
radius = rGet('dXdots', 1, 'diameter')/2;

xText = 2*radius*cosd(newOrients) + rGet('dXdots', 1, 'x') - 1;
yText = 2*radius*sind(newOrients) + rGet('dXdots', 1, 'y');
rSet('dXtext', 1, 'x', xText(isRight), 'y', yText(isRight));
rSet('dXtext', 2, 'x', xText(~isRight), 'y', yText(~isRight));

xLine = radius*cosd(newOrients) + rGet('dXdots', 1, 'x');
yLine = radius*sind(newOrients) + rGet('dXdots', 1, 'y');
rSet('dXline', 1, 'x2', xLine(isRight), 'y2', yLine(isRight));
rSet('dXline', 2, 'x2', xLine(~isRight), 'y2', yLine(~isRight));

rGraphicsShow('dXdots', 'dXline', 'dXtext');
rGraphicsDraw(100, true);
rGraphicsShow({}, 'dXdots', 'dXline', 'dXtext');
% rGraphicsDraw(100, true, true);
% get return message