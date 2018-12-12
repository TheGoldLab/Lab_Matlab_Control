function activateEnsemblesByState(activeList, state)
% function activateEnsemblesByState(activeList, state)
%
% Toggle isActive flags for children of concurrentComposite during
%  stateMachine traversal. This is used if you don't want all of 
%  the children of the topsConcurrentComposite that contains the 
%  stateMachine to always be running. 
%
% Arguments:
%  activeList           ... A cell array with possibly multiple rows of:
%     <[ensemble1], [ensemble1 method name]; [ensemble2], [ensemble2 method name]>, 
%               <cell array of state names to activate>
%
% Created 5/10/18 by jig

% disp(sprintf('Entering state <%s>', state.name))

%% Loop through the specification list
for ii = 1:size(activeList, 1)
   
   % check if should be activated
   if any(strcmp(state.name, activeList{ii,2}))
      activateFlag = true;
   else
      activateFlag = false;
   end
   
   % loop through each object in list
   for jj = 1:size(activeList{ii,1},1)
      
      % get the ensemble
      theEnsemble = activeList{ii,1}{jj,1};

      % get the method
      methodName = activeList{ii,1}{jj,2};
      
      % Activate/deactivate
      theEnsemble.setActiveByName(activateFlag, methodName);
   end
end
