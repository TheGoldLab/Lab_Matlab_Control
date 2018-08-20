function ensemble = makeTextEnsemble(name, num, yOffset, screenEnsemble)
% function ensemble = makeTextEnsemble(name, num, yOffset, screenEnsemble)
%
% Convenient utility for combining a bunch of dotsDrawableText objects that
%  will show vertically positioned strings into an ensemble
%
% Aguments:
%  name           ... optional <string> name of the ensemble/composite 
%  num            ... number of objects to make
%  yOffset        ... vertical separation beween text strings on the screen
%  screenEnsemble ... ensemble containing the screen object, which we use 
%                       to determine client/server behavior
%
% 5/28/18 written by jig

if nargin < 1 || isempty(name)
   name = 'textEnsemble';
end

if nargin < 2 || isempty(num)
   num = 2;
end

if nargin < 3 || isempty(yOffset)
   yOffset = 3;
end

% If no screen ensemble given, assume this is local
if nargin < 4 || isempty(screenEnsemble) || ...
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

offsets = (0:num-1).*yOffset;
offsets = -(offsets - (offsets(end)-offsets(1))/2);
% make and add the objects
for ii = 1:num
   text = dotsDrawableText();
   text.y = offsets(ii);   
   ensemble.addObject(text);
end
