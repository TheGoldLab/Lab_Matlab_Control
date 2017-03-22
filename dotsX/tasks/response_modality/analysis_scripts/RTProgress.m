function [f, axises] = RTProgress(dr)
% show session-by-session and blockwise progress of
%   Weibull threshold
%   Overall Mean RT
%   ddm sensitivity, k
%   ddm bound height, A'
%   ddm residual time, tR

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
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,30);
sessions = unique(sessionID)';

% get common data structure, d
d = getCommonDataTypes(subjects, blockNum, sessionID);
cohs = [2.^(5:9)/10, 99];
nc = length(cohs);

% constraints on model fitting

% Weibull
% guess, min, max, on Weibull alpha, beta, lambda, gamma
WeibCon = [80 1 100; 1 .1 5; 0.01 0.01 0.05; 0.5 0.5 0.5];

% confidence interval for Weibull fitting
citype = {100, 68};
citype = [];

% return figure to caller
f = figure(5459);
clf(f);

% show percentage of good trials
sAxis = [.7 sessions(end)+1];

np = 5;
axG = subplot(np,1,1, 'XLim', sAxis, 'XTick', sessions, ...
    'YLim', [0, 100]);
ylabel(axG, '% good trials')
title(axG, subjects{1})

% show block thresholds
axTh = subplot(np,1,2, 'XLim', sAxis, 'XTick', sessions, ...
    'YLim', [1, 100], 'YScale', 'log', 'YTIck', cohs, 'YGrid', 'on');
ylabel(axTh, 'Weibull Thresh')

% show fit ddm k
axK = subplot(np,1,3, 'XLim', sAxis, 'XTick', sessions, 'YGrid', 'on');
ylabel(axK, 'ddm sensitivity, k')

% show fit ddm A
axA = subplot(np,1,4, 'XLim', sAxis, 'XTick', sessions, 'YGrid', 'on');
ylabel(axA, 'ddm bound A''')

% show raw mean and fit residual RT
axRT = subplot(np,1,5, 'XLim', sAxis, 'XTick', sessions, ...
    'YLim', [0, 2], 'YGrid', 'on');
ylabel(axRT, 'mean RT (+) and residual tR (.)')
xlabel(axRT, 'session.block')

% return all axises to caller
axises = [axG, axTh, axRT, axK, axA];

for ss = sessions

    drawnow

    % select one session
    %   find its blocks
    sSelect = d.good & sessionID == ss;
    block = blockNum(sSelect);
    blocks = unique(block)';

    % get grand session accuracy and time
    s_n         = sum(sSelect);
    s_pC        = sum(d.correct(sSelect)) / s_n;
    s_meanRT    = mean(d.RT(sSelect));
    s_stdRT     = std(d.RT(sSelect));

    % get session accuracy and time by coherence
    sc_n         = nan*zeros(1, nc);
    sc_pC        = nan*zeros(1, nc);
    sc_meanRT    = nan*zeros(1, nc);
    sc_stdRT     = nan*zeros(1, nc);
    for ii = 1:nc
        cSelect = sSelect & d.coh == cohs(ii);
        sc_n(ii)       = sum(cSelect);
        sc_pC(ii)      = sum(d.correct(cSelect)) / sc_n(ii);
        sc_meanRT(ii)  = mean(d.RT(cSelect));
        sc_stdRT(ii)   = std(d.RT(cSelect));
    end

    % fit Weibull to session accuracy
    % fir ddRT to accuracy and speed
    z = sc_n~=0;
    if any(z)
        PFD = [cohs(z)', sc_pC(z)', sc_n(z)'];
        [WQ, varWQ] = ...
            ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), [], citype, WeibCon);

        % package data from this set
        DDD = [d.coh(sSelect), d.correct(sSelect), d.RT(sSelect)];
        
        % get reasonable start values and bounds for ddm parameters
        Qinit = [ddRT_initial_params(DDD), ddRT_bound_params];

        [ddQ, varddQ] = ddRT_fit(@ddRT_psycho_nll, ...
            @ddRT_chrono_nll_from_fano, DDD, Qinit);
    end

    % show percentage of good trials
    c = [0 1 0];
    line(ss, 100*mean(d.good(sessionID == ss)), ...
        'Marker', '.', 'LineStyle', 'none', 'Color', c, 'Parent', axG);

    % plot Weibull thresh (with error bars)
    line(ss, WQ(1), 'Marker', '+', 'LineStyle', 'none', ...
        'Color', c, 'Parent', axTh);
    if ~isempty(citype)
        line([ss ss], varWQ(1,:), 'Marker', 'none', 'LineStyle', '-', ...
            'Color', c, 'Parent', axTh);
    end

    % plot mean RT +/- std
    line(ss, s_meanRT, 'Marker', '+', 'LineStyle', 'none', ...
        'Color', c, 'Parent', axRT);
    line([ss ss], s_meanRT + s_stdRT*[1 -1], 'Marker', 'none', ...
        'LineStyle', '-', 'Color', c, 'Parent', axRT);

    % plot ddRT parameters
    line(ss, ddQ(1), 'Marker', '+', 'LineStyle', 'none', ...
        'Color', c, 'Parent', axK);
    line(ss, ddQ(3), 'Marker', '+', 'LineStyle', 'none', ...
        'Color', c, 'Parent', axA);
    line(ss, ddQ(6), 'Marker', '.', 'LineStyle', 'none', ...
        'Color', c, 'Parent', axRT);

    for bb = blocks

        % select one block
        bSelect = sSelect & blockNum == bb;

        % which task was this block
        tID = taskID(find(bSelect, 1));

        % get grand block accuracy and time
        b_n         = sum(bSelect);
        b_pC        = sum(d.correct(bSelect)) / b_n;
        b_meanRT    = mean(d.RT(bSelect));
        b_stdRT     = std(d.RT(bSelect));

        % get block accuracy and time by coherence
        bc_n         = nan*zeros(1, nc);
        bc_pC        = nan*zeros(1, nc);
        bc_meanRT    = nan*zeros(1, nc);
        bc_stdRT     = nan*zeros(1, nc);
        for ii = 1:nc
            cSelect = bSelect & d.coh == cohs(ii);
            bc_n(ii)       = sum(cSelect);
            bc_pC(ii)      = sum(d.correct(cSelect)) / bc_n(ii);
            bc_meanRT(ii)  = mean(d.RT(cSelect));
            bc_stdRT(ii)   = std(d.RT(cSelect));
        end

        % fit Weibull to block accuracy
        z = bc_n~=0;
        if any(z)
            PFD = [cohs(z)', bc_pC(z)', bc_n(z)'];
            [WQ, varWQ] = ...
                ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), [], citype, WeibCon);

            % package data from this set
            DDD = [d.coh(bSelect), d.correct(bSelect), d.RT(bSelect)];

            % get reasonable start values and bounds for ddm parameters
            Qinit = [ddRT_initial_params(DDD), ddRT_bound_params];

            [ddQ, varddQ] = ddRT_fit(@ddRT_psycho_nll, ...
                @ddRT_chrono_nll_from_fano, DDD, Qinit);
        end

        % show percentage of good trials
        x = ss+bb/10;
        c = [tID==1, 0, tID==2];
        line(x, 100*mean(d.good(sessionID == ss & blockNum == bb)), ...
            'Marker', '.', 'LineStyle', 'none', 'Color', c, 'Parent', axG);

        % plot Weibull thresh (with error bars)
        line(x, WQ(1), 'Marker', '+', 'LineStyle', 'none', ...
            'Color', c, 'Parent', axTh);
        if ~isempty(citype)
            line([x x], varWQ(1,:), 'Marker', 'none', 'LineStyle', '-', ...
                'Color', c, 'Parent', axTh);
        end

        % plot mean RT +/- std
        line(x, b_meanRT, 'Marker', '+', 'LineStyle', 'none', ...
            'Color', c, 'Parent', axRT);
        line([x x], b_meanRT + b_stdRT*[1 -1], 'Marker', 'none', ...
            'LineStyle', '-', 'Color', c, 'Parent', axRT);

        % plot ddRT parameters
        line(x, ddQ(1), 'Marker', '+', 'LineStyle', 'none', ...
            'Color', c, 'Parent', axK);
        line(x, ddQ(3), 'Marker', '+', 'LineStyle', 'none', ...
            'Color', c, 'Parent', axA);
        line(x, ddQ(6), 'Marker', '.', 'LineStyle', 'none', ...
            'Color', c, 'Parent', axRT);

    end
end