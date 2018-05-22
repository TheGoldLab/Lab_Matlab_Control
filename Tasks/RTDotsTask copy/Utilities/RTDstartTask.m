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

%% ---- Show intro/transition
if taskTreeNode.nodeData.taskNumber == 1
   
   % Initial instructions
   if isa(datatub{'Control'}{'ui'}, 'dotsReadableEyePupilLabs')
      str2 = 'Each trial starts by fixating the central cross';
   else
      str2 = 'Each trial starts by pressing the space bar';
   end
   RDTshowText(datatub, {'Work at your own pace', str2}, ...
      datatub{'Timing'}{'showInstructions'});
   
else
   
   % Give a little break between tasks
   for timer = 10:-1:1
      RDTshowText(datatub, {'Well done!' , ...
         sprintf('Next task starts in: %d', timer)}, 1);
   end      
end

%% ---- Pause between instructions
pause(1);

%% ---- Show instructions
if ~isempty(instructionStrings{1}) || ~isempty(instructionStrings{1})   
   RDTshowText(datatub, instructionStrings, datatub{'Timing'}{'showInstructions'});
end

%% ---- Turn off both strings
RTDsetVisible(datatub{'Graphics'}{'textEnsemble'}, [], ...
   datatub{'Graphics'}{'text inds'});
   