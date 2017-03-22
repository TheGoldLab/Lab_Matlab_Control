function [uNames, tnID, allNames] = unifyFIRATaskNames
%Get task names for a FIRA and make task ID ecodes with full FIRA scope
%
%   taskNames = unifyFIRATaskNames
%
%   FIRA has a default ecode called "task_index".  These are unique within
%   a session but are meaningless across sessions.  unifyFIRATaskNames
%   resolves "task_index" values to string task names thereby making them
%   meaningfull across sessions.
%
%   This is mostly useful for concatenated FIRA structs that contain data
%   from multiple sessions.
%
%   uNames is a cell array of strings containing the unique list of
%   names of dXtask instances saved in the current FIRA.
%   unifyFIRATaskNames puts the same list in FIRA.allTaskNames.
%
%   tnID is an array of indices into uNames, one for each trial.  These
%   indices are unique task identifiers withing the scope of the current
%   FIRA.  unifyFIRATaskNames adds the same array to the current FIRA, as
%   an ecode called "taskNameID".
%
%   allNames is a cell array of strings containing the complete list of
%   task names for every single trial.  allNames = uNames(tnID).
%
%   See also concatenateFIRAs, findFIRASessionsAndBlocks

% Copyright 2008 Benjamin Heasly University of Pennsylvania
global FIRA

% how many sessions?
nH = length(FIRA.allHeaders);

% where is the "task_index" ?
eTask = strcmp(FIRA.ecodes.name, 'task_index');
ti = FIRA.ecodes.data(:,eTask);

% when task index is nan, replace with the previous trial's task index
%   also treat first trial and consecutive bad trials
bads = find(isnan(ti));
goods = find(~isnan(ti));
if ~isempty(bads)
    for bb = bads
        ti(bb) = ti(goods(find(goods<bb,1,'last')));
    end
end

% it's crazy, but go ahead and get a task name for each trial
%   it might be useful to someone
allNames = cell(1, length(ti));
for ii = 1:nH
    RS = FIRA.allHeaders(ii).session;
    if ~isempty(RS) && isfield(RS, 'dXtask')

        % get trials and task names for this header
        t = struct(RS.dXtask);
        sessNames = {t.name};
        jj = FIRA.allHeaders(ii).trialSelect;

        % deal out task names for each trial
        allNames(jj) = sessNames(ti(jj));
    end
end

% boil down the crazy list to a unique list and an array of indices
[uNames, first, tnID] = unique(allNames);
FIRA.allTaskNames = uNames;

%tnID is a pain in the ass, it should be a column, not a row
tnID = tnID';

% place indices list into ecodes
eID = strcmp(FIRA.ecodes.name, 'taskNameID');
if ~any(eID)

    % new kind of ecode
    eNew = length(FIRA.ecodes.name) + 1;
    FIRA.ecodes.name{eNew} = 'taskNameID';
    FIRA.ecodes.type{eNew} = 'id';
    FIRA.ecodes.data(:,eNew) = tnID;
else

    % replace existing ecode values
    FIRA.ecodes.data(:,eID) = tnID;
end