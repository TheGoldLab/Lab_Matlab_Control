function [f, axises] = RTByCoh(dir)
% show session-by-session and modalitywise wise progress of
%   RT distro at each coh and correct vs incorrect

if ~nargin
    dir = true;
end

% load data
clear global FIRA
concatenateFIRAs(dir);

% make new multisession ecodes, get basic summary data
global FIRA
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,30);
tids = unique(taskID);
nt = length(tids);
sessions = unique(sessionID)';
ns = length(sessions);

% performance data
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood) & ~isnan(blockNum));

% get "correct" ecode, or build it from responses
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

% I goofed one session
if any(strcmp(subjects, 'JIG'))
    correct = fixMissingCorrect;
end

eCoh = strcmp(FIRA.ecodes.name, 'Q65_used');
coh = FIRA.ecodes.data(:,eCoh);
cohs = [2.^(5:9)/10, 99];
nc = length(cohs);

% response timing data
%   SOON, GET RT FROM PMD AND ASL
eChoose = strcmp(FIRA.ecodes.name, 'choose');
eLeft = strcmp(FIRA.ecodes.name, 'left');
eRight = strcmp(FIRA.ecodes.name, 'right');
tChoose = FIRA.ecodes.data(:,eChoose);
tLeft = FIRA.ecodes.data(:,eLeft);
tRight = FIRA.ecodes.data(:,eRight);

RT = tChoose;
rTOK = ~isnan(tLeft) & tLeft > 0;
RT(rTOK) = tLeft(rTOK);
rTOK = ~isnan(tRight) & tRight > 0;
RT(rTOK) = tRight(rTOK);

% return figure to caller
f = figure(8974);
clf(f);

sAxis = [.7 sessions(end)+1];

% correct
axC = subplot(2,1,1, 'XLim', sAxis, 'XTick', sessions, 'Parent', f);
ylabel(axC, 'correct RT (ms)')
title(axC, subjects{1})

% incorrect
axI = subplot(2,1,2, 'XLim', sAxis, 'XTick', sessions, 'Parent', f);
ylabel(axI, 'incorrect RT (ms)')
xlabel(axI, 'session.coh')

% return all axes to caller
axises = [axC axI];

% get mean and var of RT in different conditions
N = nan*zeros(ns, nt, nc);
RTMeans = nan*zeros(ns, nt, nc, 2);
RTVars = nan*zeros(ns, nt, nc, 2);

for ss = sessions

    % select one session
    %   find its blocks
    sSelect = good & sessionID == ss;

    % look at each task separately
    for tt = tids

        % select one task/reponse mode
        tSelect = sSelect & taskID' == tt;

        % look at coherences and correct/incorrect separately
        for ii = 1:nc
            cSelect = tSelect & coh == cohs(ii);

            N(ss,tt,ii) = sum(cSelect);
            if N(ss,tt,ii)

                % correct and incorrect means
                RTMeans(ss,tt,ii,1) = mean(RT(cSelect&correct));
                RTMeans(ss,tt,ii,2) = mean(RT(cSelect&~correct));

                % correct and incorrect variances
                RTVars(ss,tt,ii,1) = var(RT(cSelect&correct));
                RTVars(ss,tt,ii,2) = var(RT(cSelect&~correct));
            end
        end
    end
end

% plot a line for each coherence
cla(axC)
cla(axI)
for ii = 1:nc
    x = sessions + (ii-1)/nc;

    % Eye correct/incorrect
    c = [.5 0 ii/nc];
    line(x, RTMeans(:,1,ii,1), 'Color', c, 'Parent', axC);
    line(x, RTMeans(:,1,ii,2), 'Color', c, 'Parent', axI);

    % Lever correct/incorrecr
    c = [0 ii/nc .5];
    line(x, RTMeans(:,2,ii,1), 'Color', c, 'Parent', axC);
    line(x, RTMeans(:,2,ii,2), 'Color', c, 'Parent', axI);
end