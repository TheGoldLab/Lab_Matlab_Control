function [s_, attributes_, batchMethods_] = dXsaveToFIRA(tags)
% function [s_, attributes_, batchMethods_] = dXsaveToFIRA(tags)
%
% Creates a dXsaveToFIRA object, which is used
%   to initialize communication with FIRA struct
%
% Arguments:
%   tags           ... ignored taglist
%
% Returns:
%   s_             ... created dXsaveToFIRA object
%   attributes_    ... default object attributes
%   batchMethods_  ... methods that can be run in a batch (e.g., save)

% Copyright 2004 by Joshua I. Gold
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name              type		ranges  default
    'filename',         'string',   [],     []; ...
    'filepath',         'string',   [],     []; ...
    };

% make an array of objects from structs made from the attributes
s_ = class(cell2struct(attributes(:,4), attributes(:,1), 1), 'dXsaveToFIRA');

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

if nargout > 2
    batchMethods_ = {'root', 'saveTrial'};
end
