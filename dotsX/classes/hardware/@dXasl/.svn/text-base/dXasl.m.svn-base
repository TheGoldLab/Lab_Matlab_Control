function [a_, attributes_, batchMethods_] = dXasl(num_objects)
% function [a_, attributes_, batchMethods_] = dXasl(num_objects)
%
% Constructor method for class asl
%   A-S-L eyetracker
%
% Input:
%   first arg is init flag
%   second arg is flag to init FIRA for awd data
%
% Output:
%   a_          ... created object
%   attributes_ ... default object attributes
%   batchMethods_  ... methods that can be run in a batch (e.g., draw)

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania
global ROOT_STRUCT

% make sure eyetracker available .. check for 'as' mex function
available = ~isempty(which('as'));

% return empty matrix if not available, which
% will automatically remove dXasl devices from the ui queue
% if called from rInit
if isfield(ROOT_STRUCT, 'dXasl') || ~available || ~nargin
    a_            = [];
    attributes_   = [];
    batchMethods_ = [];
    return
end

% default parameters for blink filtering
%   these units are pretty raw:
BF.n = 5; % number of frames
BF.lowP = 0; % unknown units
BF.deltaP = 10; % unknown units per frame
BF.deltaH = 650; % point-of-gaze-units*100 per frame
BF.deltaV = 650; % point-of-gaze-units*100 per frame

% default object attributes
attributes = { ...
    % name        type		  ranges(?)	default
    'available',    'boolean',  []      available;  ...
    'active',       'boolean',  [],     false;      ...
    'blinkParams',  'struct',   [],     BF;        ...
    'mouseMode'     'boolean',  [],     false;      ...
    'showPlot',     'boolean',  [],     false;      ...
    'showPtr',      'cell',     [],     {};         ...
    'movePtr',      'cell',     [],     {};         ...
    'mappings',     'cell',     [],     [];         ...
    'FIRAdataType', 'string',   [],     'aslData';  ...
    'names',        'cell',     [],     {'pupil_d', 'horiz_eye', 'vert_eye', 'frame_num', 'isBlinking'}; ...
    'offsetTime',   'scalar',   [],     0;          ...
    'checkShape',   'scalar',   [],     0;          ... 0 = rectangle, 1, = circle.    
    'freq',         'scalar',   [],     120;        ...
    'gain',         'scalar',   [],     1;          ...
    'aslRect',      'array',    [],     [-2032, 1532, 4064, -3064];... %if its a circle x,y,radius
    'default',      'auto',     [],     [];         ...
    'other',        'auto',     [],     [];         ...
    'checkList',    'auto',     [],     [];         ...
    'checkRet',     'auto',     [],     {};         ...
    'values',       'auto',     [],     [];         ...
    'recentVal',    'auto',     [],     1;          ...
    'degreeRect',   'auto',     [],     [];         ...
    'degPercm',     'auto',     [],     [];         ...
    'fig',          'auto',     [],     [];         ...
    'ax',           'auto',     [],     [];         ...
    'plt',          'auto',     [],     []};

% make an array of objects from structs made from the attributes
% call set to init auto fields
a_ = class(cell2struct(attributes(:,4), attributes(:,1), 1), 'dXasl');

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'reset', 'query', 'saveToFIRA', 'root', 'getJump'};
end
