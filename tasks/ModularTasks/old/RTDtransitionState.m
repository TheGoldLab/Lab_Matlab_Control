function RTDtransitionState(transitionStates, state)
% function RTDtransitionState(transitionStates, state)
%
% Toggle isActive flags for children of trialConcurrents

disp(sprintf('Transitioning from %s to %s', ...
     transitionStates(1).name, transitionStates(2).name));

%% Get the trialConcurrents object
trialConcurrents = state{'Control'}{'trialConcurrents'};

%% Get the toggle specification list
% Rows are lists of objects to toggle
%  first column is list of objects
%  second column specifies states, either:
%     - cell array of string names of states
%     - keyword 'auto' followed by fevalable to compare
transitionList = state{'Control'}{'transition list'};

for ii = 1:size(transitionList, 1)
   
   % check if should be activated
   if (strcmp(transitionList{ii,2}{1}, 'auto') && ...
         ~isempty(transitionStates(2).input) && ...
         isequal(transitionStates(2).input{1}, transitionList{ii,2}{2}{1})) || ...
         any(strcmp(transitionStates(2).name, transitionList{ii,2}))
      activate = true;
   else
      activate = false;
   end
   
   % loop through each object in list
   for jj = 1:length(transitionList{ii,1})
      
      % get the object
      theObject = transitionList{ii,1}{jj};
      
      % is it already active?
      isActive = trialConcurrents.getChildIsActive(theObject);
      
      if ~isActive && activate
         trialConcurrents.setChildIsActive(theObject, true);
      elseif isActive && ~activate
         trialConcurrents.setChildIsActive(theObject, false);
      end
   end
end
