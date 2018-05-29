function drawTextEnsemble(textEnsemble, textStrings, duration)
% function drawTextEnsemble(textEnsemble, textStrings, duration)
%
% Show text strings using the given ensemble.
%
% Inputs:
%  textEnsemble ... ensemble holding dotsDrawableText objects.
%  textStrings  ... cell array of strings; any can be empty to skip
%  duration     ... Time (in sec) to show the text
%
% 5/11/18 created by jig

%% --- Set instruction strings
for ii = 1:length(textStrings) % two possible text objects
   if isempty(textStrings{ii})
      textEnsemble.setObjectProperty('isVisible', false, ii);
   else
      textEnsemble.setObjectProperty('string', textStrings{ii}, ii);
      textEnsemble.setObjectProperty('isVisible', true, ii);
   end
end

%% ---- Draw, wait, blank
%
% Call runBriefly for the instruction ensemble
textEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);

% Wait
pause(duration);

% Set visible flags to false
textEnsemble.setObjectProperty('isVisible', false);

% Draw again to blank screen
textEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);

