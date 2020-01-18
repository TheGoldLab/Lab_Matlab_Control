function topsActivateEnsemblesByState(activeList, state)
% function topsActivateEnsemblesByState(activeList, state)
%
% Toggle isActive flags of a topsEnsemble during
%  stateMachine traversal. This is used if you don't want all of 
%  the children stateMachine to be running all the time.
%
% Arguments:
%  activeList  ... A cell array with rows that correspond to different
%                    groups of ensembles, with two columns of data:
%
%                    - Column 1 is a list of ensemble/method pairs to call; e.g.,
%                          { <ensemble1>, <ensemble1 method name>; 
%                            <ensemble2>, <ensemble2 method name>; ...
%                            etc. }
%                    
%                    - Column 2 is a list of states in which to call those
%                          methods; e.g., 
%                           { <state1>, <state2>, etc. }
%
%  state       ... string name of the current state when this shared fevalable
%                    is called.
%
% Created 5/10/18 by jig

% disp(sprintf('Entering state <%s>', state.name))

%% Loop through the specification list
% 
% Each row is a different ensemble
for ii = 1:size(activeList, 1)
   
   % The second column is a list of states. First check if the current 
   %  state is in the list and therefore should be activated
   if any(strcmp(state.name, activeList{ii,2}))
      
      % Found it -- activate!
      activateFlag = true;
   else
      
      % Did not find it -- inactivate!
      activateFlag = false;
   end
   
   % The first column is a list of ensemble/method pairs. Loop through 
   %  each pair and set the activateFlag.
   for jj = 1:size(activeList{ii,1},1)
      
      % get the ensemble
      theEnsemble = activeList{ii,1}{jj,1};

      % get the method
      methodName = activeList{ii,1}{jj,2};
      
      % Activate/deactivate
      theEnsemble.setActiveByName(activateFlag, methodName);
   end
end
