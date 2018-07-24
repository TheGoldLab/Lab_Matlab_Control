function ensemble = makeScreenEnsemble(useRemote, displayIndex)
% function ensemble = makeScreenEnsemble(useRemote, displayIndex)
%
% Convenient utility for creating a screen ensemble either as a (local)
%  topsEnsemble or for remote drawing using dotsClientEnsemble with default
%  network values.
%
% Aguments:
%  useRemote      ... flag for creating client/server ensembles
%  displayIndex   ... 0=debug screen; 1=main screen; 2=2nd screen; etc
% 5/28/18 written by jig


% First check for local/remote graphics
if nargin < 1 || isempty(useRemote)
   useRemote = false;
end

% Check display index
if nargin < 2 || isempty(displayIndex)
   displayIndex = 1; % primary screen
end

% Set up the screen object and ensemble
screen = dotsTheScreen.theObject();
screen.displayIndex = displayIndex;
ensemble = dotsEnsembleUtilities.makeEnsemble('screenEnsemble', useRemote);
ensemble.addObject(screen);
ensemble.automateObjectMethod('flip', @nextFrame);