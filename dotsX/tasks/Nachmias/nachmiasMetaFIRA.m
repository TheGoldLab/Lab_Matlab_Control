function nachmiasMetaFIRA
% Given files selected in a gui, transform interesting Nachmias task data
% into ecodes that span sessions in a meaningful way.  Prefix ecode names
% with "oc_", for "offline calculation.
%
% Add these ecodes to the metaFIRA:
%   oc_contrast     as Webber Contrast
%   oc_sincoh       signed dot coherence fraction
%   oc_response     0=left, 1=right, 2=both
%   oc_latency      response latency in ms
%   oc_date         datenum() of session
%   oc_taskID       silly integer unique task ID
%
% Also add
%   FIRA.globalTaskID   struct with taskname field names for task ID lookup
%   FIRA.allHeaders     array of header substructs from all subFIRAs
%   FIRA.datesString    datestr() string spanning session dates

global FIRA
if isempty(FIRA)
    if exist('/Volumes/XServerData')
        suggestion = ...
            '/Volumes/XServerData/Psychophysics/Gold-Nachmias/*';
    else
        suggestion = '/Users/lab/*';
    end
    [file, pth, filteri] = ...
        uigetfile({'*.mat'},'Load one or more FIRA files', ...
        suggestion, 'MultiSelect', 'on');

    % get real
    if isempty(file) || isnumeric(file)
        return
    elseif ischar(file)
        file = {file};
    end
    for f = file
        appendMetaFIRA(fix_FIRA_with_svn(pth, f{1}));
    end
    FIRA.header.flags = 'metafied';
elseif ~strcmp(FIRA.header.flags, 'metafied')
    % use an existing FIRA, like right after a session
    DUMP.FIRA = FIRA;
    FIRA = [];
    appendMetaFIRA(DUMP);
    FIRA.header.flags = 'metafied';
end

function appendMetaFIRA(DUMP)
% resolve contrast values stored as task-specific indices
c = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);
eCont = strcmp(DUMP.FIRA.ecodes.name, 'texture_index');
if any(eCont)

    % any contrast trials?
    cTrials = ~isnan(DUMP.FIRA.ecodes.data(:, eCont));

    % get dXtexture properties
    texture_book = ...
        struct(DUMP.FIRA.header.session.classes.dXtexture.objects);
    texture_book = [texture_book.fields];

    % check if contrast is Webber, by "lum", or
    %   modelfest, by "contrast"
    max_lums = [texture_book.lum];
    bg_lum = texture_book(1).bgLum;

    if length(unique(max_lums)) > 1
        max_lums = [texture_book.lum];
        % convert max lums to Webber contrasts
        c(cTrials) = ((max_lums( ...
            DUMP.FIRA.ecodes.data(cTrials, eCont))-bg_lum)/bg_lum);
    else
        all_con = [texture_book.contrast];
        % modelfest contrast *is* Webber contrast when g_max is 255
        c(cTrials) = ...
            all_con(DUMP.FIRA.ecodes.data(cTrials, eCont));
    end
end

% I don't know why there are effed up values like 2e-16 in there.  I'm
% rounding that crap off to the nearest 1000th
c = fix(c*1000)/1000;

% get all signed coherences
sc = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);
eCoh = strcmp(DUMP.FIRA.ecodes.name, 'dot_coh');
eDir = strcmp(DUMP.FIRA.ecodes.name, 'dot_dir');
dTrials = ~isnan(DUMP.FIRA.ecodes.data(:, eCoh));
sc(dTrials) = DUMP.FIRA.ecodes.data(dTrials, eCoh) ...
    .* cosd(DUMP.FIRA.ecodes.data(dTrials, eDir));
sc = reshape(sc, [], 1)/100;

% code for responses:
%   0=left, 1=right, 2=both (both replaces left or right)
r = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);
eLeft = strcmp(DUMP.FIRA.ecodes.name, 'left');
eRight = strcmp(DUMP.FIRA.ecodes.name, 'right');
eBoth = strcmp(DUMP.FIRA.ecodes.name, 'both');
r(~isnan(DUMP.FIRA.ecodes.data(:,eLeft))) = 0;
r(~isnan(DUMP.FIRA.ecodes.data(:,eRight))) = 1;
r(~isnan(DUMP.FIRA.ecodes.data(:,eBoth))) = 2;

% get response latencies
l = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);

% get latencies from lpHID data or ecodes
if isfield(DUMP.FIRA, 'lpHIDData') && ~isempty(DUMP.FIRA.lpHIDData)

    for ii = 1:size(DUMP.FIRA.ecodes.data,1)
        lp = DUMP.FIRA.lpHIDData{ii};
        if ~isempty(lp)
            pullEnd = lp(:,2)==1 & (lp(:,1)==1 | lp(:,1)==3);
            if any(pullEnd)
                l(ii) = min(lp(pullEnd, 3));
            end
        end
    end

else

    disp([DUMP.FIRA.header.filename, ' using ecodes for latencies'])

    % %   prefer to use 'hideStim' state as reference
    % %   may have to hack with another state for older sessions
    eLeft = strcmp(DUMP.FIRA.ecodes.name, 'left');
    eRight = strcmp(DUMP.FIRA.ecodes.name, 'right');
    eHide = strcmp(DUMP.FIRA.ecodes.name, 'hideStim');
    eShow = strcmp(DUMP.FIRA.ecodes.name, 'nextStim');
    eBeg = strcmp(DUMP.FIRA.ecodes.name, 'trial_begin');
    if sum(eHide) == 1
        l = min(DUMP.FIRA.ecodes.data(:,eLeft|eRight)')' ...
            - DUMP.FIRA.ecodes.data(:,eHide);
    elseif sum(eShow) == 1
        % there is no stim off time, so use the stium on time and
        % discount the nominal 200ms show time
        l = min(DUMP.FIRA.ecodes.data(:,eLeft|eRight)')' ...
            - DUMP.FIRA.ecodes.data(:,eShow) - 200;
    elseif sum(eBeg) == 1
        % there is not any stim timing info
        % use the trial begining and discount a second (rough)
        l = min(DUMP.FIRA.ecodes.data(:,eLeft|eRight)')' ...
            - DUMP.FIRA.ecodes.data(:,eBeg) - 1000;
    end
end

% store session dates as datenums.  Highly redundant.
d = datenum(DUMP.FIRA.header.date)*ones(size(DUMP.FIRA.ecodes.data, 1), 1);

% task names are to big to hash into one double.  So make an arbitrary
% table and store it in the metaFIRA
cellery = { ...
    22378008,   'taskDetectDownContrast', ...
    22378009,   'taskDetectUpContrast', ...
    22378010,   'taskDiscrim2afcContrast', ...
    22378011,   'taskDiscrim3afcContrast', ...
    32007,      'taskDetectLDots', ...
    32008,      'taskDetectRDots', ...
    32009,      'taskDiscrim2afcDots', ...
    32010,      'taskDiscrim3afcDots', ...
    -7337,      'ignored'};
gtid = cell2struct(cellery(1:2:end), cellery(2:2:end), 2);

% convert session-specific task indices to global IDs
eTask = strcmp(DUMP.FIRA.ecodes.name, 'task_index');
t = nan*ones(size(DUMP.FIRA.ecodes.data, 1), 1);
for ti = 1:length(DUMP.FIRA.header.paradigm.taskList)
    thisTask = DUMP.FIRA.ecodes.data(:,eTask) == ti;
    tn = DUMP.FIRA.header.paradigm.taskList{ti};

    % ignore incomplete sessions
    if sum(thisTask) >= 100
        if ~strncmp(tn, 'task', 4);
            disp([DUMP.FIRA.header.filename, ...
                ' has a stupid task name'])
            tn = ['task', tn];
        end
        t(thisTask) = gtid.(tn);

        if sum(thisTask) < 120
            disp(sprintf('%s is short on %s (%d trials)', ...
                DUMP.FIRA.header.filename, tn, sum(thisTask)))
        end
    else
        disp(sprintf('%s ignoring incomplete %s (%d trials)', ...
            DUMP.FIRA.header.filename, tn, sum(thisTask)))
    end
end

% add all these juicy ecodes to the metaFIRA ecodes
eNames = cat(2, DUMP.FIRA.ecodes.name, {'oc_contrast', 'oc_sincoh', ...
    'oc_response', 'oc_latency', 'oc_date', 'oc_taskID'});
eTypes = cat(2, DUMP.FIRA.ecodes.type, ...
    {'value', 'value', 'value', 'value', 'value', 'value'});
eData = cat(2, DUMP.FIRA.ecodes.data, c, sc, r, l, d, t);
buildFIRA_addTrial('add', 'ecodes', {eData, eNames, eTypes});

% suppliment metaFIRA with other data
global FIRA
FIRA.globalTaskID = gtid;
if isfield(FIRA, 'allHeaders')
    FIRA.allHeaders = [FIRA.allHeaders, DUMP.FIRA.header];
else
    FIRA.allHeaders = DUMP.FIRA.header;
end

eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dates = unique(FIRA.ecodes.data(:, eDate));

% useful summary of dates
FIRA.datesString = sprintf('%s-%s', ...
    datestr(min(dates), 2), datestr(max(dates), 2));