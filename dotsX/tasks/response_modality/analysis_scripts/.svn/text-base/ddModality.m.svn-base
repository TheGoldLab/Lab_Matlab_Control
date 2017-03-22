% fit the drift diffusion model for response modality RT task data
%   break down by modality across all sessions
%   show fit params across sessions

clear all
concatenateFIRAs

global FIRA
[tasks, taskID, allNames] = unifyFIRATaskNames;
tIDs = unique(taskID);
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,50);
allTrial = find(~isnan(sessionID) & ~isnan(blockNum));

d = getCommonDataTypes(subjects, blockNum, sessionID);
cohs = unique(d.coh(~isnan(d.coh)))';

% psycho and chrono for each coherence and task
nt = length(tIDs);
nc = length(cohs);
n = nan*zeros(nt,nc);
Pc = nan*zeros(nt,nc);
rTc = nan*zeros(nt,nc);
for ii = 1:nt
    taskSelect = d.good & taskID' == tIDs(ii);
    for jj = 1:nc
        taskCohSelect = taskSelect & d.coh == cohs(jj);
        n(ii,jj) = sum(taskCohSelect);
        Pc(ii,jj) = sum(d.correct(taskCohSelect))/n(ii,jj);
        rTc(ii,jj) = mean(d.RT(d.correct&taskCohSelect));
    end
end

figure(362)
clf
axRT = subplot(2,1,1, 'Xlim', [0,100], 'XScale', 'log', ...
    'YLim', [0 max(rTc(1:numel(rTc)))*1.25]);
ylabel('RTc (ms)');
title(subjects{1})
line(cohs, rTc, 'LineStyle', 'none', 'Marker', '*', 'Parent', axRT);

axP = subplot(2,1,2, 'Xlim', [0,100], 'XScale', 'log', ...
    'YLim', [0 1]);
ylabel('Pc');
xlabel('coherence');
line(cohs, Pc, 'LineStyle', 'none', 'Marker', '*', 'Parent', axP);

legend(axP, tasks{:}, 'Location', 'NorthWest')