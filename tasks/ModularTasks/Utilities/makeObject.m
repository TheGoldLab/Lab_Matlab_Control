function object = makeObject(constructor, argStruct)
% function object = makeObject(constructor, argStruct)
%
% Utility for making an object from a class contructor
%  and then updating properties with values from the given struct

% Make the object
object = feval(constructor);

% Update properties if given. No error checking on property names
if nargin > 1 && ~isempty(argStruct)
   
   for ff = fieldnames(argStruct)'
      object.(ff{:}) = argStruct.(ff{:});
   end
end