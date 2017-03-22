global FIRA
if isempty(FIRA)
    if exist('/Volumes/XServerData')
        suggestion = ...
            '/Volumes/XServerData/Psychophysics/response_modality/*';
    else
        suggestion = '/Users/lab/*';
    end
    [file, pth, filteri] = ...
        uigetfile({'*.mat'},'Load one FIRA file', ...
        suggestion, 'MultiSelect', 'on');

    if ischar(file)
        disp(['loading ', file])
        load(fullfile(pth,file));
    else
        file
        class(file)
    end
end

% collect ecode selectors and ecodes
ecoh = strcmp(FIRA.ecodes.name, 'dot_coh_mid_used');

rounder = 5;
coh = rounder/100*round(FIRA.ecodes.data(:,ecoh)/rounder);
cohs = unique(coh);

ecorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,ecorrect));

egood = strcmp(FIRA.ecodes.name, 'good_trial');
good = ~isnan(FIRA.ecodes.data(:,egood));

etask = strcmp(FIRA.ecodes.name, 'task_index');
task = FIRA.ecodes.data(:,etask);
tasks = unique(task);
nt = length(tasks);

clf
ax = gca;

% organize percent correct by task and coherence
Pc = nan*ones(length(cohs), nt);
n = nan*ones(length(cohs), nt);
fits = nan*ones(nt, 4);
for tt = 1:nt
    for cc = 1:length(cohs)
        c_trials = coh==cohs(cc) & good & task==tt;
        n(cc,tt) = nansum(c_trials);
        if n(cc,tt)
            Pc(cc,tt) = nansum(correct(c_trials))/n(cc,tt);
        end
    end

    % fit a weibull for each task
    nonz = n(:,tt)~=0;
    PFD = [cohs(nonz) Pc(nonz,tt) n(nonz,tt)];
    %fits(tt,1:4) = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));
    fits(tt,1:2) = ctPsych_fit(@quick2, PFD(:,1), PFD(:,2:3));
    fits(tt,3:4) = [.01,.5];

    % make a high-res Weibull from fits
    intStims = linspace(PFD(1,1), PFD(end,1), 500);
    intPF = fits(tt,4) + (1 - fits(tt,4) - fits(tt,3)) .* ...
        (1 - exp(-(intStims./fits(tt,1)).^fits(tt,2)));

    col = [tt==2 0 tt==1];
    line(cohs(nonz), Pc(nonz,tt), 'LineStyle', 'none', 'Marker', '*', ...
        'Color', col, 'Parent', ax)
    line(intStims, intPF, 'Color', col, 'Parent', ax)
    ylim(ax, [0,1])
    xlim(ax, [0,.5])
end
disp(fits(:,1:2))