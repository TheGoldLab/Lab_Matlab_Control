% what was the effect of dot field diameter on my performance?

clear all
concatenateFIRAs(false);

% make new multisession ecodes, get basic summary data
global FIRA
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(50,30);

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood) & ~isnan(blockNum));

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eCoh = strcmp(FIRA.ecodes.name, 'dot_coh');
coh = FIRA.ecodes.data(:,eCoh);
cohs = unique(coh);
nc = length(cohs(~isnan(cohs)));

eDiam = strcmp(FIRA.ecodes.name, 'dot_diam');
diam = FIRA.ecodes.data(:,eDiam);
diams = unique(diam);
nd = length(diams(~isnan(diams)));

% response timing data
eLeft = strcmp(FIRA.ecodes.name, 'left');
eRight = strcmp(FIRA.ecodes.name, 'right');
tLeft = FIRA.ecodes.data(:,eLeft);
tRight = FIRA.ecodes.data(:,eRight);

RT = tLeft;
rTOK = ~isnan(tRight) & tRight > 0;
RT(rTOK) = tRight(rTOK);


% percent correct for each diam-coh condition
n = nan*zeros(nc, nd);
Pc = nan*zeros(nc, nd);
errPc = nan*zeros(nc, nd);
meanRT = nan*zeros(nc, nd);
errRT = nan*zeros(nc, nd);
for ii = 1:nc
    for jj = 1:nd
        sel = good & coh==cohs(ii) & diam==diams(jj);
        n(ii,jj) = sum(sel);
        Pc(ii,jj) = sum(correct(sel)) / n(ii,jj);
        errPc(ii,jj) = sqrt(var(correct(sel)) / n(ii,jj));
        meanRT(ii,jj) = mean(RT(sel));
        errRT(ii,jj) = sqrt(var(RT(sel)) / n(ii,jj));
    end
end

f = figure(564);
clf(f);
axPc = subplot(2,1,1, 'Parent', f, ...
    'XLim', [0, diams(end)*1.5], 'XTick', diams, ...
    'YLim', [.5 1]);
title(axPc, subjects{1})
ylabel(axPc, 'P_c')

axRT = subplot(2,1,2, 'Parent', f, ...
    'XLim', [0, diams(end)*1.5], 'XTick', diams);
ylabel(axRT, 'RT (ms)')
xlabel(axRT, 'dot diameter (deg vis ang)')
for ii = 1:nc
    col = dec2bin(ii,3)=='1';
    % mean Pc +/- stErr
    line(diams, Pc(ii,:)+errPc(ii,:), 'Parent', axPc, ...
        'Color', col, 'LineStyle', ':');
    line(diams, Pc(ii,:)-errPc(ii,:), 'Parent', axPc, ...
        'Color', col, 'LineStyle', ':');
    line(diams, Pc(ii,:), 'Parent', axPc, 'Color', col, 'LineWidth', 2);

    % mean RT +/- stErr
    line(diams, meanRT(ii,:)+errRT(ii,:), 'Parent', axRT, ...
        'Color', col, 'LineStyle', ':');
    line(diams, meanRT(ii,:)-errRT(ii,:), 'Parent', axRT, ...
        'Color', col, 'LineStyle', ':');
    line(diams, meanRT(ii,:), 'Parent', axRT, 'Color', col, 'LineWidth', 2);


    % keys
    text(diams(end)+1, Pc(ii,end), sprintf('%.1f%%',cohs(ii)), ...
        'Color', col, 'Parent', axPc);
    text(diams(end)+1, meanRT(ii,end), sprintf('%.1f%%',cohs(ii)), ...
        'Color', col, 'Parent', axRT);
end