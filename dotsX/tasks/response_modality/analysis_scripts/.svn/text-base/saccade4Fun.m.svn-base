function saccade4Fun
% superimpose all the eye movements for a session of the response modality
% tasks

figure
clear global FIRA

% make a FIRA from alotta data files
qn = 2;
modalityMetaFIRA(qn)
global FIRA

eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
nt = FIRA.header.numTrials;
tn = FIRA.ecodes.data(:,eTrial);

eTask = strcmp(FIRA.ecodes.name, 'oc_taskID');
taskStart = [0; find(diff(tn) < 0); nt]+1;

eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dat = FIRA.ecodes.data(:,eDate);
dats = unique(dat);
day = floor(FIRA.ecodes.data(:,eDate));
days = unique(day);

eBlock = strcmp(FIRA.ecodes.name, 'oc_blockNum');
block = FIRA.ecodes.data(:,eBlock);
blocks = unique(block(~isnan(block)));

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

% get a ROOT_STRUCT with graphics info
clear global ROOT_STRUCT
global ROOT_STRUCT
ROOT_STRUCT = FIRA.allHeaders(1).session;
ROOT_STRUCT.screenMode = 0;
rGroup('gXmodality_dots');

% get screen dimensions in degrees visual angle
degRect = rGet('dXscreen', 1, 'screenRect') ...
    / rGet('dXscreen', 1, 'pixelsPerDegree');

% represent the stimulus monitor
ax = cla(gca);
set(ax, ...
    'DataAspectRatio', [1 1 1], ...
    'Xlim', degRect(3)./[-2, 2], ...
    'YLim', degRect(4)./[-2, 2], ...
    'Color', rGet('dXscreen', 'bgColor')/512 + .5);
title(ax, FIRA.allHeaders(1).subject);

% draw eye movements from eye task trials
for t = find(FIRA.ecodes.data(:,eTask)==738)'

    % color-code eye trace by task and error
    goo = FIRA.ecodes.data(t, eGood);
    col = [0 1 0].*goo;

    xlabel(ax, 'eye x-position')
    ylabel(ax, 'eye y-position')
    eye = FIRA.aslData{t};
    if ~isempty(eye)
        line(eye(:,2), eye(:,3), ...
            'Color', col, 'Parent', ax);
    end
end

% draw eye movements from lever task trials
%   which should be smaller movements
for t = find(FIRA.ecodes.data(:,eTask)==737)'

    % color-code eye trace by task and error
    goo = FIRA.ecodes.data(t, eGood);
    col = [0 0 1].*goo;

    xlabel(ax, 'eye x-position')
    ylabel(ax, 'eye y-position')
    eye = FIRA.aslData{t};
    if ~isempty(eye)
        line(eye(:,2), eye(:,3), ...
            'Color', col, 'Parent', ax);
    end
end

% show some onscreen objects
ptrs = {{'dXdots', 1}, {'dXtarget', 1}, {'dXtarget', 2}, {'dXtarget', 3}};
for p = ptrs
    c = rGet(p{1}{:}, 'color');
    d = rGet(p{1}{:}, 'diameter');
    x = rGet(p{1}{:}, 'x') - d/2;
    y = rGet(p{1}{:}, 'y') - d/2;    
    rectangle(  ...
        'Curvature',	[1,1], ...
        'EdgeColor',	c(1:3)/255, ...
        'LineStyle',	'-', ...
        'LineWidth',	2, ...
        'Position',     [x,y,d,d], ...
        'Parent',       ax);
end