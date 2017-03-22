function [d_, attributes_, batchMethods_] = dXdistr(num_objects)
% function [d_, attributes_, batchMethods_] = dXdistr(num_objects)
%
% Constructor method for class dXdistr (tuning curve)
%
% dXdistr instances cooperate, act as one thing.  Interface with dXdistr(1).
%
% Arguments:
%   num_objects   ... number of objects to create
%
% Returns:
%   d_          ... array of created dXdistr
%   attributes_   ... default object attributes
%   batchMethods_ ...

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% make two default "d" distribution specifiers
d(1).gain = 1;
d(1).offset = 0;
d(1).args = {0,1};
d(1).func = @normrnd;
d(1).toFIRA = false;

d(2).gain = 1;
d(2).offset = 0;
d(2).args = {100,1};
d(2).func = @normrnd;
d(1).toFIRA = false;

% make a default 'm' metadistribution specifier
%   randomly picks between two distributions
m.first = 1;
m.second = 2;
m.p = .5;
m.count = 0;
m.args = {};

% default object attributes
attributes = { ...
    % name              type		ranges(?)	default
    'name',             'string',   [],         []; 	...
    'ptr',              'cell',     [],         [];     ...
    'override',         'scalar',   [],         [];     ...
    'totTrials',        'scalar',   [],         300;     ...
    'distributions',    'struct',   [],         d;      ...
    'metaD',            'struct',   [],         m;      ...
    'changeMetaD',      'array',    [],         0;      ...
    'subBlockSize',     'array',    [],         [];     ...
    'subBlockMethod',   'function_handle',[],   [];     ...
    'blockIndex',       'auto',     [],         1;      ...
    'subBlockTrial'     'auto',     [],         0;      ...
    'numTrials',        'auto',     [],         0;     ...
    'ptrType',          'auto',     [],         [];     ...
    'ptrClass',         'auto',     [],         [];     ...
    'ptrIndex',         'auto',     [],         [];     ...
    'nextValue',        'auto',     [],         nan;    ...
    'value',            'auto',     [],         nan;    ...
    'FIRAdataType',     'auto',     [],         'distrData'};

% tags are numeric array, make struct from defaults
sl = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    d_(i) = class(sl, 'dXdistr');
end

% It returns the attributes.  It does this whenever it is asked.
if nargout > 1
    attributes_ = attributes;
end

% It returns a list of batch methods.  It does this whenever it is asked.
if nargout > 2
    batchMethods_ = {'control', 'update', 'endTrial', 'saveToFIRA'};
end