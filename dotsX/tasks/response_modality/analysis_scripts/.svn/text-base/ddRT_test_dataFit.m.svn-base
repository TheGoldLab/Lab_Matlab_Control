% fit parameters to real data
%   expect data from the reaction time/response modality experiments at
%	/Volumes/XServerData/Psychophysics/response_modality/

% get data
clear all
concatenateFIRAs();

[taskNames, tnID, allNames] = unifyFIRATaskNames;
mainTask = mode(tnID);

[sessionID, blockNum, days, subjects] = ...
    findFIRASessionsAndBlocks(100, 40);

d = getCommonDataTypes(subjects, blockNum, sessionID);
x = unique(d.coh(d.good));

% a first look at the dataset
nc = length(x);
n = zeros(1, nc);
Pc = zeros(1, nc);
mRT = zeros(1, nc);
quartRT = zeros(nc, 3);
fiveRT = zeros(nc, 2);
for ii = 1:nc

    trials = d.good & d.coh==x(ii) & tnID'==mainTask;

    % trials per condition
    n(ii) = sum(trials);

    % mean responses for plotting
    Pc(ii) = sum(d.correct(trials)) / n(ii);

    % RT stats for plotting
    mRT(ii) = mean(d.RT(trials));
    quartRT(ii,:) = prctile(d.RT(trials), [25, 50, 75]);
    fiveRT(ii,:) = prctile(d.RT(trials), [5, 95]);
end

% organize data as expected by my ddRT_* functions
data = [d.coh(d.good), d.correct(d.good), d.RT(d.good)];

% initial parameter values and constraints
% guess, min, max
Qinit = [ddRT_initial_params(data), ddRT_bound_params];

opt = optimset( ...
    'LargeScale',   'off', ...
    'Display',      'off', ...
    'Diagnostics',  'off', ...
    'MaxIter',      1e3, ...
    'MaxFunEvals',  1e4);

% two two different fits:
%   use logistic/binomial accuracy likelihood
%   try two different variance estimates for mean RT likelihood:
%       variance prediciton as solved in Palmer Huk Shadlen 2005
%       variance as fano facor, which I estimated from simlulation
[Qpred, Qerr, errVal, exitFlag, outputInfo] = ddRT_fit(...
    @ddRT_psycho_nll, @ddRT_chrono_nll_from_pred, ...
    data, Qinit, opt);
if outputInfo.iterations >= opt.MaxIter ...
        || outputInfo.funcCount > opt.MaxFunEvals
    disp(sprintf('\nfor pred: %s\n', outputInfo.message));
end

[Qfano, Qerr, errVal, exitFlag, outputInfo] = ddRT_fit(...
    @ddRT_psycho_nll, @ddRT_chrono_nll_from_fano, ...
    data, Qinit, opt);
if outputInfo.iterations >= opt.MaxIter ...
        || outputInfo.funcCount > opt.MaxFunEvals
    disp(sprintf('\nfor fano: %s\n', outputInfo.message));
end

disp(sprintf('k\t=\t%.4f\t%.4f', Qpred(1), Qfano(1)));
disp(sprintf('b\t=\t%.2f\t%.2f', Qpred(2), Qfano(2)));
disp(sprintf('A''\t=\t%.2f\t%.2f', Qpred(3), Qfano(3)));
disp(sprintf('l\t=\t%.3f\t%.3f', Qpred(4), Qfano(4)));
disp(sprintf('g\t=\t%.1f\t%.1f', Qpred(5), Qfano(5)));
disp(sprintf('tR\t=\t%.3f\t%.3f', Qpred(6), Qfano(6)));

% make fit curves
predPsycho = ddRT_psycho_val(Qpred, x);
predChrono = ddRT_chrono_val(Qpred, x);

fanoPsycho = ddRT_psycho_val(Qfano, x);
fanoChrono = ddRT_chrono_val(Qfano, x);

f = figure(9969);
clf(f)

% show "true" functions, fake data, fit functions
axP = subplot(2,1,1, 'XLim', [1 100], 'YLim', [0 1], ...
    'XTick', x, 'XScale', 'log', 'Parent', f);
ylabel(axP, 'P_c')

line(x, predPsycho, 'Parent', axP, 'Color', [1 0 0], ...
    'LineWidth', 1.5, 'LineStyle', ':');
line(x, fanoPsycho, 'Parent', axP, 'Color', [0 1 0], ...
    'LineWidth', 1.5, 'LineStyle', ':');

line(x, Pc, 'Parent', axP, 'LineWidth', 1, 'Color', [0 0 0], ...
    'Marker', '.', 'LineStyle', 'none');

text(1.6, .8, 'pred', 'Color', [1 0 0]);
text(1.6, .9, 'fano', 'Color', [0 1 0]);


axT = subplot(2,1,2, 'XLim', [1 100], 'YLim', [0 max(fiveRT(:,2))]*1.3, ...
    'XTick', x, 'XScale', 'log', 'Parent', f);
ylabel(axT, 't_T (ms)')
xlabel(axT, '% coh')

line(x, predChrono, 'Parent', axT, 'Color', [1 0 0], ...
    'LineWidth', 1.5, 'LineStyle', ':');
line(x, fanoChrono, 'Parent', axT, 'Color', [0 1 0], ...
    'LineWidth', 1.5, 'LineStyle', ':');

% plot RT distribution for each stimulus strength
%   mean, quartiles, 5% and 95%
for ii = 1:length(x)
    line(x(ii), mRT(ii), 'Parent', axT, 'LineWidth', 1, 'Color', [0 0 0], ...
        'Marker', '.', 'LineStyle', 'none');
    line([1 1 1]*x(ii), quartRT(ii,:), 'Parent', axT, 'LineWidth', 1, 'Color', [0 0 0], ...
        'Marker', '+', 'LineStyle', 'none');
    line([1 1]*x(ii), fiveRT(ii,:), 'Parent', axT, 'LineWidth', 1, 'Color', [0 0 0], ...
        'Marker', 'none', 'LineStyle', '-');
end