% look at variance of eye position during fixation for all subjects

subjDirs = { ...
    '/Volumes/XServerData/Psychophysics/response_modality/BMS', ...
    '/Volumes/XServerData/Psychophysics/response_modality/EAF', ...
    '/Volumes/XServerData/Psychophysics/response_modality/JIG', ...
    '/Volumes/XServerData/Psychophysics/response_modality/MAG', ...
    '/Volumes/XServerData/Psychophysics/response_modality/NKM', ...
    '/Volumes/XServerData/Psychophysics/response_modality/XL', ...
    '/Volumes/XServerData/Psychophysics/response_modality/CC', ...
    };
ns = length(subjDirs);

% pick which task
tt = 2;

f = figure(672);
clf(f);

axEV = subplot(3,1,1, 'Parent', f);
ylabel(axEV, 'E[Var(trial)]')

axVE = subplot(3,1,2, 'Parent', f);
ylabel(axVE, 'Var[E(trial)]')

axV = subplot(3,1,3, 'Parent', f);
ylabel(axV, 'Var(trials)')

xlabel(axV, 'time of day')

for ii = 1:ns
    [times, vars] = feval(@RTFixVar, subjDirs{ii}, tt);

    % mean of trial variance
    line(times, vars.sessXMeanVar, 'Parent', axEV, 'Color', [0 0 1], ...
        'LineStyle', 'none', 'Marker', '*');
    line(times, vars.sessYMeanVar, 'Parent', axEV, 'Color', [1 0 0], ...
        'LineStyle', 'none', 'Marker', '*');
    line(times, vars.sessRMeanVar, 'Parent', axEV, 'Color', [0 1 0], ...
        'LineStyle', 'none', 'Marker', '*');

    % variance of trial mean
    line(times, vars.sessXVarMean, 'Parent', axVE, 'Color', [0 0 1], ...
        'LineStyle', 'none', 'Marker', '*');
    line(times, vars.sessYVarMean, 'Parent', axVE, 'Color', [1 0 0], ...
        'LineStyle', 'none', 'Marker', '*');
    line(times, vars.sessRVarMean, 'Parent', axVE, 'Color', [0 1 0], ...
        'LineStyle', 'none', 'Marker', '*');

    % total variance across trials
    line(times, vars.sessXVar, 'Parent', axV, 'Color', [0 0 1], ...
        'LineStyle', 'none', 'Marker', '*');
    line(times, vars.sessYVar, 'Parent', axV, 'Color', [1 0 0], ...
        'LineStyle', 'none', 'Marker', '*');
    line(times, vars.sessRVar, 'Parent', axV, 'Color', [0 1 0], ...
        'LineStyle', 'none', 'Marker', '*');
end