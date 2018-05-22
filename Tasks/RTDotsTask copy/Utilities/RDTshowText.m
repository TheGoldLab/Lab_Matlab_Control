function RDTshowText(datatub, instructionStrings, instructionDuration)
% function RDTshowText(datatub, instructionStrings, instructionDuration)
% RTD = Response-Time Dots
%
% Show instruction strings at the beginning of a task block. The strings
% are defined in RTDconfigureTasks.
%
% Inputs:
%  datatub             ... A topsGroupedList object containing experimental
%                          parameters as well as data recorded during the
%                          experiment.
%  instructionStrings  ... cell array of two strings to show (top and
%                          bottom); either can be empty to skip
%  instructionDuration ... time (in sec) to show the instructions
%
% 5/11/18 created by jig

%% ---- Get instructions ensemble
textEnsemble = datatub{'Graphics'}{'textEnsemble'};

%% --- Set instruction strings
inds = datatub{'Graphics'}{'text inds'};
for ii = 1:2 % two possible text objects
   if isempty(instructionStrings{ii})
      textEnsemble.setObjectProperty('isVisible', false, inds(ii));
   else
      textEnsemble.setObjectProperty('string', instructionStrings{ii}, inds(ii));
      textEnsemble.setObjectProperty('isVisible', true, inds(ii));
   end
end

%% ---- Draw, wait, blank
%
% Call runBriefly for the instruction ensemble
textEnsemble.callObjectMethod(@mayDrawNow);

% Use the screenEmsemble to draw the next frame
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
screenEnsemble.callObjectMethod(@nextFrame);

% Wait
pause(instructionDuration);

% Blank
screenEnsemble.callObjectMethod(@blank);
