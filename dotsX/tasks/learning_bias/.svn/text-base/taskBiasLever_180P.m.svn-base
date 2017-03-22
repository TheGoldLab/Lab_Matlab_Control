function index_ = taskBiasLever_180P(varargin)
%Practice the dXquest and lever pull motion disrimination task
%
%   index_ = taskBiasLever_180P(varargin)
%
%   eye tracker for fixation
%   lpHID choices
%
%   index_ specifies the new instance in ROOT_STRUCT.dXtask

% copyright 2007 Benjamin Heasly University of Pennsylvania
% modified 2008 Benjamin Naecker University of Pennsylvania

% name for this task
name = mfilename;

% ASL or not?
if nargin
    useASL = varargin{1};
    varargin(1) = [];
else
    useASL = true;
end

% args to make statelist polymorphic
arg_statelist = {name(5:end), {'dXtc', 'dXlr'}, useASL};

arg_dXtc = { ...
    'name',     'high_coh_dot_dir', ...
    'values',	[180, 0], ...
    'ptr',      {{'dXdots', 1, 'direction'}}};

arg_dXlr = { ...
    'ptr',      {{'dXdots', 1, 'direction'}}};

% {'group', reuse, set now, set always}
static = {'current', true, true, false};
reswap = {'current', false, true, false};

bta = bias_task_args;
index_ = rAdd('dXtask', 1, {'root', false, true, false}, ...
    'name',	name(5:end), ...
    'blockReps', 5, ...
    'bgColor', [0,0,0], ...
    'helpers', { ...
    'dXtc',                 1,  reswap, arg_dXtc; ...
    'dXlr',                 1,  static, arg_dXlr; ...
    'gXbias_hardware',      1,  true,   {useASL}; ...
    'gXbias_graphics',      1,  true,	{}; ...
    'gXbias_statelist',     1,  false,	arg_statelist}, ...
    bta{:}, varargin{:});