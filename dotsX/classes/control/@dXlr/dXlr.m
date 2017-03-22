function [lrs_, attributes_, batchMethods_] = dXlr(num_objects)
% function [lrs_, attributes_, batchMethods_] = dXlr(num_objects)
%
% Constructor method for class dXlr (left/right)...
% Simple variable class that computes a left/right
% index (0 = left, 1 = right) from a direction
%
% Arguments:
%   num_objects   ... number of objects to create
%
% Returns:
%   lrs_          ... array of created lrs
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
dXlrStruct = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    lrs_(i) = class(dXlrStruct, 'dXlr');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'update', 'endTrial', 'saveToFIRA'};
end
