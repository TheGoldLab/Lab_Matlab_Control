% Look at data from the initial blocks of the fine discrimination task, do
% a weibull fit, and pick the 65% correct coherence.
%
% Lump eye and lever trials together so that all trials in the future use
% the same coherence.

% load data
clear all
concatenateFIRAs(false);

% avoid annoying errors
global FIRA
if isempty(FIRA)
    f = nan;
    axises = nan;
    return
end

% make new multisession ecodes, get basic summary data
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(20,20);
sessions = unique(sessionID)';

% the goal is a particular threshold
targetPc = .65;

% basic accounting
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood));

eTrialNum = strcmp(FIRA.ecodes.name, 'trial_num');
trialNum = FIRA.ecodes.data(:,eTrialNum);

eCoh = strcmp(FIRA.ecodes.name, 'Q92_used');
coh = FIRA.ecodes.data(:,eCoh);
cohs = unique(coh(~isnan(coh)));

f = figure(321);
clf(f);

axW = axes('XLim', [1 100], 'XTick', cohs, 'XScale', 'log', ...
    'YLim', [0 1]);
title(axW, subjects{1})
ylabel(axW, 'Pc')
xlabel(axW, 'coherence')

% show percent correct at each coherence
for ii = 1:length(cohs)
    select = good & coh == cohs(ii);
    n(ii) = sum(select);
    Pc(ii) = sum(correct(select))/n(ii);
end
line(cohs, Pc, 'LineStyle', 'none', 'Marker', '*', 'Parent', axW);

% fit a Weibull
WeibCon = [80 1 100; 2 2 2; 0.01 0.01 0.3; 0.5 0.5 0.5];
PFD = [cohs, Pc', n'];
WQ = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), [], [], WeibCon);

% draw a smooth Weibull
allCoh = linspace(1, 100, 1000);
allPc = linearWeibull(allCoh, WQ);
line(allCoh, allPc, 'LineStyle', '-', 'Marker', 'none', 'Parent', axW);

% locate the threshold of interest
targetCoh = allCoh(find(allPc >= targetPc, 1, 'first'));
line([1,1]*targetCoh, [0,targetPc], 'Color', [1 0 0], 'Parent', axW)
line([1,targetCoh], [1,1]*targetPc, 'Color', [1 0 0], 'Parent', axW)
text(sqrt(targetCoh), targetPc+.02, sprintf('Pc = %0.2f', targetPc), ...
    'Color', [1 0 0], 'Parent', axW)
text(targetCoh*1.05, targetPc/2, sprintf('%2.0f%% coh', targetCoh), ...
    'Color', [1 0 0], 'Parent', axW)