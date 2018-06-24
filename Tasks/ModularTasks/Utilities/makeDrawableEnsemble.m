function ensemble = makeDrawableEnsemble(name, objects, screenEnsemble, automateDraw)
% function ensemble = makeDrawableEnsemble(name, objects, screenEnsemble, automateDraw)
%
% Convenient utility for combining a bunch of drawables into an ensemble
%
% Aguments:
%  name           ... optional <string> name of the ensemble/composite 
%  objects        ... cell array of drawable objects
%  screenEnsemble ... ensemble containing the screen object, which we use 
%                       to determine client/server behavior
%  automateDraw   ... flag indicating whether or not to add automate draw
%                       method
%
% 5/28/18 written by jig

if nargin < 1 || isempty(name)
   name = 'drawable';
end

% If no screen ensemble given, assume this is local
if nargin < 3 || isempty(screenEnsemble) || ...
      ~isa(screenEnsemble, 'dotsClientEnsemble')
   remoteInfo = {false};
else
   remoteInfo = {true, ...
      screenEnsemble.clientIP, ...
      screenEnsemble.clientPort, ...
      screenEnsemble.serverIP, ...
      screenEnsemble.serverPort};
end

% create the ensemble
ensemble = dotsEnsembleUtilities.makeEnsemble([name 'Ensemble'], remoteInfo{:});

% add the objects
for ii = 1:length(objects)
   ensemble.addObject(objects{ii});
end

% possibly automate drawing
if nargin > 3 && automateDraw
   ensemble.automateObjectMethod('draw', @mayDrawNow);
end