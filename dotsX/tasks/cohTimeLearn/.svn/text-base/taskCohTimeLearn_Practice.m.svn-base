function index_ = taskCohTimeLearn_Practice(varargin)
%Practice the cohTimeLearn task at 100% coherence
%
%   index_ = taskCohTimeLearn_Practice(varargin)
%
%   optional eye tracker for fixation
%   lpHID choices
%
%   index_ specifies the new instance in ROOT_STRUCT.dXtask

% copyright 2008 Benjamin Heasly University of Pennsylvania

% name for this task
name = mfilename;

if nargin >= 2

    % ASL and sound info
    settings = varargin{1};

    % number of trials
    numTrials = varargin{2};

    varargin(1:2) = [];
else
    warning(sprintf('%s using default values', mfilename));
    settings.useASL = true;
    settings.mouseMode = false;
    settings.mute = false;
    settings.dotDir = [0 180];
    settings.viewingTimes = [100 200 400 800];
    numTrials = 10;
end

% number of trials and nuber of dXtc conditons
%   give the number of blocks
numBlocks = ceil(numTrials/length(settings.dotDir));

% dXtc to randomize dot direction and hold the viewing time
arg_dXtc = { ...
    'name',     {'dot_dir', 'viewing_time'}, ...
    'values',	{settings.dotDir, settings.viewingTimes(1)}, ...
    'ptr',      {{'dXdots', 1, 'direction'}, {}}};

arg_dXlr = { ...
    'ptr',      {{'dXdots', 1, 'direction'}}};

% args to make statelist polymorphic
ptrs = {'dXtc', 'dXlr'};
vtcon = {'wait', {'dXtc', 2, 'value'}, []};
PQ = {};
arg_statelist = {ptrs, vtcon, PQ, settings};

% {'group', reuse, set now, set always}
reswap = {'current', false, true, false};
ta = cohTimeLearn_task_args;
index_ = rAdd('dXtask', 1, {'root', false, true, false}, ...
    'name',	name(5:end), ...
    'blockReps',    numBlocks, ...
    'startTaskFcn',	{}, ...%@cohTimeLearn_pickNewViewingTime}, ...
    'helpers', ...
    { ...
    'dXtc',                     2,  reswap, arg_dXtc; ...
    'dXlr',                     1,  reswap, arg_dXlr; ...
    'gXcohTimeLearn_hardware',	1,  true,   {settings}; ...
    'gXcohTimeLearn_graphics',	1,  true,	{settings}; ...
    'gXcohTimeLearn_statelist',	1,  false,	arg_statelist; ...
    }, ...
    ta{:}, varargin{:});