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

% check for good trials
taskTreeNode.updateTrial();
if taskTreeNode.trialIndex<1
   error('RTDstartTask: bad task')
end

%% ---- Show intro/transition and instructions
% 
% Show all text with this duration
instructionDuration = datatub{'Timing'}{'showInstructions'};

if taskTreeNode.taskIndex == 1
   
   % For the first task, give some general instructions
   if isa(datatub{'Control'}{'userInputDevice'}, 'dotsReadableEye')
      str2 = 'Each trial starts by fixating the central cross';
   else
      str2 = 'Each trial starts by pressing the space bar';
   end
   RDTshowText(datatub, {'Work at your own pace', str2}, instructionDuration);
   
else
   
   % Otherwise give a little break between tasks
   for timer = 10:-1:1
      RDTshowText(datatub, {'Well done!' , ...
         sprintf('Next task starts in: %d', timer)}, 1);
   end      
end

% Pause between instructions
pause(1);

% Show task-specific instructions
if ~isempty(instructionStrings{1}) || ~isempty(instructionStrings{1})   
   RDTshowText(datatub, instructionStrings, instructionDuration);
end
 
