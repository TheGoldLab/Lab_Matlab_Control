function activateEnsemblesByState(concurrentComposite, activeList, state)
% function activateEnsemblesByState(concurrentComposite, activeList, state)
%
% Toggle isActive flags for children of concurrentComposite during
%  stateMachine traversal. This is used if you don't want all of 
%  the children of the topsConcurrentComposite that contains the 
%  stateMachine to always be running. 
%
% Arguments:
%  concurrentComposite  ... the topsConcurrentComposite object that 
%                             contains the topsStateMachine
%  activeList           ... A cell array with possibly multiple rows of:
%     <cell array of ensembles>, <cell array of state names to activate>
%
% Created 5/10/18 by jig

disp(sprintf('Entering state <%s>', state.name))

%% Loop through the specification list
for ii = 1:size(activeList, 1)
   
   % check if should be activated
   if any(strcmp(state.name, activeList{ii,2}))
      activate = true;
   else
      activate = false;
   end
   
   % loop through each object in list
   for jj = 1:length(activeList{ii,1})
      
      % get the object
      theObject = activeList{ii,1}{jj};
      
      % is it already active?
      isActive = concurrentComposite.getChildIsActive(theObject);
      
      if ~isActive && activate
         concurrentComposite.setChildIsActive(theObject, true);
      elseif isActive && ~activate
         concurrentComposite.setChildIsActive(theObject, false);
      end
   end
end
