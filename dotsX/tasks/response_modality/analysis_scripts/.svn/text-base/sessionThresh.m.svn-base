% plot the thresholds multiple sessions of response modality tasks

clear global FIRA

% which of three quest instances to examine?
qn = 2;
modalityMetaFIRA(qn)
global FIRA

eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
nt = FIRA.header.numTrials;
tn = FIRA.ecodes.data(:,eTrial);

eTask = strcmp(FIRA.ecodes.name, 'oc_taskID');
taskStart = [0; find(diff(tn) < 0); nt]+1;

eTh = strcmp(FIRA.ecodes.name, 'oc_thresh');
eThub = strcmp(FIRA.ecodes.name, 'oc_threshUB');
eThlb = strcmp(FIRA.ecodes.name, 'oc_threshLB');
Thub = FIRA.ecodes.data(:,eThub);
Th = FIRA.ecodes.data(:,eTh);
Thlb = FIRA.ecodes.data(:,eThlb);

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

figure
ax = cla(gca);
dayPlus = 0;
finalThresh = [];
for d = 1:length(days)

    % pick out one day and find the blocks
    daySelect = dat>days(d) & dat<days(d)+1;
    dayBlock = FIRA.ecodes.data(daySelect,eBlock);
    dayBlocks = unique(dayBlock(~isnan(dayBlock)));

    if mod(d, 2)
        mark = '+';
    else
        mark = 'o';
    end

    for b = 1:dayBlocks(end)

        % pick out one block
        blockSelect = find(block == b & daySelect);

        if ~isempty(blockSelect)
            s = blockSelect(1);
            n = blockSelect(end);

            num = length(blockSelect);
            numgd = nansum(good(blockSelect));
            gd = numgd/num;
            numcr = nansum(correct(blockSelect));
            cr = numcr/numgd;
            disp(sprintf('%d %d %.4f %d %.4f', num, numgd, gd, numcr, cr))

            % which task was it?
            tid = FIRA.ecodes.data(s, eTask);
            col = [tid==738 0 tid==737];

            % show superimposed evolutions of threshold
            xlabel('posterior threshold estimates by trial', ...
                'Parent', subplot(2,1,1))
            line(1:length(blockSelect), Th(blockSelect), ...
                'Color', col, 'Parent', subplot(2,1,1));

            % show each final thresh estimate with QUEST chi-square error
            xlabel('final posterior threshold estimates by block', ...
                'Parent', subplot(2,1,2))
            line([1,1,1]*(b+dayPlus), [Thlb(n), Th(n), Thub(n)], ...
                'Marker', mark, 'Color', col, 'Parent', subplot(2,1,2))
            finalThresh = cat(1, finalThresh, [Thlb(n), Th(n), Thub(n)]);
        end
    end
    dayPlus = dayPlus + dayBlocks(end);
end

% always same scale for final thresholds
set(subplot(2,1,2), 'YLim', [0 150], 'YScale', 'log')

% who?
title(subplot(2,1,1), FIRA.allHeaders(1).subject)

% figure(7)
% line(1:length(Th), Th, 'Color', [qn==1, qn==2, qn==3])