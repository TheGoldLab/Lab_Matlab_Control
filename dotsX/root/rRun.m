function rRun(taskList, filename, varargin)
%Execute one or more tasks, especially from the command line.
%   rRun(taskList, filename, varargin)
%
%   rRun creates an instance of dXparadigm and calls rInit so that an
%   experiment specified by taskList can be executed.  taskList must be the
%   string name of a task script (without the .m extension) or a cell array
%   of such task strings.
%
%   filename is the name of a file, without the .mat extension, in which
%   to write the data acquisition structure FIRA and the DotsX control
%   structure ROOT_STRUCT.  If filename is the empty [], or not
%   provided, neither FIRA nor ROOT_STRUCT will be written to disk. 
%
%   varargin is an optional list of the form
%       ...'class_name, {'property', value ...},...
%   to send to rInit.
%
%   varargin may also contain elements of the form
%       ...'screenMode', 'local', ... or
%       ...'screenMode', 'debug', ...
%   to run a paradigm in a mode other than remote mode.
%
%   The following three examples will execute variations on the same
%   calibration task.
%
%   % calibrate with remote graphics (default) and save nothing
%   rRun('taskCalibrateAsl');
%
%   % calibrate with local graphics and save nothing
%   rRun('taskCalibrateAsl', [], 'screenMode', 'local');
%
%   % calibrate, writing FIRA to disk after each trial (default, if FIRA
%   exists) and writing ROOT_STRUCT to disk every five minutes.
%   rRun('taskCalibrateAsl', 'test', 'ROOT_writeInterval', 5*60);
%
%   See also rInit, dXparadigm, dXtask, taskCalibrateAsl, dXgui

% Copyright 2006 by Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT

% lets assume a cell
if ischar(taskList)
    taskList = {taskList};
end

if length(taskList) == 1
    name = taskList{1};
else
    name = 'tasks';
end

% check args
if nargin < 2
    filename = [];
end

% pull screenMode out of arg list
argi = find(strcmp(varargin(1:2:end), 'screenMode'))*2;
if isempty(argi) || ~any(argi)
    screenMode = 'remote';
else
    screenMode = varargin{argi};
    varargin(argi-1:argi) = [];
end

% pull dXparadigm set args out of arg list
argi = find(strcmp(varargin(1:2:end), 'dXparadigm'))*2;
if isempty(argi) || ~any(argi) || ~iscell(varargin{argi})
    parArgs = {};
else
    parArgs = varargin{argi};
    varargin(argi-1:argi) = [];
end

%pass remaining args to rInit

% call rInit to prepare a ROOT_STRUCT.
%   Always call with dXparadigm, in remote by default.
%   Varargin overrides these default settings.
if isempty(filename)
    % save trials to FIRA, but don't write ROOT_STRUCT or FIRA to disk
    rInit(screenMode, 'dXparadigm', ...
        cat(2, {'taskList',            taskList, ...
        'name',                 name, ...
        'saveToFIRA',           true}, parArgs), ...
        varargin{:});
else
    % save trials to FIRA, write ROOT_STRUCT and FIRA to disk in default
    % directory as 'filename', after every trial.
    rInit(screenMode, 'dXparadigm', ...
        cat(2, {'taskList',            taskList, ...
        'name',                 name, ...
        'ROOT_filenameBase',    filename, ...
        'ROOT_writeInterval',   0, ...
        'ROOT_doWrite',         true, ...
        'FIRA_filenameBase',    filename, ...
        'FIRA_writeInterval',   0, ...
        'FIRA_doWrite',         true, ...
        'saveToFIRA',           true, ...
        'fileSuffixMode',       'session'}, parArgs), ...
        varargin{:});
end

% evaluate all task scripts
ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm);

try
    % light this candle
    runTasks(ROOT_STRUCT.dXparadigm);
    
    % cleanup screen, etc.
    rDone;
catch
    % Quesque c'est?
    le = lasterror;
    disp(le.message);
    rDone;
end