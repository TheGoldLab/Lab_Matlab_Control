function [sas_, attributes_, batchMethods_] = saver(num_objects)
% function [sas_, attributes_, batchMethods_] = saver(num_objects)
%
% Constructor method for class saver, which allows arbitrary
%   lists of attributes of objects to be saved to FIRA
%
% Arguments:
%   num_objects   ... array of (int) tags of objects to create
%
% Returns:
%   sas_          ... array of created savers
%   attributes_   ... default object attributes
%   batchMethods_ ... 
%   dependencies_ ...

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name           type		ranges(?)	default
    'attributes',    'cell',    [],         {}};
    
% tags are numeric array, make struct from defaults
sa = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    sas_(i) = class(sa, 'saver');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'update', 'endTrial', 'saveToFIRA'};
end
