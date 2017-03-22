function d = getCommonDataTypes(subjects, blockNum, sessionID)
% I always get the same data for all my scripts.  So get it here and return
% the structure d with all those data types.

global FIRA d

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
d.good = FIRA.ecodes.data(:,eGood) & ~isnan(blockNum) & ~isnan(sessionID);

% choices
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
d.correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

% I goofed one session
if any(strcmp(subjects, 'JIG'))
    d.correct = fixMissingCorrect;
end

% coherence
eCoh = strcmp(FIRA.ecodes.name, 'Q65_used');
d.coh = FIRA.ecodes.data(:,eCoh);

% stim onset
eShow = strcmp(FIRA.ecodes.name, 'showStim');
d.showStim = FIRA.ecodes.data(:,eShow);

% responses
eRight = strcmp(FIRA.ecodes.name, 'right');
d.right = FIRA.ecodes.data(:,eRight)/1000;
eLeft = strcmp(FIRA.ecodes.name, 'left');
d.left = FIRA.ecodes.data(:,eLeft)/1000;
eUp = strcmp(FIRA.ecodes.name, 'up');
d.up = FIRA.ecodes.data(:,eUp)/1000;
eDown = strcmp(FIRA.ecodes.name, 'down');
d.down = FIRA.ecodes.data(:,eDown)/1000;

% rough reaction time
%   in seconds, not miliseconds
eChoose = strcmp(FIRA.ecodes.name, 'choose');
d.choose = FIRA.ecodes.data(:,eChoose)/1000;
d.RT = nan*ones(length(d.choose), 1);
OK = ~isnan(d.right) & d.right~=0;
OK
d.RT(OK) = d.right(OK);
OK = ~isnan(d.left) & d.left~=0;
d.RT(OK) = d.left(OK);

% scan for dot parameter changes
paramNames = {'diam', 'x', 'y', 'dens', 'dir'};

headID = [FIRA.allHeaders.sessionID];
ns = max(headID);
d.epochInfo = cell(1, ns);
news = logical(zeros(1, ns));
for ID = 2:ns
    
    % find one header for this session
    %   get dots properties from dXremote struct
    hh = find(headID==ID,1);
    remote = struct(FIRA.allHeaders(hh).session.dXdots);
    dots(ID) = remote.fields;

    % scan a handful of dots parameters
    new = [ ...
        diff([dots(ID-1:ID).diameter]) ~= 0, ...
        diff([dots(ID-1:ID).x]) ~= 0, ...
        diff([dots(ID-1:ID).y]) ~= 0, ...
        diff([dots(ID-1:ID).density]) ~= 0, ...
        diff(sind([dots(ID-1:ID).direction]-45)==0) ~= 0];

    % summarize
    news(ID) = any(new);
    d.epochInfo{ID} = paramNames(new);
end
d.epochInfo{1} = {'start'};
d.epochs = [1, find(news)];