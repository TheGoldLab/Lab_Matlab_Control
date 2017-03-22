function [ncs_, attributes_, batchMethods_] = dXdefaultControl(num_objects)
% function [ncs_, attributes_, batchMethods_] = dXdefaultControl(num_objects)
%
% Constructor method for class dXdefaultControl
%   helper object for a task -- basically
%   does nothing)
%
% Arguments:
%   num_objects   ... number of objects to create
%
% Returns:
%   ncs_          ... array of created ncs
%   attributes_   ... default object attributes
%   batchMethods_ ... 

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania
%
% April 2006 BSH removed trial order.  dXtask should 'know' order.

% default object attributes
attributes = { ...
    % name           type		ranges(?)	default
    'name',          'scalar',   [],         [];   ...
    'numBlocks',     'scalar',   [],         [];   ...
    'stairStart',    'scalar',   [],         [];   ...
    'stairUp',       'scalar',   [],         [];   ...
    'stairDown',     'scalar',   [],         [];   ...
    'lastOutcome',   'auto',     [],         [];   ...
    'outcomeRun',    'auto',     [],         [];   ...
    'indices',       'auto',     [],         nan;  ...
    'index',         'audo',     [],         nan;

% tags are numeric array, make struct from defaults
nc = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    ncs_(i) = class(nc, 'dXdefaultControl');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'control', 'update', 'endTrial', 'saveToFIRA'};
end
