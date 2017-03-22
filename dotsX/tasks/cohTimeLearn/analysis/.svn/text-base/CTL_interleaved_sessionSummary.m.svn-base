%Summarize a session from the cohTimeLearn interleaved set of tasks
clear all
global FIRA ROOT_STRUCT

% get a data file (or even files)
concatenateFIRAs(false);
if isempty(FIRA)
    return
end

% get ROOT_STRUCT so tasks are accessible
ROOT_STRUCT = FIRA.allHeaders(1).session;

[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(2,2);
blocks = unique(blockNum(~isnan(blockNum)))';
numBlocks = length(blocks);

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eVT = strcmp(FIRA.ecodes.name, 'viewing_time');
VT = FIRA.ecodes.data(:,eVT);

VTs = rGetTaskByName('CohTimeLearn_interleaved_cohQuest', 'userData');
nVT = length(VTs);

eCoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
coherence = FIRA.ecodes.data(:,eCoherence);

cohs = rGetTaskByName('CohTimeLearn_interleaved_timeQuest', 'userData');
nCoh = length(cohs);

% axis limits
tAxis = [1 1000];
cAxis = [1 101];

f = figure(44000);
clf(f);
set(f, 'Name', subjects{1})

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

    % plot each block's 4 quest paths
    axTrials = subplot(2, numBlocks, bb, ...
        'XLim', gAxis([1,end]), 'Parent', f);
    xlabel(axTrials, 'trial#')

    % plot each block's speed-accuracy relationship
    axSA = subplot(2, numBlocks, bb+numBlocks, 'Parent', f, ...
        'YLim', cAxis([1,end]), 'YGrid', 'on', ...
        'XLim', tAxis([1,end]), 'XTick', VTs);
    xlabel(axSA, 'viewing time (ms)')
    switch allNames{find(gTrials,1)}

        case 'CohTimeLearn_interleaved_Practice'

            title(axTrials, 'interleaved practice (100%coh)')
            set(axTrials, 'YLim', [-.1 1.1], 'YTick', [0 1], ...
                'YTickLabel', {'incorrect', 'correct'});
            ylabel(axTrials, '')
            ylabel(axSA, '%correct')

            for ii = 1:nVT

                vtTrials = gTrials & (VT == VTs(ii));
                if ~any(vtTrials)
                    continue
                end

                col = dec2bin(ii,3)=='1';

                % show correct and incorrect
                line(find(vtTrials), correct(vtTrials), ...
                    'Color', col, 'Marker', '.', 'LineStyle', 'none', ...
                    'Parent', axTrials);

                % show speed vs accuracy
                line(VTs(ii), mean(correct(vtTrials))*100, ...
                    'Color', col, 'Marker', '*', 'LineStyle', 'none', ...
                    'Parent', axSA);
            end

        case 'CohTimeLearn_interleaved_cohQuest'

            title(axTrials, 'interleaved cohQuest');
            set(axTrials, 'YLim', cAxis([1,end]));
            ylabel(axTrials, '81% Thresh (%coh)')
            ylabel(axSA, '81% Thresh (%coh)')

            for ii = 1:nVT

                vtTrials = gTrials & (VT == VTs(ii));
                if ~any(vtTrials)
                    continue
                end

                col = dec2bin(ii,3)=='1';

                % show correct and incorrect
                line(find(vtTrials), coherence(vtTrials), ...
                    'Color', col, 'Marker', '.', 'LineStyle', 'none', ...
                    'Parent', axTrials)

                % show speed vs accuracy
                line(VTs(ii), coherence(find(vtTrials, 1, 'last')), ...
                    'Color', col, 'Marker', '*', 'LineStyle', 'none', ...
                    'Parent', axSA)
            end

        case 'CohTimeLearn_interleaved_timeQuest'

            title(axTrials, 'interleaved timeQuest');
            set(axTrials, 'YLim', tAxis([1,end]));
            ylabel(axTrials, '81% Thresh (ms)')
            ylabel(axSA, '81% Thresh (%coh)')

            for ii = 1:nCoh

                vtTrials = gTrials & (coherence == cohs(ii));
                if ~any(vtTrials)
                    continue
                end

                col = dec2bin(ii,3)=='1';

                % show correct and incorrect
                line(find(vtTrials), VT(vtTrials), ...
                    'Color', col, 'Marker', '.', 'LineStyle', 'none', ...
                    'Parent', axTrials)

                % show speed vs accuracy
                last = find(vtTrials, 1, 'last');
                line(VT(last), cohs(ii), ...
                    'Color', col, 'Marker', '*', 'LineStyle', 'none', ...
                    'Parent', axSA)
            end
    end
end