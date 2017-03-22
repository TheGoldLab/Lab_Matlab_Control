function [f, axises] = RTOverview(dr)
% show session-by-session and taskwise progress of
%   accuracy threshold
%   mean RT and residual time
%   sensitivity
%   bound height

if ~nargin
    dr = true;
end

% load data
clear global FIRA
concatenateFIRAs(dr);

% avoid annoying errors
global FIRA
if isempty(FIRA)
    f = nan;
    axises = nan;
    return
end

% make new multisession ecodes, get basic summary data
[taskNames, taskID, allNames] = unifyFIRATaskNames;
tasks = unique(taskID)';

[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,30);
sessions = unique(sessionID)';
sAxis = [.7 sessions(end)+1];

% get common data structure, d
d = getCommonDataTypes(subjects, blockNum, sessionID);
cohs = unique(d.coh(d.good));

% get a grand fit of ddRT parameters for over all sessions,
%   for each modality
[Qgrand, varQgrand] = getGrandddRTFit(d, taskID, sessionID);

% return figure to caller
f = figure(990);
clf(f);

% accuracy threshold
np = 4;
axTh = subplot(np,1,1, 'XLim', sAxis, 'XTick', sessions, ...
    'YLim', [1, 100], 'YTick', cohs, 'YMinorTick', 'off', ...
    'YScale', 'log', 'YGrid', 'on');
ylabel(axTh, '82Pc (%coh)')
title(axTh, subjects{1})

% RT threshold and residual time
axRT = subplot(np,1,2, 'XLim', sAxis, 'XTick', sessions, ...
    'YLim', [0, 1.5], 'YGrid', 'on');
ylabel(axRT, 't_R(+), E[RT](X) (sec)')

% sensitivity
axK = subplot(np,1,3, 'XLim', sAxis, 'XTick', sessions, ...
    'YScale', 'log', 'YGrid', 'on');
ylabel(axK, 'k')

% bound height
axA = subplot(np,1,4, 'XLim', sAxis, 'XTick', sessions, 'YGrid', 'on');
ylabel(axA, 'A'' (sqrt-sec)')
xlabel(axA, 'session.task')

% return all axises to caller
axises = [axTh, axRT, axK, axA];

for ss = sessions

    % select one session
    sSelect = d.good & sessionID == ss;

    for tt = tasks

        % select one task
        tSelect = sSelect & taskID == tt;

        % package data from this set
        data = [d.coh(tSelect), d.correct(tSelect), d.RT(tSelect)];

        % get reasonable start values and bounds for ddm parameters
        Qinit = [ddRT_initial_params(data), ddRT_bound_params];
        
        % fix the residual time to the grand residual time
        Qinit(6,:) = Qgrand(6,tt);

        % fit the ddRT parameters
        [Qfit, varddQ] = ddRT_fit(...
            @ddRT_psycho_nll, @ddRT_chrono_nll_from_pred, ...
            data, Qinit);

        % halfway thresholds
        ThPc = .758 / (Qfit(1)*Qfit(3));
        %ThPc = .55 / (Qfit(1)*Qfit(3));
        ThRT = 1.92 / (Qfit(1)*Qfit(3));
        mRT = mean(d.RT(tSelect));

        x = ss + .2*tt;
        c = [tt==1, 0 tt==2];
        s = [(tt==mode(taskID(sSelect))) + 1] * 6;
        setup = {'Color', c, 'MarkerSize', s};
        line(x, ThPc,       'Marker', '+', setup{:}, 'Parent', axTh);
        line(x, mRT,        'Marker', 'X', setup{:}, 'Parent', axRT);
        line(x, Qfit(6),    'Marker', '+', setup{:}, 'Parent', axRT);
        line(x, Qfit(1),    'Marker', '+', setup{:}, 'Parent', axK);
        line(x, Qfit(3),    'Marker', '+', setup{:}, 'Parent', axA);
    end
end

% delimit epochs
for ax = axises
    for ee = d.epochs
        line([1,1]*ee, get(ax, 'YLim'), 'LineWidth', 2, ...
            'Color', [1 1 1]*.5, 'Parent', ax)
    end
end

% label epochs
for ee = d.epochs
    info = sprintf('%s ', d.epochInfo{ee}{:});
    text(ee+.1, cohs(end)*.9, info, 'Parent', axTh);
end