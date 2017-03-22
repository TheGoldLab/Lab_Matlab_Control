% get some FIRA file(s) to look at
% clear all
% close all

global FIRA
nachmiasMetaFIRA
if isempty(FIRA)
    return
end

% single sessions or accumulated sessions?
accumulate = false;

% do bootstrap error bars or just fits?
bootstrap = false;

% monitor real estate
mre = get(0, 'MonitorPositions');

% locate useful ecodes
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood));

eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dates = unique(FIRA.ecodes.data(:, eDate));

eContrast = strcmp(FIRA.ecodes.name, 'oc_contrast');
eSinCoh = strcmp(FIRA.ecodes.name, 'oc_sincoh');
eTaskID = strcmp(FIRA.ecodes.name, 'oc_taskID');

% organize parallel structures for code reuse
s.contrast.task_names = {'taskDetectDownContrast', 'taskDetectUpContrast', ...
    'taskDiscrim2afcContrast', 'taskDiscrim3afcContrast'};
s.contrast.value = abs(FIRA.ecodes.data(:,eContrast));
s.contrast.fig = 88;
s.contrast.figPos = mre(1,[3,4,3,4]).*[0, .4, .5, .6];

s.dots.task_names = {'taskDetectLDots', 'taskDetectRDots', ...
    'taskDiscrim2afcDots', 'taskDiscrim3afcDots'};
s.dots.value = abs(FIRA.ecodes.data(:,eSinCoh));
s.dots.fig = 34;
s.dots.figPos = mre(1,[3,4,3,4]).*[.5, .4, .5, .6];

% analyze detect and discrim in parallel for contrast and dots
for style = {'contrast', 'dots'}
    theseTasks = s.(style{1}).task_names;

    stim = s.(style{1}).value;
    stims = unique(stim(~isnan(stim)));

    % title with basic session info
    figure(s.(style{1}).fig)
    clf(s.(style{1}).fig)
    set(s.(style{1}).fig, 'Name', sprintf('%s %s', ...
        FIRA.allHeaders(1).subject, FIRA.datesString), ...
        'Position', s.(style{1}).figPos);

    % four statistics to keep track of
    pctCorr = nan*ones(length(dates), 4);
    
    % keep best guess and confidence bounds for Weibull fits
    Wthresh = nan*ones(length(dates), 4, 3);
    Wshape = nan*ones(length(dates), 4, 3);
    Wlapse = nan*ones(length(dates), 4, 3);

    dat = logical(zeros(size(FIRA.ecodes.data(:,eDate))));
    for dd = 1:length(dates)
        styleTasks = logical(zeros(size(correct)));
        
        % single sessions or accumulated sessions
        if accumulate
            dat = dat | FIRA.ecodes.data(:,eDate) == dates(dd);
        else
            dat = FIRA.ecodes.data(:,eDate) == dates(dd);
        end

        for tt = 1:4
            % get selector for one task
            task = FIRA.ecodes.data(:,eTaskID) == ...
                FIRA.globalTaskID.(theseTasks{tt});
            
            % enrich the selector for several tasks
            styleTasks = styleTasks | task;

            % get % correct, a coarse measure
            pctCorr(dd, tt) = 100*sum(correct(task&dat&good)) ...
                /sum(good(task&dat&good));

            % organize % correct psychometric data
            probC = nan*ones(size(stims));
            n = nan*ones(size(stims));
            for ii = 1:length(stims)
                s_trials = (stim==stims(ii))&task&good&dat;
                n(ii) = nansum(s_trials);
                if n(ii)
                    probC(ii) = nansum(correct(s_trials))/n(ii);
                end
            end

            % fit a Weibull to % correct data
            if any(n > 0)
                
                % fits take time...
                disp(sprintf('fitting %s %s', ...
                    datestr(dates(dd)), theseTasks{tt}))

                PFD = [stims(n~=0) probC(n~=0) n(n~=0)];

                if bootstrap
                    ciSets = 50;
                    ciSize = 90;
                    [fits, ci] = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), ...
                        {ciSets, ciSize});
                    Wthresh(dd,tt,1:3) = [fits(1), ci(1,1:2)];
                    Wshape(dd,tt,1:3) = [fits(2), ci(2,1:2)];
                    Wlapse(dd,tt,1:3) = [fits(3), ci(3,1:2)];
                else
                    fits = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));
                    Wthresh(dd,tt,1) = fits(1);
                    Wshape(dd,tt,1) = fits(2);
                    Wlapse(dd,tt,1) = fits(3);
                end
            end
        end
    end

    % each task can have a color
    colors = [[1 0 0];[.8 .8 0];[0 0 1];[0 .8 .8]];
    absc = 1:length(dates);

    % plot % correct across dates
    sp = subplot(4,1,1);
    cla(sp)
    for tt = 1:4
        showMe = ~isnan(pctCorr(:, tt));
        line(absc(showMe), pctCorr(showMe, tt), ...
            'Color', colors(tt,:), 'Marker', '.', 'Parent', sp);
    end
    title(sp, style{1}, 'FontSize', 16)
    ylim(sp, [0 100])
    ylabel(sp, 'percent correct', 'FontSize', 16)
    xlim(sp, [1, length(dates)]);

    % legend magically picks the right colors
    legend(theseTasks{:}, 'Location', 'Best')
    legend(sp, 'boxoff')

    % plot Weibull threshold across dates
    sp = subplot(4,1,2);
    cla(sp)
    for tt = 1:4
        showMe = ~isnan(pctCorr(:, tt));
        line(absc(showMe), Wthresh(showMe, tt, 1), ...
            'Color', colors(tt,:), 'Marker', '.', 'Parent', sp);
        if bootstrap
            line([absc(showMe);absc(showMe)], squeeze(Wthresh(showMe, tt, 2:3))', ...
                'Color', colors(tt,:), 'Marker', '*', 'Parent', sp);
        end
    end
    ylim(sp, [stims(1), 2*stims(end)])
    ylabel(sp, 'Weibull threshold', 'FontSize', 16)
    xlim(sp, [1, length(dates)]);


    % plot Weibull shape across dates
    sp = subplot(4,1,3);
    cla(sp)
    for tt = 1:4
        showMe = ~isnan(pctCorr(:, tt));
        line(absc(showMe), Wshape(showMe, tt, 1), ...
            'Color', colors(tt,:), 'Marker', '.', 'Parent', sp);
        if bootstrap
            line([absc(showMe);absc(showMe)], squeeze(Wshape(showMe, tt, 2:3))', ...
                'Color', colors(tt,:), 'Marker', '*', 'Parent', sp);
        end
    end
    ylabel(sp, 'Weibull shape', 'FontSize', 16)
    xlim(sp, [1, length(dates)]);


    % plot Weibull lapse across dates
    sp = subplot(4,1,4);
    cla(sp)
    for tt = 1:4
        showMe = ~isnan(pctCorr(:, tt));
        line(absc(showMe), Wlapse(showMe, tt, 1), ...
            'Color', colors(tt,:), 'Marker', '.', 'Parent', sp);
        if bootstrap
            line([absc(showMe);absc(showMe)], squeeze(Wlapse(showMe, tt, 2:3))', ...
                'Color', colors(tt,:), 'Marker', '*', 'Parent', sp);
        end
    end
    ylim(sp, [0 .5])
    ylabel(sp, 'Weibull lapse', 'FontSize', 16)
    xlim(sp, [1, length(dates)]);
    xlabel(sp, 'session number', 'FontSize', 16)
end