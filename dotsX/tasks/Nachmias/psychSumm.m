% get some FIRA file(s) to look at
%clear all
%close all

global FIRA
nachmiasMetaFIRA
if isempty(FIRA)
    return
end

% monitor real estate
mre = get(0, 'MonitorPositions');

% locate useful ecodes
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = logical(FIRA.ecodes.data(:,eGood));

eResponse = strcmp(FIRA.ecodes.name, 'oc_response');
resp = FIRA.ecodes.data(:,eResponse);

eLatency = strcmp(FIRA.ecodes.name, 'oc_latency');
latency = FIRA.ecodes.data(:,eLatency);

eContrast = strcmp(FIRA.ecodes.name, 'oc_contrast');
eSinCoh = strcmp(FIRA.ecodes.name, 'oc_sincoh');
eTaskID = strcmp(FIRA.ecodes.name, 'oc_taskID');

% organize parallel structures for code reuse
s.contrast.task_names = {'taskDetectDownContrast', 'taskDetectUpContrast', ...
    'taskDiscrim2afcContrast', 'taskDiscrim3afcContrast'};
s.contrast.value = FIRA.ecodes.data(:,eContrast);
s.contrast.units = 'Webber contrast (bg 30cd/m^2)';
s.contrast.fig = 19;
s.contrast.figPos = mre(1,[3,4,3,4]).*[0, .4, .5, .6];

s.dots.task_names = {'taskDetectLDots', 'taskDetectRDots', ...
    'taskDiscrim2afcDots', 'taskDiscrim3afcDots'};
s.dots.value = FIRA.ecodes.data(:,eSinCoh);
s.dots.units = 'signed dot coherence';
s.dots.fig = 48;
s.dots.figPos = mre(1,[3,4,3,4]).*[.5, .4, .5, .6];

% analyze detect and discrim in parallel for contrast and dots
for style = {'contrast', 'dots'}
    stim = s.(style{1}).value;
    stims = unique(stim(~isnan(stim)));
    thisStyle = ~isnan(stim);
    theseTasks = s.(style{1}).task_names;
    lateRange = [0,5000];

    if sum(thisStyle)
        % title with basic session info
        figure(s.(style{1}).fig)
        clf(s.(style{1}).fig)
        set(s.(style{1}).fig, 'Name', sprintf('%s %s', ...
            FIRA.allHeaders(1).subject, FIRA.datesString), ...
            'Position', s.(style{1}).figPos);

        % do the detection tasks
        sp = subplot(3,1,1);
        axr = axes('Position', get(sp, 'Position'), 'YColor', [1 1 0], ...
            'Color', 'none', 'YAxisLocation', 'right');

        for tt = 1:2
            task = FIRA.ecodes.data(:,eTaskID) == ...
                FIRA.globalTaskID.(theseTasks{tt});
            if sum(task)

                % compute P_detect for down/left detecton task,
                %   then add to same plot with up/right detecton task
                probD = nan*ones(size(stims));
                late = nan*ones(size(stims));
                n = nan*ones(size(stims));
                for ii = 1:length(stims)
                    s_trials = (stim==stims(ii))&task&good;
                    n(ii) = nansum(s_trials);
                    if n(ii)
                        probD(ii) = nansum(correct(s_trials))/n(ii);
                        late(ii) = prctile(latency(s_trials), 50);
                    end
                end

                % for blank detection trials,
                %   P_correct is the compliment of P_detect
                probD(stims == 0) = 1-probD(stims == 0);

                PFD = [abs(stims(n~=0)) probD(n~=0) n(n~=0)];
                if abs(PFD(1,1)) > abs(PFD(end,1))
                    PFD = flipud(PFD);
                    flipMe = true;
                else
                    flipMe = false;
                end

                fits = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));

                % make a high-res Weibull from fits
                intStims = linspace(PFD(1,1), PFD(end,1), 500);
                intPF = fits(4) + (1 - fits(4) - fits(3)) .* ...
                    (1 - exp(-(intStims./fits(1)).^fits(2)));

                % show psychometric function with Weibull fit
                text(stims(find(n,1))+stims(end)*.2, .2, ...
                    sprintf('%2.1f%% of %d', 100*mean(correct(task)), ...
                    sum(task)), 'FontSize', 24, 'Color', [.85 .75 .95], ...
                    'Parent', sp);

                % scatter psychometric data
                line(stims, probD, 'LineStyle', 'none', ...
                    'Marker', '*', 'Color', [0 1 0], 'Parent', sp);

                % draw weibull fits
                if flipMe
                    line(fliplr(-intStims), fliplr(intPF), 'Parent', sp);
                    text(-fits(1), interp1(intStims, intPF, fits(1)), ...
                        sprintf('%.2f, %.2f', fits(1), fits(2)), 'Parent', sp);
                else
                    line(intStims, intPF, 'Parent', sp)
                    text(fits(1), interp1(intStims, intPF, fits(1)), ...
                        sprintf('%.2f, %.2f', fits(1), fits(2)), 'Parent', sp);
                end
                xlim(sp, [stims(1), stims(end)])
                ylim(sp, [0,1])
                ylabel(sp, 'P_d_e_t_e_c_t', 'FontSize', 14)
                title(sp, 'combined detection', 'FontSize', 14)

                % trace chrometric function
                line(stims, late, 'Color', [1 1 0], 'Marker', '.', ...
                    'Parent', axr);
                ylim(axr, lateRange)
                ylabel(axr, 'median latency (ms)', 'FontSize', 14)
                xlim(axr, [stims(1), stims(end)])

            end
        end

        % do the discrimination tasks on separate plots
        for tt = 3:4
            task = FIRA.ecodes.data(:,eTaskID) == ...
                FIRA.globalTaskID.(theseTasks{tt});
            if sum(task)

                probB = nan*ones(size(stims));
                probR = nan*ones(size(stims));
                late = nan*ones(size(stims));
                n = nan*ones(size(stims));
                for ii = 1:length(stims)
                    s_trials = (stim==stims(ii))&task&good;
                    n(ii) = nansum(s_trials);
                    if n(ii)
                        probB(ii) = nansum(resp(s_trials) == 2)/n(ii);
                        probR(ii) = nansum(resp(s_trials) == 1)/n(ii);
                        late(ii) = prctile(latency(s_trials), 50);
                    end
                end

                % do the Weibull fit with %left
                lSide = 1:length(stims) <= find(stims==0) & n' ~= 0;
                PFD = flipud([-stims(lSide) 1-probR(lSide) n(lSide)]);
                fits = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));

                % make a high-res Weibull from fits
                intStimsL = linspace(PFD(1,1), PFD(end,1), 500);
                intPFL = fits(4) + (1 - fits(4) - fits(3)) .* ...
                    (1 - exp(-(intStimsL./fits(1)).^fits(2)));
                thL = fits(1);
                shL = fits(2);

                % do the Weibull fit with %right
                rSide = 1:length(stims) >= find(stims==0) & n' ~= 0;
                PFD = [stims(rSide) probR(rSide) n(rSide)];
                fits = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));

                % make a high-res Weibull from fits
                intStimsR = linspace(PFD(1,1), PFD(end,1), 500);
                intPFR = fits(4) + (1 - fits(4) - fits(3)) .* ...
                    (1 - exp(-(intStimsR./fits(1)).^fits(2)));
                thR = fits(1);
                shR = fits(2);

                % show psychometric function with Weibull fit
                sp = subplot(3,1,tt-1);
                text(stims(1)*.8, .8, sprintf('%2.1f%% of %d', ...
                    100*mean(correct(task)), sum(task)), ...
                    'FontSize', 24, 'Color', [.95 .75 .85]);

                % scatter psychometric data
                line(stims, probR, 'Color', [0 1 0], 'Marker', '*', ...
                    'LineStyle', 'none', 'Parent', sp);

                % trace guessometric data
                line(stims, probB,'Color', [1 0 0], 'Marker', '*', ...
                    'Parent', sp);

                % draw Weibull fit in two parts
                line(intStimsR, intPFR, 'Color', [0 0 1], 'Parent', sp);
                line(-intStimsL, 1-intPFL, 'Color', [0 0 0], 'Parent', sp);

                text(thR, interp1(intStimsR, intPFR, thR), ...
                    sprintf('%.2f, %.2f', thR, shR), 'Parent', sp);
                text(-thL, 1-interp1(intStimsL, intPFL, thL), ...
                    sprintf('%.2f, %.2f', thL, shL), 'Parent', sp);
                xlim(sp, [stims(1), stims(end)])
                ylim(sp, [0,1])
                ylabel(sp, 'P_r_i_g_h_t', 'FontSize', 14)
                title(sp, s.(style{1}).task_names(tt), 'FontSize', 14)

                % trace chrometric function
                axr = axes('Position', get(sp, 'Position'), ...
                    'YColor', [1 1 0], 'Color', 'none', ...
                    'YAxisLocation', 'right');
                line(stims, late, 'Parent', axr, 'Color', [1 1 0], ...
                    'Marker', '.');
                ylim(axr, lateRange)
                ylabel(axr, 'median latency (ms)', 'FontSize', 14)
                xlim(axr, [stims(1), stims(end)])
            end
        end

        % only need to show units once
        xlabel(sp, s.(style{1}).units, 'FontSize', 14)
    end
end

% dipper
% d' vs signal
% gaussians in 2afc vs gaussians in 1i 2a fc
% detectionation combined task (literature search)
% bipolar impulse response despite temporal and spatial windowing