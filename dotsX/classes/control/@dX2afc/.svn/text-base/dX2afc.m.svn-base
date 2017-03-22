function [tafcs_, attributes_, batchMethods_] = dX2afc(num_objects)
% function [tafcs_, attributes_, batchMethods_] = dX2afc(num_objects)
%
% Constructor method for class tafc, which stores
% outcome data for a two-alternative forced-choice task
%
% Arguments:
%   num_objects   ... array of (int) tags of objects to create
%
% Returns:
%   afs_          ... array of created objects
%   attributes_   ... default object attributes
%   batchMethods_ ... 

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name           type		ranges(?)	default
    'outcome',       'cell',    [],         {}; ...
    'outcomeVal',    'auto',    [],         nan; ...
    'rt1',           'string',  [],         []; ...
    'rt1Val',        'auto',    [],         nan; ...
    'rt2',           'string',  [],         []; ...
    'rt2Val',        'auto',    [],         nan};
    
% tags are numeric array, make struct from defaults
tafc = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    tafcs_(i) = class(tafc, 'dX2afc');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'update', 'endTrial', 'saveToFIRA'};
end
