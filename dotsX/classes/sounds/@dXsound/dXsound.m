function [s_, attributes_, batchMethods_] = dXsound(num_objects)
% function [s_, attributes_, batchMethods_] = dXsound(num_objects)
%
% Constructor method for class dXsound
%
% Arguments:
%   num_objects    ... number of objects to create
%
% Returns:
%   s_             ... array of new sound objects
%   attributes_    ... default object attributes
%   batchMethods_  ... not used

% Copyright 2008 by Benjamin Heasly
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name              type		ranges(?)	default
    'rawSound',         'array',	[],         [];     ... % nx2 or file
    'sampleFrequency',  'scalar',   [],         44100;  ... % Hz
    'bitrate',          'scalar',   [],         16;     ... % bits/sample
    'gain',             'scalar',   [],         1;      ... % volume
    'mute',             'boolean',  [],         false;  ... % suppress?
    'duration',         'auto',     [],         [];     ... % sec
    'sound',            'auto',     [],         [];     ...
    'tag',              'auto',     [],         0};         % ignored

% make an array of objects from structs made from the attributes
b = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    s_(i) = class(b, 'dXsound');
end

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% no batch methods
if nargout > 2
    batchMethods_ = {};
end