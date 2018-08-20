function [ensemble, inds, composite] = RTDmakeDrawableEnsemble(name, objects, ...
   remoteInfo, screenEnsemble)
% function [ensemble, inds, composite] = RTDmakeDrawableEnsemble(name, objects, ...
%    remoteInfo, screenEnsemble)
%
% RTD = Response-Time Dots
%
% Convenient utility for combining a bunch of drawables into an ensemble
%  with an automated "mayDrawNow" method, and then possibly aggregating
%  that ensemble with a screen ensemble into a topsConcurrentComposite,
%  which is a nice way of drawing an object (or group of objects) simply
%
% Aguments:
%  name           ... optional <string> name of the ensemble/composite 
%  objects        ... cell array of drawable objects
%  remoteInfo     ... cell arrray of arguments to
%                       dotsEnsembleUtilities.makeEnsemble (default {false}
%                       for local drawing)
%  screenEnsemble ... opional ensemble containing the screen object -- if
%                       given, the composite is formed
%
% 5/11/18 written by jig

if nargin < 1 || isempty(name)
   name = 'drawable';
end

if nargin < 3 || isempty(remoteInfo)
   remoteInfo = {false};
end

% create the ensemble
ensemble = dotsEnsembleUtilities.makeEnsemble( ...
   [name 'Ensemble'], remoteInfo{:});

% add the objects
inds = nans(length(objects),1);
for oo = 1:length(objects)
   inds(oo) = ensemble.addObject(objects{oo});
end

% automate mayDrawNow method
ensemble.automateObjectMethod('draw', @mayDrawNow);

% check for screen ensemble
if nargin >= 4 && ~isempty(screenEnsemble)
   
   % Make a concurrentComposite with the screen
   composite = topsConcurrentComposite([name 'ScreenComposite']);
   
   % add the drawable and screen ensembles
   composite.addChild(ensemble);
   composite.addChild(screenEnsemble);
end