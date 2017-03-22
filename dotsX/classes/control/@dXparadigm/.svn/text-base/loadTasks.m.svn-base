function p_ = loadTasks(p_, otherList)
% function p_ = loadTasks(p_, otherList)
%
% Method for dXparadigm class that prepares a ROOT_STRUCT for an
% experiment.  Either inits and runs all the scripts in p_.taskList or runs
% the scripts in otherList without initing.
%
% Args:
%   p_          ... instance of dXparadigm (with p_.taskList)
%
%   otherList   ... alternate 'taskList' cell array to be called
%
% Returns the paradigm instance.
%
% 2006 by Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT

if ~nargin
    %get real
    return
elseif nargin == 1 || isempty(otherList)

    % don't get confused, now
    rClear

    % reload all tasks
    tL = p_.taskList;
    taskCount = 0;

elseif nargin > 1 && ~isempty(otherList)

    % Reload only new tasks
    tL = otherList;

    % offset taskCount by number of existing tasks
    taskCount = length(p_.taskList);
end

% make self accessible to task scripts
ROOT_STRUCT.dXparadigm(1) = p_;

% make local (inaccessible) copy of taskProportions
tP = p_.taskProportions;

%%%
% CALL TASK SETUP SCRIPTS
%%%
disp('Loading tasks could take a while...')
while ~isempty(tL)

    % parse name of task file (check for "task" prefix)
    if ischar(tL{1})
        if strncmp(tL{1}, 'task', 4)
            name = tL{1};
        else
            name = ['task' tL{1}];
        end

        % does such a task file exist?
        if exist(name)==2

            disp(sprintf('...loading %s', name))
            
            % parse optional repetitions argument
            if length(tL)>1 && isnumeric(tL{2}) && isscalar(tL{2})
                reps = tL{2};
                tL(2) = [];
            else
                reps = 1;
            end

            % parse optional arguments to task function
            if length(tL)>1 && iscell(tL{2})
                args = tL{2};
                tL(2) = [];
            else
                args = [];
            end

            if ~isempty(args)

                % feval task function with args
                feval(name, args{:});
            else

                % eval task file as script
                eval([name ';']);
            end

            % set repetitions for this new task
            taskCount = taskCount + 1;
            tP(taskCount) = reps;

        else
            % there is no such task file
            disp(sprintf('...can''t find %s', name))
        end
    end
    tL(1) = [];
end

% update self after task scripts
p_ = ROOT_STRUCT.dXparadigm(1);

% save local copy of taskPorportions
p_.taskProportions = tP;

disp([p_.name, ' ready']);