% get eye data from FIRA file
global FIRA
modalityMetaFIRA;

% eyetracker camera frequency
f = 120;

% roughly, max trial length in seconds
T = 2;

% get some task events times from FIRA
eBegin = strcmp(FIRA.ecodes.name, 'trial_begin');
begin = FIRA.ecodes.data(:,eBegin);
eWrt = strcmp(FIRA.ecodes.name, 'trial_wrt');
wrt = FIRA.ecodes.data(:,eWrt);
rectify = wrt-begin;

eFP = strcmp(FIRA.ecodes.name, 'indicate');
fp = FIRA.ecodes.data(:,eFP)./1000 + rectify;

eShow = strcmp(FIRA.ecodes.name, 'showStim');
show = FIRA.ecodes.data(:,eShow)./1000 + rectify;

eHide = strcmp(FIRA.ecodes.name, 'choices');
hide = FIRA.ecodes.data(:,eHide)./1000 + rectify;

% make figure and axes for plotting
clf(figure(933))
ax_pd = subplot(4,1,1, 'XLim', [0, T], 'YLim', [0, 100]);
ylabel(ax_pd, 'pupil diameter')
pd = line(nan, nan, 'Color', [0 0 1], 'Parent', ax_pd);

ax_hp = subplot(4,1,2, 'XLim', [0, T]);
ylabel(ax_hp, 'horizontal position')
hp = line(nan, nan, 'Color', [0 .5 0], 'Parent', ax_hp);

ax_vp = subplot(4,1,3, 'XLim', [0, T]);
ylabel(ax_vp, 'vertical position')
vp = line(nan, nan, 'Color', [.7 .7 0], 'Parent', ax_vp);

ax_bn = subplot(4,1,4, 'XLim', [0, T], ...
    'YLim', [-.1, 1.1], 'YTick', [0 1], ...
    'YTickLabel', {'normal', 'blinking'});
bn = line(nan, nan, 'Color', [1 0 0], 'Parent', ax_bn);

% put event markers in blink axes
line_fp = line([nan, nan], [-2, 2], 'Color', [0 0 0], ...
    'Parent', ax_bn);
line_show = line([nan, nan], [-2, 2], 'Color', [0 0 0], ...
    'Parent', ax_bn);
line_hide = line([nan, nan], [-2, 2], 'Color', [0 0 0], ...
    'Parent', ax_bn);

% and copy markers into other axes
lines_fp = [line_fp; copyobj(line_fp, [ax_pd, ax_hp, ax_vp])];
lines_show = [line_show; copyobj(line_show, [ax_pd, ax_hp, ax_vp])];
lines_hide = [line_hide; copyobj(line_hide, [ax_pd, ax_hp, ax_vp])];

% plot eye data for each trial
for ii = 130:length(FIRA.aslData)
    d = FIRA.aslData{ii};
    if ~isempty(d)
        
        % show data traces
        n = size(d, 1);
        title(ax_pd, sprintf('%d', ii));
        naxis = 1:n;
        xaxis = (d(naxis, 4)-d(1, 4))./f;
        set(pd, 'XData', xaxis, 'YData', d(naxis, 1));
        set(hp, 'XData', xaxis, 'YData', d(naxis, 2));
        set(vp, 'XData', xaxis, 'YData', d(naxis, 3));
        set(bn, 'XData', xaxis, 'YData', d(naxis, 5));
        
        % show trial event markers
        if ~isnan(fp(ii))
            set(lines_fp, 'XData', [1,1]*fp(ii));
        end
        if ~isnan(show(ii))
            set(lines_show, 'XData', [1,1]*show(ii));
        end
        if ~isnan(hide(ii))
            set(lines_hide, 'XData', [1,1]*hide(ii));
        end
        
        drawnow;
        if true%any(d(naxis, 5))
            pause
        end
    end
end