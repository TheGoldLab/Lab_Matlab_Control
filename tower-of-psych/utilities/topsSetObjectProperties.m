function topsSetObjectProperties(object, index, args)
% function topsSetObjectProperties(object, index, args)
%
% Utility for setting properties of a stand-alone object or an indexed
% object in a topsEnsemble
%
% object    ... duh
% index     ... index of object if object is a topsEnsemble
% args      ... cell array of property/value pairs or struct

if nargin < 3 || isempty(object) || isempty(args)
   return
end

% Make arguments as property/value pairs
if nargin == 3 && isstruct(args)
   args = struct2args(args);
end

if isempty(index)
   
   % Set properties of object
   for ii = 1:2:length(args)
      object.(args{ii}) = args{ii+1};
   end
   
else
   
   % Set properties of object in an ensemble
   for ii = 1:2:length(args)
      object.setObjectProperty(args{ii}, args{ii+1}, index);
   end
end