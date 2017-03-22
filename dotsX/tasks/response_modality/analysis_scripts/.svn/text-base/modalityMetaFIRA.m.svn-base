function modalityMetaFIRA(qn, getDir)
% Given files selected in a gui, transform interesting response modality
% task data into ecodes that span sessions in a meaningful way.  Prefix
% ecode names with "oc_", for "offline calculation".
%
% Add these ecodes to the metaFIRA:
%
%   These might depend on session-specific things (e.g. ecode names):
%   oc_response     0=left or down, 1=right or up, 2=both
%   oc_latency      response latency in ms
%   oc_date         datenum() of session
%   oc_taskID       silly integer unique task ID
%
%   These should be general across the union of all sessions:
%   oc_converged    nan = never, num = OK
%   oc_blockNum     block number from withing a session
%   oc_thresh       posterior estimate of threshold
%   oc_threshLB     lower bound of thresh estimate
%   oc_threshUB     upper bound of thresh estimate
%
% Also add
%   FIRA.globalTaskID   struct with taskname field names for task ID lookup
%   FIRA.allHeaders     array of header substructs from all subFIRAs
%   FIRA.datesString    datestr() string spanning session dates

% possibly get a whole dir instead of individual file
if nargin < 2
    getDir = false;
end

global FIRA
if isempty(FIRA)
    if exist('/Volumes/XServerData')
        suggestion = ...
            '/Volumes/XServerData/Psychophysics/response_modality';
    else
        suggestion = '/Users/lab';
    end

    if islogical(getDir) && getDir
        pth = uigetdir(suggestion, 'Pick a subject directory');
        d = dir(pth);
        % find .mat files that start with "R"
        for n = 1:length(d)
            dataFiles(n) = ~isempty(strfind(d(n).name, '.mat')) & ...
                ~isempty(strncmp(d(n).name, 'R', 1));
        end
        file = {d(dataFiles).name};
    elseif ischar(getDir) && ~isempty(getDir)
        pth = getDir;
        d = dir(pth);
        % find .mat files that start with "R"
        for n = 1:length(d)
            dataFiles(n) = ~isempty(strfind(d(n).name, '.mat')) & ...
                ~isempty(strncmp(d(n).name, 'R', 1));
        end
        file = {d(dataFiles).name};
    else
        [file, pth, filteri] = ...
            uigetfile({'*.mat'},'Load one or more FIRA files', ...
            [suggestion, '/*'], 'MultiSelect', 'on');
    end

    % get real
    if isempty(file) || isnumeric(file)
        return
    elseif ischar(file)
        file = {file};
    end
    for f = file
        disp(sprintf('getting %s', f{1}));
        DUMP = load(fullfile(pth, f{1}));
        appendMetaFIRA(DUMP);
    end
    FIRA.header.flags = 'metafied';
elseif ~strcmp(FIRA.header.flags, 'metafied')
    % use an existing FIRA, like right after a session
    DUMP.FIRA = FIRA;
    FIRA = [];
    appendMetaFIRA(DUMP);
    FIRA.header.flags = 'metafied';
end

% grand total of trials
nt = size(FIRA.ecodes.data, 1);
FIRA.header.numTrials = nt;

% find block numbers within each session===day
%   and find whether Quest converged
%   nan = never converged
%   100 = didn't converge, but OK
%   num = converged after num trials

% use one dXquest instance...which one?
if ~nargin || ~isnumeric(qn) || qn<1 || qn>3
    qn = 2;
end

c = nan*ones(nt,1);
b = nan*ones(nt,1);
th = nan*ones(nt,1);
thub = nan*ones(nt,1);
thlb = nan*ones(nt,1);

eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dat = FIRA.ecodes.data(:,eDate);
dates = unique(dat);
day = floor(FIRA.ecodes.data(:,eDate));
days = unique(day);
for dd = 1:length(days)
    thisSession = find(day==days(dd));
    tn = FIRA.ecodes.data(thisSession,eTrial);
    nts = length(thisSession);
    taskStart = [0; find(diff(tn) < 0); nts]+1;

    bn = 1;
    for bb = 1:length(taskStart)-1

        % isolate blocks
        block = thisSession(taskStart(bb):taskStart(bb+1)-1);

        % If any Quest got a good estimate,
        %   consider this a full block
        qb = FIRA.QUESTData{block(end)};
        converged = [qb.convergedAfter];
        if tn(taskStart(bb+1)-1) > 20

            % got at least 90 trials, === good estimate
            c(block) = deal(tn(taskStart(bb+1)-1));

            % mark the block number
            b(block) = deal(bn);
            bn = bn+1;
        elseif any(~isnan(converged))

            % take the first convergence as authoritative
            c(block) = deal(min(converged));

            % mark the block number
            b(block) = deal(bn);
            bn = bn+1;
        end
    end

    % get a *date* index from the *day*
    %  and access a corresponding dXquest instance
    dt = find(dates>days(dd),1);
    q = struct(FIRA.allHeaders(dt).session.classes.dXquest.objects(qn));

    thOffset = q.psychParams(1);
    ref = q.refValue;
    refExp = q.refExponent;

    % for every damn trial, get the posterior thresh, ub and lb
    for ts = 1:length(thisSession)
        qts = FIRA.QUESTData{thisSession(ts)};
        qt = qts(qn);

        % coh = 10^(dB/refExp)*ref;
        if ~isnan(qt.CIdB)
            th(thisSession(ts)) = ...
                10^((qt.estimateLikedB+thOffset)/refExp)*ref;
            thub(thisSession(ts)) = 10^((qt.CIdB(1)+thOffset)/refExp)*ref;
            thlb(thisSession(ts)) = 10^((qt.CIdB(2)+thOffset)/refExp)*ref;

            % th(thisSession(ts)) = qt.estimateLikedB+thOffset;
            % thub(thisSession(ts)) = qt.CIdB(1)+thOffset;
            % thlb(thisSession(ts)) = qt.CIdB(2)+thOffset;

        end
    end
end

% manually append ecodes (there are no new trials)
newNames = {'oc_converged', 'oc_blockNum', ...
    'oc_thresh', 'oc_threshLB', 'oc_threshUB'};

FIRA.ecodes.name = cat(2, FIRA.ecodes.name, newNames);
FIRA.ecodes.data = cat(2, FIRA.ecodes.data, [c, b, th, thub, thlb]);

function appendMetaFIRA(DUMP)

% code for responses:
%   0=left or down, 1=right or up, 2=both (both replaces left or right)
r = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);
eLeft = strcmp(DUMP.FIRA.ecodes.name, 'left');
eDown = strcmp(DUMP.FIRA.ecodes.name, 'down');
eRight = strcmp(DUMP.FIRA.ecodes.name, 'right');
eUp = strcmp(DUMP.FIRA.ecodes.name, 'up');
eBoth = strcmp(DUMP.FIRA.ecodes.name, 'both');
r(~isnan(DUMP.FIRA.ecodes.data(:,eLeft))) = 0;
r(~isnan(DUMP.FIRA.ecodes.data(:,eRight))) = 1;
r(~isnan(DUMP.FIRA.ecodes.data(:,eDown))) = 0;
r(~isnan(DUMP.FIRA.ecodes.data(:,eUp))) = 1;
r(~isnan(DUMP.FIRA.ecodes.data(:,eBoth))) = 2;

% get response latencies from ecodes
l = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);

% % the lever task was saving some of the wrong states to FIRA,
% %   so we must use stim onset rather than offset time.
% eshow = strcmp(DUMP.FIRA.ecodes.name, 'showStim');

% try to get latency from response cue time
eChoices = strcmp(DUMP.FIRA.ecodes.name, 'choices');
if sum(eChoices) == 1
    l = min(DUMP.FIRA.ecodes.data(:,eLeft|eDown|eRight|eUp)')' ...
        - DUMP.FIRA.ecodes.data(:,eChoices);
else
    disp([DUMP.FIRA.header.filename, ' missing stim onset ecode'])
end

% store session dates as datenums.  Highly redundant.
d = datenum(DUMP.FIRA.header.date)*ones(size(DUMP.FIRA.ecodes.data, 1), 1);

% task names are to big to hash into one double.  So make an arbitrary
% table and store it in the metaFIRA
cellery = { ...
    737,	'taskModalityLever', ...
    738,	'taskModalityEye', ...
    -7337,	'ignored'};
gtid = cell2struct(cellery(1:2:end), cellery(2:2:end), 2);

% convert session-specific task indices to global IDs
eTask = strcmp(DUMP.FIRA.ecodes.name, 'task_index');
t = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);

names = logical(zeros(size(DUMP.FIRA.header.paradigm.taskList)));
for ii = 1:length(DUMP.FIRA.header.paradigm.taskList)
    names(ii) = ischar(DUMP.FIRA.header.paradigm.taskList{ii});
end
tNames = DUMP.FIRA.header.paradigm.taskList(names);

for ti = 1:length(tNames)

    thisTask = DUMP.FIRA.ecodes.data(:,eTask) == ti;
    tn = tNames{ti};

    % ignore incomplete sessions
    if sum(thisTask) >= 30;
        if ~strncmp(tn, 'task', 4);
            disp([DUMP.FIRA.header.filename, ...
                ' has a stupid task name'])
            tn = ['task', tn];
        end
        t(thisTask) = gtid.(tn);

    else
        disp(sprintf('%s ignoring incomplete %s (%d trials)', ...
            DUMP.FIRA.header.filename, tn, sum(thisTask)))
    end
end

% add all these juicy ecodes to the metaFIRA ecodes
eNames = cat(2, DUMP.FIRA.ecodes.name, { ...
    'oc_response', 'oc_latency', 'oc_date', 'oc_taskID'});
eTypes = cat(2, DUMP.FIRA.ecodes.type, ...
    {'value', 'value', 'value', 'value'});
eData = cat(2, DUMP.FIRA.ecodes.data, r, l, d, t);
buildFIRA_addTrial('add', 'ecodes', {eData, eNames, eTypes});

% concatenate headers and formatted "Data"
global FIRA a
FIRA.globalTaskID = gtid;

% get names of all "Data" fields
fn = fieldnames(DUMP.FIRA);
iData = find(cell2num(strfind(fn, 'Data')))';

if isfield(FIRA, 'allHeaders')
    FIRA.allHeaders = [FIRA.allHeaders, DUMP.FIRA.header];
    if ~isempty(iData)
        for ii = iData
            FIRA.(fn{ii}) = [FIRA.(fn{ii}); DUMP.FIRA.(fn{ii})];
        end
    end
else
    FIRA.allHeaders = DUMP.FIRA.header;
    if ~isempty(iData)
        for ii = iData
            FIRA.(fn{ii}) = DUMP.FIRA.(fn{ii});
        end
    end
end

% summarize dates
eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dates = unique(FIRA.ecodes.data(:, eDate));
FIRA.datesString = sprintf('%s-%s', ...
    datestr(min(dates), 2), datestr(max(dates), 2));