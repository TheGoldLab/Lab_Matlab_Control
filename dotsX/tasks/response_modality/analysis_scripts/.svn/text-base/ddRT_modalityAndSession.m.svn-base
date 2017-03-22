function [f, axises] = ddRT_modalityAndSession(dr)
% Show ddRT psychometric and chronometric fits for each session.
%   Plot modalitites separately.

if ~nargin
    dr = true;
end

% get data
clear global FIRA
concatenateFIRAs(dr);

% avoid annoying errors
global FIRA
if isempty(FIRA)
    f = nan;
    axises = nan;
    return
end

[taskNames, taskID, allNames] = unifyFIRATaskNames;
mainTask = mode(taskID);
nt = max(taskID);

[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100, 40);
ns = max(sessionID);

% get common data structure, d
d = getCommonDataTypes(subjects, blockNum, sessionID);
cohs = unique(d.coh(d.good));
nc = length(cohs);
smoothCohs = linspace(cohs(1), cohs(end), 500);

% get a grand fit of ddRT parameters for over all sessions,
%   for each modality
[Qgrand, varQgrand] = getGrandddRTFit(d, taskID, sessionID);

f = figure(6549);
clf(f)

rows = 3;
cols = ceil(ns/rows);
nsp = rows*cols*2;

% setup lots of subfigures
pProp = {'XLim', [1 100], 'YLim', [0 1], ...
    'XTick', cohs, 'XScale', 'log', 'Parent', f};
tProp = {'XLim', [1 100], 'YLim', [0 2], ...
    'XTick', cohs, 'XScale', 'log', 'YGrid', 'on', 'Parent', f};

for ii = 1:ns
    sp = ii+cols*(floor((ii-1)/cols));
    axP(ii) = subplot(rows*2, cols, sp, pProp{:});
    title(sprintf('%s #%d', subjects{1}, ii));

    axT(ii) = subplot(rows*2, cols, sp+cols, tProp{:});
end
axises = cat(2, axP, axT);

% make labels only on edges
for ii = 1:cols:ns
    ylabel(axP(ii), 'P_c')
    ylabel(axT(ii), 't_T (ms)')
end
for ii = ns-cols+1:ns
    xlabel(axT(ii), '% coh')
end

% fit 6 parameters for each modality and each session
allFits = nan*zeros(ns,2,6);
for ss = 1:ns

    % select good trials from one session
    sessSelect = d.good & sessionID == ss;

    for tt = 1:nt

        % select trials from one task
        taskSelect = sessSelect & taskID == tt;

        % raw performance per coherence
        n = zeros(1,nc);
        Pc = zeros(1,nc);
        mRT = zeros(1,nc);
        quartRT = zeros(nc,3);
        fiveRT = zeros(nc,2);
        for ii = 1:nc
            cohSelect = d.coh==cohs(ii) & taskSelect;
            n(ii) = sum(cohSelect);
            Pc(ii) = sum(d.correct(cohSelect)) / n(ii);
            mRT(ii) = mean(d.RT(cohSelect));
            quartRT(ii,:) = prctile(d.RT(cohSelect), [25, 50, 75]);
            fiveRT(ii,:) = prctile(d.RT(cohSelect), [5, 95]);
        end

        % package task data for fitting
        fitData = [d.coh(taskSelect), d.correct(taskSelect), d.RT(taskSelect)];

        % initial parameter values and constraints
        % guess, min, max
        Qinit = [ddRT_initial_params(fitData), ddRT_bound_params];

        % fix the residual time to the grand residual time
        Qinit(6,:) = Qgrand(6,tt);

        % fit ddm
        allFits(ss,tt,:) = ddRT_fit( ...
            @ddRT_psycho_nll, @ddRT_chrono_nll_from_pred, ...
            fitData, Qinit);

        % compute smooth fit curves
        psychoFit = ddRT_psycho_val(allFits(ss,tt,:), smoothCohs);
        chronoFit = ddRT_chrono_val(allFits(ss,tt,:), smoothCohs);

        % color code the response modalities and offset them
        ofs = 1.02;
        x = cohs/ofs * ofs^(2*(tt-1));
        col = [tt==1, 0, tt==2];
        text(cohs(1), .1*tt, taskNames(tt), 'Parent', axP(ss), ...
            'Color', col);

        % draw smooth fit and raw accuracy data
        line(smoothCohs, psychoFit, 'Parent', axP(ss), ...
            'LineWidth', 1, 'LineStyle', '-', 'Color', col);
        line(x, Pc, 'Parent', axP(ss), ...
            'LineWidth', 1, 'LineStyle', 'none', ...
            'Marker', '.', 'Color', col);

        % draw smooth fit and raw timing data
        line(smoothCohs, chronoFit, 'Parent', axT(ss), ...
            'LineWidth', 1, 'LineStyle', '-', 'Color', col);

        line(x([1,end]), [1,1]*allFits(ss,tt,6), 'Parent', axT(ss), ...
            'LineWidth', 1, 'LineStyle', '-', 'Color', col);

        for ii = 1:nc
            line(x(ii), mRT(ii), 'Parent', axT(ss), ...
                'LineWidth', 1, 'LineStyle', 'none', ...
                'Marker', '.', 'Color', col);
            line([1 1 1]*x(ii), quartRT(ii,:), 'Parent', axT(ss), ...
                'LineWidth', 1, 'LineStyle', 'none', ...
                'Marker', '+', 'Color', col);
            line([1 1]*x(ii), fiveRT(ii,:), 'Parent', axT(ss), ...
                'LineWidth', 1, 'LineStyle', '-', ...
                'Marker', 'none', 'Color', col);
        end
    end
end