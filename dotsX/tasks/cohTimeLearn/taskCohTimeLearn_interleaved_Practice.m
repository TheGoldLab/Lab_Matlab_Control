function index_ = taskCohTimeLearn_interleaved_Practice(varargin)
%Practice the cohTimeLearn interleaved task at 100% coherence
%
%   index_ = taskCohTimeLearn_interleaved_Practice(varargin)
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

% number of trials and nuber of dXtc conditons give the number of blocks
numBlocks = ceil(numTrials/8); %ceil(numTrials/length(settings.dotDir)/length(settings.viewingTimes))

% dXtc to randomize dot direction and hold the viewing time
arg_dXtc = { ...
    'name',     {'dot_dir', 'viewing_time'}, ...
    'values',	{settings.dotDir, settings.viewingTimes}, ...
    'ptr',      {{'dXdots', 1, 'direction'}, {}}};

arg_dXlr = { ...
    'ptr',      {{'dXdots', 1, 'direction'}}};

% args to make statelist polymorphic
ptrs = {'dXtc', 'dXlr'};
vtcon = {'wait', {'dXtc', 2, 'value'}, []};
PQ = {};
arg_statelist = {ptrs, vtcon, PQ, settings};

% a function to set 100% dot coherence
practiceDots = @(varargin) rSet('dXdots', 1, 'coherence', 75);

% {'group', reuse, set now, set always}
reswap = {'current', false, true, false};
ta = cohTimeLearn_task_args;
index_ = rAdd('dXtask', 1, {'root', false, true, false}, ...
    'name',	name(5:end), ...
    'blockReps',    numBlocks, ...
    'startTaskFcn', {practiceDots}, ...
    'helpers', ...
    { ...
    'dXtc',                     2,  reswap, arg_dXtc; ...
    'dXlr',                     1,  reswap, arg_dXlr; ...
    'gXcohTimeLearn_hardware',	1,  true,   {settings}; ...
    'gXcohTimeLearn_graphics',	1,  true,	{settings}; ...
    'gXcohTimeLearn_statelist',	1,  false,	arg_statelist; ...
    }, ...
    ta{:}, varargin{:});