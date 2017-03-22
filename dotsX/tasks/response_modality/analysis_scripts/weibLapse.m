% plot psychometric functions for each block
%   focus on high-coherence presentations and lapse rate

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

% get coh as recorded by low quest
eCoh = strcmp(FIRA.ecodes.name, 'dot_coh_low_used');
coh = FIRA.ecodes.data(:,eCoh);

figure
ax = cla(gca);
dayPlus = 0;
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
            %disp(sprintf('%d %d %.4f %d %.4f', num, numgd, gd, numcr, cr))

            % which task was it?
            tid = FIRA.ecodes.data(s, eTask);
            col = [tid==738 0 tid==737];

            % show superimposed stimulus histograms
            edges = 0:5:100;
            centers = edges(2:end)-edges(2)/2;
            h = hist(coh(blockSelect), centers);
            xlabel('distribution of coherences', ...
                'Parent', subplot(2,1,1));
            line(centers, h, ...
                'Color', col, 'Parent', subplot(2,1,1))
            
            uCoh = unique(coh(blockSelect));
            Pc = nan*ones(size(uCoh));
            n = nan*ones(size(uCoh));
            for ii = 1:length(uCoh)
                sel = coh==uCoh(ii)&good;
                n(ii) = sum(sel);
                Pc(ii) = sum(correct(sel))/n(ii);
            end

            % show performance each block
            xlabel('performance', ...
                'Parent', subplot(2,1,2));
            line(uCoh, Pc, 'Color', col, 'Parent', subplot(2,1,2));
        end
    end
    dayPlus = dayPlus + dayBlocks(end);
end

set(subplot(2,1,1), 'XLim', edges([1,end]), 'XTick', edges);

% who?
title(subplot(2,1,1), FIRA.allHeaders(1).subject)