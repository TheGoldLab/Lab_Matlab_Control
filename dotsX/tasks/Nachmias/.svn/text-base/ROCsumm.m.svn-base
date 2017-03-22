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

eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dates = unique(FIRA.ecodes.data(:, eDate));

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
s.dots.units = 'signed dot %coherence';
s.dots.fig = 48;
s.dots.figPos = mre(1,[3,4,3,4]).*[.5, .4, .5, .6];

% analyze detect and discrim in parallel for contrast and dots
for style = {'contrast', 'dots'}
    stim = s.(style{1}).value;
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
        for tt = 1:2

            task = FIRA.ecodes.data(:,eTaskID) == ...
                FIRA.globalTaskID.(theseTasks{tt});

            if sum(task)

                % for detection, use absolute coherence
                stims = unique(abs(stim(~isnan(stim))));

                sp = subplot(2,2,tt);
                cla(sp);

                % computer the P(S|n) and P(S|s) for each coh and date
                %   for each detection task
                PS = nan*ones(length(stims), length(dates));
                n = nan*ones(length(stims), length(dates));
                for dd = 1:length(dates)
                    dat = FIRA.ecodes.data(:,eDate) == dates(dd);
                    for ii = 1:length(stims)
                        s_trials = (abs(stim)==stims(ii))&task&good&dat;
                        n(ii) = nansum(s_trials);
                        if n(ii)
                            PS(ii,dd) = nansum(correct(s_trials))/n(ii);
                        end
                    end
                end

                % show performance text
                % text(stims(find(n,1))+stims(end)*.2, .2, ...
                %     sprintf('%2.1f%% of %d', 100*mean(correct(task)), ...
                %     sum(task)), 'FontSize', 24, 'Color', [.85 .75 .95], ...
                %     'Parent', sp);

                % scatter ROC points
                %   for blank detection trials,
                %   P(correct|n) is the compliment of P(S|n)
                %   PS(1,:) is P(S|n), PS(i>1,:) is P(S|si)
                PS(1,:) = 1-PS(1,:);

                colors = ones(length(stims), 3);
                colors(:,3) = stims/max(stims)*.6;
                colors(:,2) = stims/max(stims);
                colors(:,1) = stims/max(stims);
                for ii = 2:length(stims)
                    line(PS(1,:), PS(ii,:), 'LineStyle', '-', ...
                        'Marker', '*', 'Color', colors(ii,:), 'Parent', sp);
                    cohStr{ii} = num2str(stims(ii));
                end
                xlim(sp, [0,1])
                ylim(sp, [0,1])
                xlabel(sp, 'P(S|n)', 'FontSize', 14)
                ylabel(sp, 'P(S|s)', 'FontSize', 14)
                title(sp, theseTasks{tt}, 'FontSize', 14)

                % legend magically picks the right colors
                legend(cohStr{2:end}, 'Location', 'SouthOutside')
                legend(sp, 'boxoff')

            end
        end

        % do the discrimination tasks on separate plots
        for tt = 3:4

            task = FIRA.ecodes.data(:,eTaskID) == ...
                FIRA.globalTaskID.(theseTasks{tt});

            if sum(task)

                % for discrimination, also remember coherence sign
                stims = unique(stim(~isnan(stim)));
                astims = unique(abs(stims));

                sp = subplot(2,2,tt);
                cla(sp);

                % computer the P(R|l) and P(R|r) for each coh and date
                %   for each discrimination task
                PRl = nan*ones(length(stims), length(dates));
                PRr = nan*ones(length(stims), length(dates));
                n = nan*ones(length(stims), length(dates));
                for dd = 1:length(dates)
                    dat = FIRA.ecodes.data(:,eDate) == dates(dd);
                    for ii = 1:length(stims)
                        s_trials = (stim==stims(ii))&task&good&dat;
                        n(ii) = nansum(s_trials);
                        if n(ii)
                            if stims(ii) < 0
                                % prob R given rightward coherence
                                PRl(ii,dd) = ...
                                    nansum(resp(s_trials)==1)/n(ii);
                            elseif stims(ii) > 0
                                % prob R given leftward coherence
                                PRr(ii,dd) = ...
                                    nansum(resp(s_trials)==1)/n(ii);
                            end
                        end
                    end
                end
                
                PRl = PRl(~isnan(PRl));
                PRr = flipud(PRr(~isnan(PRr)));

                % show performance text
                % text(stims(find(n,1))+stims(end)*.2, .2, ...
                %     sprintf('%2.1f%% of %d', 100*mean(correct(task)), ...
                %     sum(task)), 'FontSize', 24, 'Color', [.85 .75 .95], ...
                %     'Parent', sp);

                colors = ones(length(astims), 3);
                colors(:,3) = astims/max(astims)*.6;
                colors(:,2) = astims/max(astims);
                colors(:,1) = astims/max(astims);
                las = length(astims);
                for ii = 1:las-1
                    line(PRl(ii,:), PRr(las-ii,:), 'LineStyle', '-', ...
                        'Marker', '*', 'Color', colors(ii,:), 'Parent', sp);
                    cohStr{ii} = num2str(astims(ii));
                end
                xlim(sp, [0,1])
                ylim(sp, [0,1])
                xlabel(sp, 'P(S|n)', 'FontSize', 14)
                ylabel(sp, 'P(S|s)', 'FontSize', 14)
                title(sp, theseTasks{tt}, 'FontSize', 14)

                % legend magically picks the right colors
                legend(cohStr{:}, 'Location', 'SouthOutside')
                legend(sp, 'boxoff')
            end
        end
    end
end