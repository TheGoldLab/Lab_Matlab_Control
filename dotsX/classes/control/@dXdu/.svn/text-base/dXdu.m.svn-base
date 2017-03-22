function [dus_, attributes_, batchMethods_] = dXdu(num_objects)
% function [dus_, attributes_, batchMethods_] = dXdu(num_objects)
%
% Constructor method for class dXdu (down/up)...
% Simple variable class that computes a down/up
% index (0 = down, 1 = up) from a direction
%
% Arguments:
%   num_objects   ... number of objects to create
%
% Returns:
%   dus_          ... array of created dXdu
%   attributes_   ... default object attributes
%   batchMethods_ ...

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name          type		ranges(?)	default
    'ptr',          'cell',     [],         {};     ...
    'coefficient',	'scalar',   [],         pi/180;	...
    'intercept',    'scalar',   [],         0;      ...
    'value',        'auto',     [],         []};

% tags are numeric array, make struct from defaults
dXduStruct = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    dus_(i) = class(dXduStruct, 'dXdu');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'update', 'endTrial', 'saveToFIRA'};
end
