function ind_ = rTaskIndex(name, varargin)
%Get the index of a dXtask instance from its name
%   ind_ = rTaskIndex(name, varargin)
%
%   If you know the name of a task but not its index in ROOT_STRUCT, use
%   this too look it up.  This is especially useful when a dXtask wants to
%   refer to its global self in one of its own methods.
%
%   See also rGetTaskByName, dXtask

% 2008 by Benjamin Heasly at University of Pennsylvania

% get real
if ~nargin || isempty(name)
    ind_ = [];
    return
end

global ROOT_STRUCT

taskBook = struct(ROOT_STRUCT.dXtask);

if isfield(taskBook, 'name')
    ind_ = find(strcmp({taskBook.name}, name));
else
    ind_ = [];
    return
end