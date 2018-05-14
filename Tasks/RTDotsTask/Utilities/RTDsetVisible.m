function RTDsetVisible(drawables, inds_on, inds_off, datatub, eventTag)
% function RTDsetVisible(ensemble, inds_on, inds_off, datatub, eventTag)
%
% Utility for setting isVisible flag of drawable objects to true/false,
%  then possibly sending a screen flip command
%
% Arguments:
%  drawables   ... ensemble with objects to draw
%  inds_on     ... indices of ensemble objects to set isVisible=true
%  inds_off    ... indices of ensemble objects to set isVisible=false
%  datatub     ... if given, get screen object, draw, and save timing
%  eventTag    ... string used to store timing information in trial struct
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
   
   % Call runBriefly for the drawable ensemble
   drawables.runBriefly();
   
   % Use the screenEmsemble to draw the next frame  
   screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
   ret = screenEnsemble.callByName('flip');

   % Save timing information in the trial struct, then re-save
	task = datatub{'Control'}{'currentTask'};
   trial = task.nodeData.trialData(task.nodeData.currentTrial);
   trial.(sprintf('time_screen_%s', eventTag)) = ret.onsetTime;
   trial.(sprintf('time_local_%s', eventTag)) = mglGetSecs;
   task.nodeData.trialData(task.nodeData.currentTrial) = trial;
end
