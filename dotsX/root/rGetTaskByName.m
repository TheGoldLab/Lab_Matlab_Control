function val_ = rGetTaskByName(name, varargin)
%Get a dXtask instance or properties of an instance with the given name
%   rGetTaskByName(name, varargin)
%
%   rGetTaskByName is a substitute for rGet which only operates on objects
%   of type dXtask and which uses the name of a dXtask instead of an object
%   index.
%
%   The following two examples are equivalent.
%
%   % get a task instance or its properties with rGet
%   rInit('debug');
%   rAdd('dXtask', 1, 'name', 'someTask');
%   some_task = rGet('dXtask', 1);
%   trial_order = rGet('dXtask', 1, 'trialOrder');
%
%   % get an instance or its properties with rGetTaskByName
%   rInit('debug');
%   rAdd('dXtask', 1, 'name', 'someTask');
%   some_task = rGetTaskByName('someTask');
%   trial_order = rGetTaskByName('someTask', 'trialOrder');
%
%   See also rGet, dXtask, rInit, rAdd

% 2006 by Benjamin Heasly at University of Pennsylvania

% get real
if ~nargin || isempty(name)
    val_ = [];
    return
end

global ROOT_STRUCT

% dXtasks are never swapped into ROOT_STRUCT.classes... so there's no need
% to use that 'master' list.  In fact, instances in that list never have
% set called on them by rAdd.  So They're useless.  Use top-level instances.
taskBook = struct(ROOT_STRUCT.dXtask);

if isfield(taskBook, 'name')
    ti = find(strcmp({taskBook.name}, name));
else
    val_ = [];
    return
end

if isempty(ti)
    val_ = [];
else

    if nargin < 2 || ~ischar(varargin{1})
        % return a whole task
        val_ = struct(ROOT_STRUCT.dXtask(ti));

    else
        % retrun one property value
        val_ = taskBook(ti).(varargin{1});

    end
end