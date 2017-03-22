function [bk_, attributes_, batchMethods_] = dXblank(num_objects)
% function [bk_, attributes_, batchMethods_] = dXblank(num_objects)
%
% Constructor method for class dXblank
% Simple variable class that computes a blank/stim
% index (0 = blank, 1 = stim) from a stimulus value (e.g. coherence)
%
% Arguments:
%   num_objects   ... number of objects to create
%
% Returns:
%   bk_           ... array of created lrs
%   attributes_   ... default object attributes
%   batchMethods_ ...

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name           type		ranges(?)	default
	'ptr',          'cell',     [],         {};	...
    'blankValue',   'scalar',   [],         0;	...   
    'value',        'auto',     [],         []};

% tags are numeric array, make struct from defaults
dXlrStruct = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    bk_(i) = class(dXlrStruct, 'dXblank');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'update', 'endTrial', 'saveToFIRA'};
end
