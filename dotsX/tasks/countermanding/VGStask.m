function index_ = VGStask(varargin)
%Define the simple_demo task, with all its helpers
%
%   index_ = taskSimpleDemo(varargin)
%
%   taskSimpleDemo defines the simple_demo task.  It adds an instance of
%   dXtask to the current ROOT_STRUCT with the name SimpleDemo, and creates
%   a group of objects called SimpleDemo.  This group contains all the
%   helpers, including graphics, hardware devices, a statelist, and a few
%   control objects.  Together the dXtask instance and all its helpers
%   comprise a task that may be run with dXparadigm/runTasks.
%
%   taskSimpleDemo gets configuration informatino from the following helper
%   files:
%       gXsimpleDemo_graphics.m, for graphics config
%       gXsimpleDemo_hardware.m, for hardware config
%       gXsimpleDemo_statelist.m, for the satelist
%
%   taskSimpleDemo configures some "control" helpers here in this file.
%   They are two instances of dXtc, for ranomizing coherence and direction
%   conditions for the dXdots stimulus.
%
%   varargin may be a boolean specifying whether to mute all sounds.
%
%   index_ specifies the new instance in ROOT_STRUCT.dXtask

% 2008 by Benjamin Heasly
%   University of Pennsylvania
%   benjamin.heasly@gmail.com
%   (written in the Black Hills of South Dakota!)

if nargin >= 2

    % number of trials
    numTrials = varargin{1};

    % set of coherences to test
%     coherences = varargin{2};

    % mute all sounds?
    mute = varargin{3};

else
    warning(sprintf('%s missing arguments, using defaults', mfilename));
    numTrials = 10;
%     coherences = [0 51.2 100];
    mute = false;
end

% dXtc will randomize permutations of task parameters.  Each parameter needs
% a name, a set of values, and an optional pointer where the value of the
% parameter may be set each trial.  In this case, the parameters are left
% and right dot direction, and an set of coherences.
arg_dXtc = { ...
    'name',     {'target_location'}, ...
    'values',	{[-2, 2]}, ...
    'ptr',      {{'dXtarget', 1, 'x'}}};

% The number of trial conditions is the number of coherences times times
%   the number of directions
% numConditions = 2*length(coherences);

% In order to get the desired number of trials, we may need to repeat
% blocks of trial contitions.  Round up.
numBlocks = ceil(numTrials/numConditions);

% Get ready to rAdd the dXtask.  We must configure rAdd_args for both the
% dXtask itself and for the dXtc we conigured above.  rAdd_args tell rAdd
% four things:
%   1. What group should these objects belong to?  'current' means add
%   objects to whatever group is currently active (e.g. the current task).
%   'root' means add objects to the root group, which is always active.
%
%   2. Should rAdd try to reuse existing objects of the same type?  If so,
%   rAdd will configure some existing objects rather than create new ones.
%
%   3. Should rAdd configure objects with rSet immediately upon creation?
%
%   4. Should rGroup reconfigure the object with rSet every time rGroup
%   activates this object (e.g. every time the task is activated)?
dXtask_rAdd_args = {'root', false, true, false};
dXtc_rAdd_args = {'current', false, true, false};

% For the helper groups we defined in, like gXcohTimeLearn_graphics, the
% rAdd_args is just a boolean specifying whether to reuse an existing group
% with the same name, instead of creating a new group.
group_rAdd_args = false;

% Add a dXtask to the current ROOT_STRUCT.  This dXtask will contain all
% our configured helpers, plus aditional configuration:
%   name            the name of this task and its group of helpers
%   blockReps       the number of trials per condition
%   statesToFIRA    state names for saving timing information to FIRA
%                   1 = save time when state begins
%                   2 = save time just after state function evaluation
%                   3 = save flip time when state draws graphics
%                   4 = save time query mapping event occurred
%   wrtState        state defined as 0 time
%   objectsToFIRA   find objects with data to save automaticall to FIRA
%   anyStates       entering either of these states defines a good trial
%   bgColor         screen background color during the task
%   trialOrder      dXtc will check this and randomize stimulus conditions
%   timeout         maximum time a trial may last

% Automaticall name this task the same as this file
%   exclude the "task" prefix
fileName = mfilename;
taskName = fileName(5:end);

index_ = rAdd('dXtask', 1, dXtask_rAdd_args, ...
    'helpers', ...
    { ...
    'dXtc',             1,  dXtc_rAdd_args,     arg_dXtc; ...
    'gXCMD_graphics',	1,  group_rAdd_args,    {}; ...
    'gXCMD_hardware',	1,  group_rAdd_args,    {mute}; ...
    'gXVGS_statelist',	1,  group_rAdd_args,    {}; ...
    }, ...
    'name',	taskName, ...
    'blockReps', numBlocks, ...
    'statesToFIRA', ...
    { ...
    'clear',    3; ...
    'fixOn',    3; ...
    'ready1',   1; ...
    'ready2',   1; ...
    'dotsOn',   3; ...
    'respond',  3; ...
    'left'      1; ...
    'right'     1; ...
    'correct',  1; ...
    'cText',    3; ...
    'incorrect',1; ...
    'iText',    3; ...
    'error'     1; ...
    'eText',    3; ...
    'end'       3; ...
    }, ...
    'wrtState',         'fixOff', ...
    'objectsToFIRA',    {'saveToFIRA'}, ...
    'anyStates',        {'correct', 'incorrect'}, ...
    'bgColor',          [0,0,0], ...
    'trialOrder',       'random', ...
    'timeout',          3600);