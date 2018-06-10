function drawTextEnsemble(textEnsemble, textStrings, showDuration, pauseDuration)
% function drawTextEnsemble(textEnsemble, textStrings, showDuration, pauseDuration)
%
% Show text strings using the given ensemble.
%
% Inputs:
%  textEnsemble  ... ensemble holding dotsDrawableText objects.
%  textStrings   ... cell array of strings; any can be empty to skip.
%                     rows are done in separate screens
%                     columns should correspond to the # of text objects in
%                     the ensemble to show at once
%  showDuration  ... Time (in sec) to show the text
%  pauseDuration ... Time (in sec) to pause after showing the text
%
% 5/11/18 created by jig

%% ---- Create a text ensemble if none given
if isempty(textEnsemble)
   
end

%% ---- Loop through each set
for ii = 1:size(textStrings, 1)
   
   % Set text strings in the given set
   for jj = 1:size(textStrings, 2) % many possible text objects
      if isempty(textStrings{ii,jj})
         textEnsemble.setObjectProperty('isVisible', false, jj);
      else
         textEnsemble.setObjectProperty('string', textStrings{ii,jj}, jj);
         textEnsemble.setObjectProperty('isVisible', true, jj);
      end
   end
   
   %% ---- Draw, wait, blank
   %
   % Call runBriefly for the instruction ensemble
   textEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
   
   % Wait
   pause(showDuration);
   
   % Set visible flags to false
   textEnsemble.setObjectProperty('isVisible', false);
   
   % Draw again to blank screen
   textEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
   
   % Wait again
   if nargin>3 && ~isempty(pauseDuration) && pauseDuration>0
      pause(pauseDuration);
   end
end
