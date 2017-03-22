function [sessionID, blockNum, days, subjects, times] = findFIRASessionsAndBlocks(sessMin, blockMin)
%Locate sessions and blocks within the current FIRA
%
%   [sessionID, blockNum, days, subjects, times] = ...
%       findFIRASessionsAndBlocks(sessMin, blockMin)
%
%   findFIRASessionsAndBlocks identifies unique experiment sessions in the
%   current FIRA, and blocks within each session.  A session is a group of
%   trials from the same subject on the same day.  A block is a group of
%   trials within a session with monotonically increasing trial numbers.
%
%   sessMin and blockMin are the minimum numbers of trials that may
%   constitute a valid session or block.  Groups of trials that are too
%   small will be ignored.  Defaults are sessMin = 20 and blockMin = 20.
%
%   sessionID is an array of session identification numbers, one for each
%   trial.  findFIRASessionsAndBlocks adds this same array to the current
%   FIRA as an ecode called "sessionID".
%
%   blockNum is an array of block identification numbers, one for each
%   trial.  findFIRASessionsAndBlocks adds this same array to the current
%   FIRA as an ecode called "blockNum".  Block numbers repeat each session.
%
%   days is a cell array of strings representing the unique set of days
%   on which sessions occured.  findFIRASessionsAndBlocks adds this same
%   cell array to FIRA.allDays.
%
%   subjects is a cell array of strings representing the unique set of
%   subjects who participated in sessions.  findFIRASessionsAndBlocks adds
%   this same cell array to FIRA.allSubjects.
%
%   sessionID can index days and subjects, and
%   length(subjects) = length(days) = max(sessionID).
%
%   See also concatenateFIRAs, unifyFIRATaskNames

% Copyright 2008 by Benjamin Heasly at University of Pennsylvania
global FIRA

% locate the default ecode, "trial_num"
eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
trials = FIRA.ecodes.data(:,eTrial);

% treat a single, ordinary FIRA or a big FIRA made with concatenateFIRAs
if isfield(FIRA, 'allHeaders')

    % this is a concatenated FIRA set
    %   locate the sessions as same subject and same day
    %   a session might span more than one ordinary FIRA
    %   an ordinary FIRA cannot span more than one session
    subAll = {FIRA.allHeaders.subject};
    subD = diff(sum(double(char(subAll)),2)) ~= 0;

    dateVAll = datevec({FIRA.allHeaders.date});
    timeAll = dateVAll(:,4) + dateVAll(:,5)/60;
    dateVAll(:,4:6) = 0;
    dayD = diff(datenum(dateVAll)) ~= 0;

    % group headers into sessions
    breaks = find(subD | dayD);
    starts = [1; breaks+1];
    ends = [breaks; length(FIRA.allHeaders)];
    ns = length(starts);

    sessionID = nan*ones(size(trials));
    blockNum = nan*ones(size(trials));
    days = {};
    subjects = {};
    times = [];
    ID = 1;
    for ii = 1:ns

        % select trials from same day and subject
        hh = starts(ii):ends(ii);
        tt = cat(1,FIRA.allHeaders(hh).trialSelect);

        % tag each header with it's session ID
        [FIRA.allHeaders(hh).sessionID] = deal(ID);

        % are there enough trials to constitute a session?
        if length(tt) >= sessMin
            sessionID(tt) = ID;
            blockNum(tt) = findSessionBlocks(trials(tt), blockMin);
            days{ID} = datestr(dateVAll(hh(1),:), 29);
            times(ID) = timeAll(hh(1));
            subjects(ID) = subAll(hh(1));
            ID = ID + 1;
        end
    end
else

    % this is an ordinary FIRA
    %   therefore it is worth exactly one session
    sessionID = ones(size(trials));
    blockNum = findSessionBlocks(trials, blockMin);
    days = {datestr(FIRA.header.date, 29)};
    subjects = {FIRA.header.subject};
end

% add days and subjects to FIRA
FIRA.allDays = days;
FIRA.allSubjects = subjects;

% add sessions to FIRA
sessID = strcmp(FIRA.ecodes.name, 'sessionID');
if any(sessID)

    % replace existing ecode values
    FIRA.ecodes.data(:,sessID) = sessionID;

else

    % new kind of ecode
    eNew = length(FIRA.ecodes.name) + 1;
    FIRA.ecodes.name{eNew} = 'sessionID';
    FIRA.ecodes.type{eNew} = 'id';
    FIRA.ecodes.data(:,eNew) = sessionID;
end

% add blocks to FIRA
blockN = strcmp(FIRA.ecodes.name, 'blockNum');
if any(blockN)

    % replace existing ecode values
    FIRA.ecodes.data(:,blockN) = blockNum;
else

    % new kind of ecode
    eNew = length(FIRA.ecodes.name) + 1;
    FIRA.ecodes.name{eNew} = 'blockNum';
    FIRA.ecodes.type{eNew} = 'id';
    FIRA.ecodes.data(:,eNew) = blockNum;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %  %   %     %        %             %                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function b = findSessionBlocks(t, m)
% find blocks, obey minimum size
breaks = find(diff(t)<0);
starts = [1; breaks+1];
ends = [breaks; length(t)];

b = nan*ones(size(t));
n = 1;
for ii = 1:length(starts)
    if t(ends(ii)) - t(starts(ii)) >= m
        b(starts(ii):ends(ii)) = n;
        n = n+1;
    end
end