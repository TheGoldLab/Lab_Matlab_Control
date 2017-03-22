%Summarize a session from the cohTimeLearn set of tasks
clear all
global FIRA

% get a data file (or even files)
concatenateFIRAs(false);
if isempty(FIRA)
    return
end

[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(2,2);
blocks = unique(blockNum)';
numBlocks = max(blocks);
blockGroup = 4;

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eCohQuest81 = strcmp(FIRA.ecodes.name, 'cohQ81_used');
cohQuest81 = FIRA.ecodes.data(:,eCohQuest81);

eCohQuestVT = strcmp(FIRA.ecodes.name, 'coh_Quest_viewing_time');
cohQuestVT = FIRA.ecodes.data(:,eCohQuestVT);

eTimeQuest81 = strcmp(FIRA.ecodes.name, 'timeQ81_used');
timeQuest81 = FIRA.ecodes.data(:,eTimeQuest81);

eCoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
coherence = FIRA.ecodes.data(:,eCoherence);

% axis limits
tAxis = [10 1500];
cAxis = [1 100];

% figure for all Quest data
f = figure(55000);
clf(f);

% figure and axis for scatter of coh vs time
ff = figure(23890);
clf(ff);
axCT = axes('Parent', ff, 'XLim', tAxis, 'YLim', cAxis);
xlabel(axCT, 'viewing time (ms)')
ylabel(axCT, 'coherence (%)')
text(100, 90, 'cohQuest', 'Color', [1 0 0], 'Parent', axCT)
text(300, 90, 'timeQuest', 'Color', [0 0 1], 'Parent', axCT)

for bb = blocks

    % good trials in this block
    gTrials = good & (blockNum == bb);
    gAxis = find(gTrials);

    % get slightly real
    if isempty(gAxis)
        continue
    end

    % correct and incorrect good trials
    cTrials = gTrials & correct;
    iTrials = gTrials & ~correct;

    % plot each block/subtask
    ax = subplot(ceil(numBlocks/blockGroup), blockGroup, bb, ...
        'XLim', gAxis([1,end]), 'Parent', f);
    switch allNames{find(gTrials,1)}

        case 'CohTimeLearn_Practice'

            % setup axes for practice block
            title(ax, 'practice')
            set(ax, 'YLim', [-.1 1.1], 'YTick', [0 1], ...
                'YTickLabel', {'incorrect', 'correct'});

            % pick correct and incorrect practice trials
            blockData = correct;

        case 'CohTimeLearn_cohQuest'

            % setup axes for Coherence Quest training block
            vt = cohQuestVT(gAxis(1));
            title(ax, sprintf('cohQuest at %dms', vt));

            % put grid lines at min, and max
            blockCohs = cohQuest81(gTrials);
            ticks = [min(blockCohs), max(blockCohs)];
            set(ax, 'YLim', cAxis, 'YScale', 'log', ...
                'YTick', unique(ticks), 'YGrid', 'on');

            % label the final coherence
            text(gAxis(end)+1, blockCohs(end), sprintf('%.0f', blockCohs(end)), ...
                'Parent', ax);

            % pick coherence threshold/performance
            blockData = cohQuest81;

            % add to the coh-time scatter plot
            line(vt, blockCohs(end), 'Parent', axCT, ...
                'Marker', '*', 'Color', [1 0 0]);

        case 'CohTimeLearn_timeQuest'

            % setup axes for Time Quest training block
            coh = coherence(gAxis(1));
            title(ax, sprintf('timeQuest at %.0f%% coh', coh));

            % put grid lines at min, max, and end
            blockTimes = round(timeQuest81(gTrials));
            ticks = [min(blockTimes), max(blockTimes)];

            % put grid lines at min, and max
            set(ax, 'YLim', tAxis, 'YScale', 'log', ...
                'YTick', unique(ticks), 'YGrid', 'on');

            % label the final viewing time
            text(gAxis(end)+1, blockTimes(end), sprintf('%.0f', blockTimes(end)), ...
                'Parent', ax);

            % pick time threshold/performance
            blockData = timeQuest81;

            % add to the coh-time scatter plot
            line(blockTimes(end), coh, 'Parent', axCT, ...
                'Marker', '*', 'Color', [0 0 1]);

    end

    % plot the picked data
    line(find(cTrials), blockData(cTrials), 'Parent', ax, ...
        'Color', [0 1 0], 'LineStyle', 'none', 'Marker', '*');
    line(find(iTrials), blockData(iTrials), 'Parent', ax, ...
        'Color', [1 0 0], 'LineStyle', 'none', 'Marker', '*');
end