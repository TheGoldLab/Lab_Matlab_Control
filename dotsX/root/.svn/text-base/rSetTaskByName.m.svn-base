function rSetTaskByName(name, varargin)
%Set properties of a dXtask instance with the given name
%   rSetTaskByName(name, varargin)
%
%   rSetTaskByName is a substitute for rSet which only operates on objects
%   of type dXtask and which uses the name of a dXtask instead of an object
%   index.
%
%   The following two examples are equivalent.
%
%   % set properties with rSet
%   rInit('debug');
%   rAdd('dXtask', 1, 'name', 'someTask');
%   rSet('dXtask', 1, 'trialOrder', 'block');
% 
%   % set properties with rSetTaskByName
%   rInit('debug');
%   rAdd('dXtask', 1, 'name', 'someTask');
%   rSetTaskByName('someTask', 'trialOrder', 'block');
%
%   See also rSet, rSetMany, dXtask, rInit, rAdd

% 2006 by Benjamin Heasly at University of Pennsylvania

% get real
if ~nargin || isempty(name)
    return
elseif isempty(varargin)
    % empty varargin OK for set()
    varargin = {};
end

global ROOT_STRUCT

% dXtasks are never swapped into ROOT_STRUCT.classes... so there's no need
% to use that 'master' list.  In fact, instances in that list never have
% set called on them by rAdd.  So They're useless.  Use top-level instances.
taskBook = struct(ROOT_STRUCT.dXtask);
ti = find(strcmp({taskBook.name}, name));

% call set(), even with empty varargin
if ~isempty(ti)
    ROOT_STRUCT.dXtask(ti) = set(ROOT_STRUCT.dXtask(ti), varargin{:});
end