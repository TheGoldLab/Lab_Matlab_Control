% superimpose all the eye movements for a session of the response modality
% tasks

figure(1)
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

hide = logical(zeros(size(good)));
eHide = strcmp(FIRA.ecodes.name, 'hideStim');
eChoices = strcmp(FIRA.ecodes.name, 'choices');
hide(~isnan(FIRA.ecodes.data(:,eHide))) = true;
hide(~isnan(FIRA.ecodes.data(:,eChoices))) = true;


% get a ROOT_STRUCT with graphics info
clear global ROOT_STRUCT
global ROOT_STRUCT
ROOT_STRUCT = FIRA.allHeaders(1).session;
ROOT_STRUCT.screenMode = 0;
rGroup('gXmodality_dots');

% get screen dimensions in degrees visual angle
degRect = rGet('dXscreen', 1, 'screenRect') ...
    / rGet('dXscreen', 1, 'pixelsPerDegree');

% represent the stimulus monitor twice
%   for accepted and rejected eye responses
ax(1) = cla(subplot(2,1,1));
ax(2) = cla(subplot(2,1,2));
title(ax(1), 'rejected');
title(ax(2), 'accepted');
set(ax, ...
    'DataAspectRatio', [1 1 1], ...
    'Xlim', degRect(3)./[-2, 2], ...
    'YLim', degRect(4)./[-2, 2], ...
    'Color', rGet('dXscreen', 'bgColor'));

% who was this person?
set(gcf, 'Name', FIRA.allHeaders(1).subject);

% draw eye movements from eye task trials
%   find eye trials with successful fixation and stimulus viewing
%   color-code by successful response
eyeFixView = FIRA.ecodes.data(:,eTask)==738 & hide;
accepted = 0;
rejected = 0;
for t = find(eyeFixView)'

    % color-code eye trace by task and error
    goo = FIRA.ecodes.data(t, eGood);
    col = [~goo goo ~goo];

    % keep track of precentages
    accepted = accepted + goo;
    rejected = rejected + ~goo;

    xlabel(ax(goo+1), 'eye x-position')
    ylabel(ax(goo+1), 'eye y-position')
    eye = FIRA.aslData{t};
    if ~isempty(eye)
        line(eye(:,2), eye(:,3), ...1:size(eye,1), ...
            'Color', col, ...
            'LineStyle', '-', ...
            'Marker', 'none', ...
            'Tag', 'trace', ...
            'Parent', ax(goo+1));

        line(eye(end,2), eye(end,3), ...
            'Color', [0 0 1], ...
            'LineStyle', 'none', ...
            'Marker', '*', ...
            'MarkerSize', 10, ...
            'Tag', 'terminal', ...
            'Parent', ax(goo+1));
    end
end

% show some onscreen objects
ptrs = {{'dXdots', 1}, {'dXtarget', 1}, {'dXtarget', 2}, {'dXtarget', 3}};
for p = ptrs
    o = rGet(p{1}{:});
    x = o.x - o.diameter/2;
    y = o.y - o.diameter/2;
    for a = ax
        rectangle(  ...
            'Curvature',	[1,1], ...
            'EdgeColor',	o.color(1:3)/255, ...
            'LineStyle',	'-', ...
            'LineWidth',	2, ...
            'Position',     [x,y,o.diameter,o.diameter], ...
            'Parent',       a);

        if isfield(o, 'diameter2')
            x2 = o.x - o.diameter2/2;
            y2 = o.y - o.diameter2/2;
            rectangle(  ...
                'Curvature',	[0,0], ...
                'EdgeColor',	o.color(1:3)/255, ...
                'LineStyle',	'-', ...
                'LineWidth',	2, ...
                'Position',     [x2,y2,o.diameter2,o.diameter2], ...
                'Parent',       a);
        end

        % sort children so terminal buttons are on top
        traces = findobj(get(a, 'Children'), 'Tag', 'trace');
        terminals = findobj(get(a, 'Children'), 'Tag', 'terminal');
        others = findobj(get(a, 'Children'), 'Tag', '');
        set(a, 'Children', [terminals; others; traces;]);
    end
end

disp(sprintf('rejected %d accepted %d', rejected, accepted));