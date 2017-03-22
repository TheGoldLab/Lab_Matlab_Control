function threshANOVA
% use ANOVA to see whether/which block(s) in each session is significantly
% different from the others

qn = 2;

clear global FIRA
modalityMetaFIRA(qn)

f = figure(521);
clf(f);
set(f, 'DefaultTextFontSize', 9);

global FIRA

eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
nt = FIRA.header.numTrials;
tn = FIRA.ecodes.data(:,eTrial);

eTask = strcmp(FIRA.ecodes.name, 'oc_taskID');
taskStart = [0; find(diff(tn) < 0); nt]+1;
tid = FIRA.ecodes.data(:, eTask);

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
B = length(blocks);

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

% get coh as recorded by low quest
eCoh = strcmp(FIRA.ecodes.name, 'dot_coh_low_used');
coh = FIRA.ecodes.data(:,eCoh);

% bin coherences
edges = (.5:1:100);
centers = edges(2:end)-edges(2)/2;
lapseCoh = 90;

% how many sessions?
nd = length(days);
allDay = 1:nd;
dayLim = [.9,nd+1];

% initial values and boundaries for weibull fitting
shape = 1.5;
lamb = 0.01;
bot = 0.5;
fitCon = [ ...
    80      10      110;	... % thresh
    shape   shape   shape;	... % shape
    lamb    lamb    lamb;	... % lapse
    bot     bot     bot];       % lower asymptote

% confidence interval and repetitions for Weibull fit bootstrapping
ci = 95;
ciN = 100;

% pick an alpha level for anova test
alpha = .005;

% Show threshtimates
thAxArgs = {...
    'YLim', [10, 100], 'YScale', 'log', ...
    'XLim', dayLim, 'XTick', allDay};

% show sesson-relative f-scores for thresh estimates
fAxArgs = {...
    'YLim', [.1, 10], 'YScale', 'log', ...
    'XLim', dayLim, 'XTick', allDay};

% from QUEST
thAxQ = subplot(6,1,1, thAxArgs{:});
title(thAxQ, FIRA.allHeaders(1).subject(2:end))
ylabel(thAxQ, 'Quest thresh (+/- 95%)')

fAxQ = subplot(6,1,4, fAxArgs{:});
ylabel(fAxQ, 'Quest relative F')

% from bootstrap
%   either numeric, or peek at underlying distribution
thAxB = subplot(6,1,2, thAxArgs{:});
ylabel(thAxB, 'Bootstrap thresh (+/- 95%)')

fAxB = subplot(6,1,5, fAxArgs{:});
ylabel(fAxB, 'Bootstrap relative F')

% from Hessian?
thAxH = subplot(6,1,3, thAxArgs{:});
ylabel(thAxH, 'Hessian thresh (+/- 68%)')

fAxH = subplot(6,1,6, fAxArgs{:});
ylabel(fAxH, 'Hessian relative F')
xlabel(fAxH, 'session number')

for d = 1:length(days)

    % pick out one day
    daySelect = dat>days(d) & dat<days(d)+1;

    % find the blocks
    dayBlock = FIRA.ecodes.data(daySelect,eBlock);
    dayBlocks = unique(dayBlock(~isnan(dayBlock)));

    % gather stats for anova
    ns = nan*ones(1,B);
    Qmeans = nan*ones(1,B);
    Qwidths = nan*ones(1,B);
    Bmeans = nan*ones(1,B);
    Bwidths = nan*ones(1,B);
    Hmeans = nan*ones(1,B);
    Hwidths = nan*ones(1,B);

    for b = 1:dayBlocks(end)

        % pick out one block
        blockSelect = block == b & daySelect;
        x = (d+b/10);

        if any(blockSelect)

            % begining and end trials of block
            s = find(blockSelect, 1, 'first');
            n = find(blockSelect, 1, 'last');

            % number of good trials this block
            ns(b) = sum(good&blockSelect);

            % color code by task
            colour = [tid(s)==738 0 tid(s)==737];

            % fill in stats for anova
            Qmeans(b) = Th(n);
            Qwidths(b) = Thub(n) - Thlb(n);

            % Show each final thresh estimate with QUEST chi-square error
            %   offset each block by arbitrary amount
            line(x, Th(n), 'Parent', thAxQ, ...
                'Marker', '+', 'Color', colour);
            line([1,1]*x, [Thlb(n), Thub(n)], 'Parent', thAxQ, ...
                'Marker', 'none', 'Color', colour);

            % make a dummy mark on the F axis, with proper color
            Qfline(b) = line(x, 1, 'Parent', fAxQ, ...
                'Marker', '+', 'Color', colour);

            % calculate performance in each bin, for this block
            Pc = nan*ones(size(centers));
            n = nan*ones(size(centers));
            for ii = 1:length(centers)
                stimSelect = coh >= edges(ii) & coh < edges(ii+1) ...
                    & blockSelect & good;
                n(ii) = sum(stimSelect);
                Pc(ii) = sum(correct & stimSelect)/n(ii);
            end

            % calculate lapse rate for this block
            highSelect = coh >= lapseCoh & blockSelect & good;
            highN = sum(highSelect);
            if highN
                highP = sum(correct & highSelect)/highN;
                lapse = 1-highP;
            else
                lapse = lamb;
            end
            fitCon(3,:) = lapse;

            % do fresh Weibull fits for this block
            z = n~=0;
            if any(z)
                PFD = [centers(z)', Pc(z)', n(z)'];

                % with bootstrap confidence intervals
                [fit, bootCI] = ...
                    ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), ...
                    {ciN, ci}, fitCon);

                % fill in stats for anova
                Bmeans(b) = fit(1);
                Bwidths(b) = bootCI(1,2) - bootCI(1,1);

                line(x, fit(1), 'Parent', thAxB, ...
                    'Marker', '+', 'Color', colour);
                line([1,1]*x, bootCI(1,[1,2]),'Parent', thAxB, ...
                    'Marker', 'none', 'Color', colour);

                % make a dummy mark on the F axis, with proper color
                Bfline(b) = line(x, 1, 'Parent', fAxB, ...
                    'Marker', '+', 'Color', colour);

                % with Hessian confidence intervals
                % with bootstrap confidence intervals
                [fit, hessCI] = ...
                    ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), ...
                    [], fitCon);

                % fill in stats for anova
                Hmeans(b) = fit(1);
                Hwidths(b) = hessCI(1);

                range = max(fit(1)+hessCI(1)*[.5 -.5], 1);
                line(x, fit(1), 'Parent', thAxH, ...
                    'Marker', '+', 'Color', colour);
                line([1,1]*x, range, 'Parent', thAxH, ...
                    'Marker', 'none', 'Color', colour);

                % make a dummy mark on the F axis, with proper color
                Hfline(b) = line(x, 1, 'Parent', fAxH, ...
                    'Marker', '+', 'Color', colour);

            end
        end
    end

    % plot ANOVA for this day's Quest
    QCI = .95;
    z = ~isnan(Qmeans);
    plotAnova(Qmeans(z), Qwidths(z), ns(z), QCI, alpha, d, ...
        thAxQ, fAxQ, Qfline)

    % plot ANOVA for this day's Bootstrapping
    z = ~isnan(Bmeans);
    plotAnova(Bmeans(z), Bwidths(z), ns(z), ci/100, alpha, d, ...
        thAxB, fAxB, Bfline)

    % plot ANOVA for this day's Hessian
    z = ~isnan(Hmeans);
    plotAnova(Hmeans(z), Hwidths(z), ns(z), 68/100, alpha, d, ...
        thAxH, fAxH, Hfline)

end

% repeat plotting for different kinds of error bars
function plotAnova(means, ciWidths, ns, ci, alpha, d, thAx, fAx, flines)

% number of blocks
k = length(means);

% where to plot for this day:
%   between d and x
x = d+(k+1)/10;

% do the 1 n-way comparison
[FStat, signif] = benova(means, ciWidths, ns, ci);
if signif > 1-alpha
    line([d,x], [1,1], ...
        'Parent', fAx, 'Color', [0 0 0])
end

% show the Fstat for the n-way comparison
text(x, 1, sprintf('%.0f', FStat), 'Parent', fAx)

% do the n (n-1)-way comparisons
[FStats, signifs] = dropAnova(means, ciWidths, ns, ci);
accept = signifs < 1-alpha;
if any(accept)
    line(d+find(accept)/10, means(accept), ...
        'Parent', thAx, 'Color', [0 0 0], ...
        'Marker', 'x', 'MarkerSize', 16, ...
        'LineStyle', 'none');
end

% show the relative Fstats for each of the (n-1)-way comparisons
for ii = 1:k
    set(flines(ii), 'YData', FStats(ii)/FStat)
end

% do some anova in the way I think will work
function [fstat, signif] = benova(means, widths, ns, CI)
% Calculate F = (SSB/DFB)/(SSE/DSE):
% Report whether F > F(1-alpha), the critical value for rejecting the
% hypothesis that all means are the same.

% assume means, widths, and ns have same lenght, k
k = length(means);

% SSB and DFB are easy
%   sum of deviations of each mean from the mean mean
%   assume same N for all means
meanMean = mean(means);
SSB = sum(ns.*(means - meanMean).^2);
DFB = k-1;
MSB = SSB/DFB;

% Skip SSE and go striaght to MSE.
%   Assume CI width refers to a gaussian,
%   so CI% indicates some Z-score
%   and width can be converted to an estimate of sigma
Z = erfinv(CI)*sqrt(2);
sigs = widths/(2*Z);
MSE = sum(sigs.^2)/k;

% Now assume DFE comes from the number of trials that led to each mean.
%   As long as number of trials is large, and we're after non-crazy
%   significance (say, .05-.005), we don't have to know DFE exactly.
DFE = sum(ns)-length(means);

% how certainly could we reject the null hypothesis?
fstat = MSB/MSE;
signif = fcdf(fstat, DFB, DFE);

% do same anova with dropouts
function [fstats, signifs] = dropAnova(means, widths, ns, CI)
% rejects is a logical array where each element says whether the ANOVA null
% hypothesis was rejected when the iith block was left out

k = length(means);
s = logical(ones(1,k));
signifs = zeros(1,k);
fstats = zeros(1,k);
for ii = 1:k
    s(ii) = false;
    [fstats(ii), signifs(ii)] = benova(means(s), widths(s), ns(s), CI);
    s(ii) = true;
end