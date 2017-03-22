% get some FIRA file(s) to look at
%clear all
%close all

global FIRA
nachmiasMetaFIRA
if isempty(FIRA)
    return
end

intScale = 500;

useLapse = false;

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
s.contrast.fig = 20;
s.contrast.figPos = mre(1,[3,4,3,4]).*[0, .4, .5, .6];

s.dots.task_names = {'taskDetectLDots', 'taskDetectRDots', ...
    'taskDiscrim2afcDots', 'taskDiscrim3afcDots'};
s.dots.value = FIRA.ecodes.data(:,eSinCoh);
s.dots.units = 'signed dot coherence';
s.dots.fig = 50;
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

        % axes for Weibulls
        spw = subplot(3,1,1);
        title(spw, style{1})
        cla(spw)
        xlim(spw, [0, stims(end)])
        ylim(spw, [0 1])
        ylabel(spw, 'P_W_e_i_b_u_l_l', 'FontSize', 16)
        line(0, .5, 'Color', [0 0 0], 'Marker', '+', ...
            'HandleVisibility', 'off', 'Parent', spw)
        
        % axes for d'
        spd = subplot(3,1,2);
        cla(spd)
        xlim(spd, [0, stims(end)])
        ylim(spd, [0 7])
        ylabel(spd, 'd''', 'FontSize', 16)
        xlabel(spd, s.(style{1}).units)
        grid(spd)
        
        % axes for log d' slope
        spsd = subplot(3,1,3);
        cla(spsd)
        xlim(spsd, [0 , stims(end)])
        %ylim(spsd, [0 5])
        ylabel(spsd, 'd log(d'') / d log(x)', 'FontSize', 16)
        xlabel(spsd, ['log ',s.(style{1}).units])
        grid(spsd)

        % do the detection tasks
        for tt = 1:2
            task = FIRA.ecodes.data(:,eTaskID) == ...
                FIRA.globalTaskID.(theseTasks{tt});

            col = [1 tt/3 0];

            if sum(task)

                probD = nan*ones(size(stims));
                n = nan*ones(size(stims));
                for ii = 1:length(stims)
                    s_trials = (stim==stims(ii))&task&good;
                    n(ii) = nansum(s_trials);
                    if n(ii)
                        probD(ii) = nansum(correct(s_trials))/n(ii);
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

                % make a high-res Weibull from fits
                fits = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));
                intStims = linspace(PFD(1,1), PFD(end,1), intScale);

                % get PF on interval (gamma, 1-lam)
                lam = fits(3)*useLapse;
                intPF = fits(4) + (1 - fits(4) - lam) .* ...
                    (1 - exp(-(intStims./fits(1)).^fits(2)));
                
                legTaskNames{tt} = sprintf('%s B=%.2f', ...
                    theseTasks{tt}, fits(2));

                line(intStims, intPF, 'Color', col, 'Parent', spw);
                if fits(1) <= stims(end)
                    line(fits(1), intPF(find(intStims>=fits(1),1)), ...
                        'Marker', '*', 'Color', col, ...
                        'Parent', spw, 'HandleVisibility', 'off');
                end

                % convert from P to d', as in Klein, "Measuring,
                % estimating, and understanding..." 2001, Perception &
                % Psychophysics.
                %   equations 4 and 5
                intd = sqrt(2) ...
                    *(erfinv(2*intPF-1)-erfinv(2*fits(4)-1));

                line(intStims, intd, 'Color', col, ...
                    'Parent', spd);

                % get centers of diff axis
                dX = intStims(2)-intStims(1);
                daxis = intStims(2:end) - dX/2;
                line(daxis, diff(log(intd))./diff(log(intStims)), ...
                    'Color', col, 'Parent', spsd);
            end
        end

        % do the discrimination tasks
        % for tt = 3:4
        %     task = FIRA.ecodes.data(:,eTaskID) == ...
        %         FIRA.globalTaskID.(theseTasks{tt});
        % 
        %     col = [0 (tt-2)/3 1];
        % 
        %     if sum(task)
        % 
        %         probR = nan*ones(size(stims));
        %         n = nan*ones(size(stims));
        %         for ii = 1:length(stims)
        %             % ignore trials with 'both' response
        %             s_trials = (stim==stims(ii))&task&good&(resp~=2);
        %             n(ii) = nansum(s_trials);
        %             if n(ii)
        %                 probR(ii) = nansum(correct(s_trials))/n(ii);
        %             end
        %         end
        % 
        %         % do the Weibull fit with %left
        %         lSide = 1:length(stims) <= find(stims==0) & n' ~= 0;
        %         PFD = flipud([-stims(lSide) probR(lSide) n(lSide)]);
        %         fitsL = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));
        % 
        %         % make a high-res Weibull from fits
        %         %   get PF on interval (gamma, 1-lam)
        %         lam = fitsL(3)*useLapse;
        %         intStimsL = linspace(PFD(1,1), PFD(end,1), intScale);
        %         intPFL = fitsL(4) + (1 - fitsL(4) - lam) .* ...
        %             (1 - exp(-(intStimsL./fitsL(1)).^fitsL(2)));
        % 
        %         % do the Weibull fit with %right
        %         rSide = 1:length(stims) >= find(stims==0) & n' ~= 0;
        %         PFD = [stims(rSide) probR(rSide) n(rSide)];
        %         fitsR = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3));
        % 
        %         % make a high-res Weibull from fits
        %         %   get PF on interval (gamma, 1-lam)
        %         lam = fitsR(3)*useLapse;
        %         intStimsR = linspace(PFD(1,1), PFD(end,1), intScale);
        %         intPFR = fitsR(4) + (1 - fitsR(4) - lam) .* ...
        %             (1 - exp(-(intStimsR./fitsR(1)).^fitsR(2)));
        % 
        %         line(intStimsL, intPFL, 'Color', col, ...
        %             'Parent', spw, 'LineStyle', '--');
        %         if fitsL(1) <= stims(end)
        %             line(fitsL(1), intPFL(find(intStimsL>=fitsL(1),1)), ...
        %                 'Marker', '*', 'Color', col, ...
        %                 'Parent', spw, 'HandleVisibility', 'off');
        %         end
        %         legTaskNames{2*tt-3} = sprintf('%s neg B=%.2f', ...
        %             theseTasks{tt}, fitsL(2));
        % 
        %         line(intStimsR, intPFR, 'Color', col, ...
        %             'Parent', spw, 'LineStyle', ':');
        % 
        %         if fitsR(1) <= stims(end)
        %             line(fitsR(1), intPFR(find(intStimsR>=fitsR(1),1)), ...
        %                 'Marker', '*', 'Color', col, ...
        %                 'Parent', spw, 'HandleVisibility', 'off');
        %         end
        %         legTaskNames{2*tt-2} = sprintf('%s pos B=%.2f', ...
        %             theseTasks{tt}, fitsR(2));
        % 
        %         % convert from P to d', as in Klein, "Measuring,
        %         % estimating, and Understanding..." 2001, Perception &
        %         % Psychophysics.
        %         %   equations 4 and 7
        %         zR = erfinv(2*intPFR-1);% *sqrt(2)
        %         zL = erfinv(2*intPFL-1);% *sqrt(2)
        %         intd = (zR+zL);% /sqrt(2)
        % 
        %         % find the stim where d' is zero.  This is direction bias.
        %         iBias = find(intd >= 0, 1);
        %         bias = intStims(iBias);
        % 
        %         line(intStims, intd, 'Color', col, 'Parent', spd);
        %         line(bias, 0, 'Color', col, 'Marker', '*', 'Parent', spd);
        % 
        %         % get slope of log(d')
        %         dX = intStims(2)-intStims(1);
        %         dlintd = diff(intd)/dX;
        % 
        %         % get centers of diff axis
        %         dX = intStims(2)-intStims(1);
        %         daxis = intStims(iBias+1:end) - dX/2;
        %         line(log(daxis), ...
        %             diff(log(intd(iBias:end)))./diff(log(intStims(iBias:end))), ...
        %             'Color', col, 'Parent', spsd);
        % 
        %     end
        % end

        % like magic, pick the right colors for each line
        legend(spw, legTaskNames{:}, 'Location', 'SouthEast')
        legend(spw, 'boxoff')
    end
end