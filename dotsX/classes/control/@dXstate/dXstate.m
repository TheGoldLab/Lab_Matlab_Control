function [states_, attributes_, batchMethods_] = dXstate(num_objects)
% function [states_, attributes_, batchMethods_] = dXstate(num_objects)
%
% Constructor method for class dXstate
%
% Arguments:
%   num_objects   ... number of dXstate objects to create
%
% Returns:
%   states_       ... array of created dXstates
%   attributes_   ... default object attributes
%   batchMethods_ ... 

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes ... see dXtask/set for details
attributes = { ...
    % name      type		ranges(?)	default
    'name',     'string',   [],         [];  ...
    'func',     'handle',   [],         [];  ...
    'args',     'cell',     [],         {};  ...
    'jump',     'string',   [],         {};  ...
    'wait',     'special',  [],         [];  ... % scalar or cell array
    'reps',     'int',      [],         0;   ...
    'draw',     'int',      [],         0;   ...
    'query',    'int',      [],         0;   ...
    'cond',     'cell',     [],         {}};

% tags are numeric array, make struct from defaults
sl = cell2struct(attributes(:,4), attributes(:,1), 1);
for ii = 1:num_objects
    
    % make the object
    states_(ii) = class(sl, 'dXstate');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {};
end
