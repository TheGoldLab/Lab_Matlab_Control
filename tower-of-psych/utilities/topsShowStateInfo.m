function showStateInfo(state)
% function showStateInfo(state)
%
% Can be used as a sharedFevalable in a dotsStateMachine
%
% Arguments:
%  state ... the current state
%
% Created 5/10/18 by jig

disp(sprintf('Entering state <%s>', state.name))
