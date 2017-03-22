function rSetMany(varargin)
%Set properties of multiple objects belonging to like or unlike classes.
%   rSetMany(varargin)
%
%   rSetMany calls the overloaded "set" method for objects of each class
%   specified.  Arguments shoule come in triplets of the form 
%   {CLASS_NAME1, INDICES1, ARGS1, CLASS_NAME2, INDICES2, ARGS2, ...},
%   where each CLASS_NAME is a string, each INDICES is a 1-by-N array of
%   integers, and each ARGS is a cell array of property-value pairs.
%
%   The following simultaneously sets propeties of dXdots objects and
%   dXtarget objects.
%
%   rInit('debug');
%   rAdd('dXdots', 3);
%   rAdd('dXtarget', 3);
%   inds = 1:3;
%   args = {'color', [0,255,0], 'diameter', 6};
%   rSetMany('dXdots', inds, args, 'dXtarget', inds, args);
%
%   See also rInit, rAdd, dXdots, dXtarget, rSet, rSetTaskByName

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

ind = 1;
lva = length(varargin);

while ind < lva
    % call the class-specific set routines, saving the result
    ROOT_STRUCT.(varargin{ind})(varargin{ind+1}) = ...
        set(ROOT_STRUCT.(varargin{ind})(varargin{ind+1}), ...
        varargin{ind+2}{:});

    ind = ind + 3;
end