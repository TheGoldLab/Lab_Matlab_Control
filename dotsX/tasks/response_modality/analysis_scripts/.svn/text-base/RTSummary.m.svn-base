% show summary of sampling scheme, psychometric performance, and RT for the
% response modality RT tasks

% load data
clear all
concatenateFIRAs;

% constraints on Weibull fitting
% guess, min, max, on Weibull alpha, beta, lambda, gamma
fitCon = [50 1 100; 1 .1 10; 0.01 0.01 0.01; 0.5 0.5 0.5];

% make new multisession ecodes, get basic summary data
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,50);
allTrial = 1:length(blockNum);
global FIRA

% performance data
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood));

eCoh = strcmp(FIRA.ecodes.name, 'Q65_used');
coh = FIRA.ecodes.data(:,eCoh);
cohs = [2.^(5:9)/10, 99];

% response timing data
eChoose = strcmp(FIRA.ecodes.name, 'choose');
eLeft = strcmp(FIRA.ecodes.name, 'left');
eRight = strcmp(FIRA.ecodes.name, 'right');
tChoose = FIRA.ecodes.data(:,eChoose);
tLeft = FIRA.ecodes.data(:,eLeft);
tRight = FIRA.ecodes.data(:,eRight);

% get rough response times from state entry times
%   SOON, GET RT FROM PMD AND ASL
roughResponseTime = tChoose;
rTOK = ~isnan(tLeft) & tLeft > 0;
roughResponseTime(rTOK) = tLeft(rTOK);
rTOK = ~isnan(tRight) & tRight > 0;
roughResponseTime(rTOK) = tRight(rTOK);

% organize performance data
times = 0:50:1500;
hScale = 3;
for ii = 1:length(cohs)
    cohSelect = good & coh == cohs(ii);

    % coherence performance
    n(ii) = sum(cohSelect);
    p(ii) = sum(correct & cohSelect)/n(ii);

    % reaction time
    rt(ii) = nanmean(roughResponseTime(cohSelect));
    rh(:,ii) = histc(roughResponseTime(cohSelect), times);
    rhMod(:,ii) = cohs(ii) - rh(:,ii)*hScale/max(rh(:,ii));
end

z = n~=0;
if any(z)
    PFD = [cohs(z)', p(z)', n(z)'];
    fit = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), [], [], fitCon);
end

f = figure(432);
clf(f);

% show distribution of coherences
axCoh = subplot(3,1,1, 'XLim', [0 100], 'YLim', [0, max(n)*1.5]);
stem(cohs, n, 'Marker', '*', 'Parent', axCoh);
ylabel(axCoh, 'n')

% show percent correct
%   with fit
axP = subplot(3,1,2, 'XLim', [0 100], 'YLim', [0 1]);
line(cohs, p, 'LineStyle', 'none', 'Marker', '*', 'Parent', axP);

x = 1:100;
y = linearWeibull(x, fit);
line(x, y, 'LineStyle', '-', 'Marker', 'none', ...
    'Color', [1 0 0], 'Parent', axP);
text(60, 0.5, sprintf('alpha = %.0f, beta = %.1f', fit(1), fit(2)), ...
    'Color', [1 0 0], 'Parent', axP);
ylabel(axP, 'p')

% show reaction time mean and hist
axRT = subplot(3,1,3, 'XLim', [0 100], 'YLim', [0, max(times)]);
line(rhMod, repmat(times',1,6), 'Color', [0 1 1], 'Parent', axRT);
line(cohs, rt, 'Marker', '*', 'Parent', axRT)
xlabel(axRT, 'coherence')
ylabel(axRT, 'rt (ms)')
grid(axRT, 'on')