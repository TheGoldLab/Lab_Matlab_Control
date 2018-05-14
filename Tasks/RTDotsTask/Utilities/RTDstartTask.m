function RTDstartTask(datatub, taskTreeNode, instructionStrings)
% function RTDstartTask(datatub, taskTreeNode, instructionStrings)
%
% RTD = Response-Time Dots
%
% Show instruction strings at the beginning of a task block. The strings
% are defined in RTDconfigureTasks.
%
% Inputs:
%  datatub            ... A topsGroupedList object containing experimental 
%                          parameters as well as data recorded during the 
%                          experiment.
%  taskTreeNode       ... the topsTreeNode task that called this function
%  instructionStrings ... cell array of two strings to show (top and
%                          bottom); either can be empty to skip
% 
% 5/11/18 created by jig

%% ---- Save the topsTreeNode as the current task
datatub{'Control'}{'currentTask'} = taskTreeNode;

%% ---- Get instructions ensemble
instructionsEnsemble = datatub{'Graphics'}{'instructionsEnsemble'};

%% --- Set instruction strings
inds = datatub{'Graphics'}{'instruction inds'};
for ii = 1:2 % two possible text objects
   if isempty(instructionStrings{ii})
      instructionsEnsemble.setObjectProperty('isVisible', false, inds(ii));
   else
      instructionsEnsemble.setObjectProperty('string', instructionStrings{ii}, inds(ii));
      instructionsEnsemble.setObjectProperty('isVisible', true, inds(ii));
   end
end

%% ---- Possibly draw, wait, blank
if ~isempty(instructionStrings{1}) && ~isempty(instructionStrings{2})
   
   % Call runBriefly for the instruction ensemble
   instructionsEnsemble.runBriefly();
   
   % Use the screenEmsemble to draw the next frame
   screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
   screenEnsemble.callObjectMethod(@nextFrame);

   % Wait
   pause(datatub{'Timing'}{'showInstructions'});
   
   % Blank
   screenEnsemble.callObjectMethod(@blank);   
end