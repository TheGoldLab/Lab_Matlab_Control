function [fc_, attributes_, batchMethods_] = dXfunctionCaller(num_objects)
% function [fc_, attributes_, batchMethods_] = dXfunctionCaller(num_objects)
%
% Constructor method for dXfunctionCaller, which holds as properties
%   an arbitrary function with arguments, and can make the function call.
%
% Arguments:
%   num_objects     ... number of objects to create
%
% Returns:
%   fc_             ... array of created dXfunctionCallers
%   attributes_     ... default object attributes
%   batchMethods_	... probably should have none

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name          type                ranges(?)       default
    'function',     'function_handle',	[],             [];     ...
    'class',        'string',           [],             [];     ...
    'indices',      'array',            [],             [];     ...
    'args',         'cell',             [],             {};     ...
    'doEndTrial',   'boolean',          [],             false;  ...
    'functionType', 'auto',             [],             0;      ...
    'ans',          'auto',             [],             [];     ...
    };

% tags are numeric array, make struct from defaults
fca = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    fc_(i) = class(fca, 'dXfunctionCaller');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'endTrial'};
end