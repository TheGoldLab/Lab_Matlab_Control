function slopeChange
% plot psychometric function fit parameters per session
%   look at mainstream response type only
%   focus on thresh and slope changes
clear all
f = clf(figure(111));

% which of three quest instances to examine for each sessions?
qn = 2;

% which subjecs to look at
subs = {...
    '/Volumes/XServerData/Psychophysics/response_modality/AKM', ...
    '/Volumes/XServerData/Psychophysics/response_modality/GYL', ...
    '/Volumes/XServerData/Psychophysics/response_modality/SL', ...
    ...'/Volumes/XServerData/Psychophysics/response_modality/MZ', ...
    ...'/Volumes/XServerData/Psychophysics/response_modality/NLM', ...
    ...'/Volumes/XServerData/Psychophysics/response_modality/XS', ...
    };
ns = length(subs);

% bins for coherences
edges = (.5:1:100);
centers = edges(2:end)-edges(2)/2;

% coherence above which to consider lapse rate
lapseCoh = 90;
lMax = .2;

% confidence interval and repetitions for Weibull fit bootstrapping
ci = 68;
ciN = 100;

% initial values and boundaries for weibull fitting
fitCon = [ ...
    80      10      200;    ... % thresh
    3.5     0.5     4.5;    ... % shape
    lMax    lMax	lMax;	... % lapse
    0.5     0.5     0.5];       % lower asymptote

% divvy up figure realestate
rows = 2;
cols = ceil(ns/rows);
npg = rows*cols;
pw = 1/cols;
ph = 1/rows;

% bottom-left corners of major figure sub-regions
page(1,1:npg) = repmat(0:pw:1-pw, 1, rows);
for r = 1:rows
    page(2, 1+((r-1)*cols):r*cols) = (rows-r)*ph;
end
page(3,1:ns) = 0;
page(4,1:ns) = 0;

% bottom-left corners of minor figure sub-regions (within major subregions)
%   for arranging some number of axes
nax = 4;
margain.x = pw/5;
margain.y = ph/5;
paragraph(1,1:nax) = margain.x;
paragraph(2,1:nax) = linspace(margain.y, page(2,1)-margain.y, nax);
paragraph(3,1:nax) = pw-(2*margain.x);
paragraph(4,1:nax) = .6*margain.y;

for s = 1:ns
    % axes for thresholds
    axT(s) = axes('Position', paragraph(:,4)+page(:,s), ...
        'Parent', f, ...
        'YLim', fitCon(1,2:3).*[.9 1.1], 'YScale', 'log');

    % axes for shapes
    axB(s) = axes('Position', paragraph(:,3)+page(:,s), ...
        'Parent', f, ...
        'YLim', fitCon(2,2:3).*[.9 1.1]);

    % axes for lapse rates
    axL(s) = axes('Position', paragraph(:,2)+page(:,s), ...
        'Parent', f, ...
        'YLim', [0, lMax]);

    % axes for full Weibull curve
    axP(s) = axes('Position', paragraph(:,1)+page(:,s), ...
        'Parent', f, ...
        'YLim', [0,1], 'Xlim', edges([1,end]));
end

% lables for weibull fit parameters
for n = [1, min(floor(npg/2)+1, ns)];
    ylabel(axT(n), sprintf('thresh (%d%% boot)', ci))
    ylabel(axB(n), sprintf('shape (%d%% boot)', ci))
    ylabel(axL(n), sprintf('err @ %d+%%coh', lapseCoh))
    ylabel(axP(n), 'Weibull')
end

for n = 1:ns
    % axes for full weibull curves
    xlabel(axP(n), '% coherence')
    xlabel(axL(n), 'session number')
end

global export
for s = 1:ns
    clear global FIRA
    modalityMetaFIRA(qn, subs{s})
    global FIRA

    eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
    nt = FIRA.header.numTrials;
    tn = FIRA.ecodes.data(:,eTrial);

    eTask = strcmp(FIRA.ecodes.name, 'oc_taskID');
    taskStart = [0; find(diff(tn) < 0); nt]+1;
    tid = FIRA.ecodes.data(:, eTask);

    eTh = strcmp(FIRA.ecodes.name, 'oc_thresh');
    eThub = strcmp(FIRA.ecodes.name, 'oc_threshUB');
    eThlb = strcmp(FIRA.ecodes.name, 'oc_threshLB');
    Thub = FIRA.ecodes.data(:,eThub);
    Th = FIRA.ecodes.data(:,eTh);
    Thlb = FIRA.ecodes.data(:,eThlb);

    eDate = strcmp(FIRA.ecodes.name, 'oc_date');
    dat = FIRA.ecodes.data(:,eDate);
    dats = unique(dat);
    day = floor(FIRA.ecodes.data(:,eDate));
    days = unique(day);

    eBlock = strcmp(FIRA.ecodes.name, 'oc_blockNum');
    block = FIRA.ecodes.data(:,eBlock);
    blocks = unique(block(~isnan(block)));

    eGood = strcmp(FIRA.ecodes.name, 'good_trial');
    good = FIRA.ecodes.data(:,eGood);

    eCorrect = strcmp(FIRA.ecodes.name, 'correct');
    correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

    % get coh as recorded by low quest
    eCoh = strcmp(FIRA.ecodes.name, 'dot_coh_low_used');
    coh = FIRA.ecodes.data(:,eCoh);

    % how many sessions?
    nd = length(days);
    allDay = 1:nd;

    fits = cell(nd, 2);
    fitCI = cell(nd, 2);
    
    yesterdayWasLevers = false;
    switchDay = nan;
    for d = 1:length(days)

        % pick out one day
        %   lump together the blocks
        daySelect = dat>days(d) & dat<days(d)+1;

        leverage = daySelect & tid == 737;
        eyeage = daySelect & tid == 738;
        if sum(leverage) > sum(eyeage)
            taskSelect = leverage;
            modality = 'levers';
            colour = [0 0 1];
        else
            taskSelect = eyeage;
            modality = 'eyes';
            colour = [1 0 0];
        end
        subName = FIRA.allHeaders(1).subject(2:end);
        title(axT(s), sprintf('%s', subName));

        % find the switch day
        todayIsLevers = ...
            sum(leverage) > sum(eyeage);
        if d>1 && xor(yesterdayWasLevers, todayIsLevers);
            switchDay = d;
        end
        yesterdayWasLevers = todayIsLevers;

        % calculate performance in each bin
        Pc = nan*ones(size(centers));
        n = nan*ones(size(centers));
        for ii = 1:length(centers)
            stimSelect = coh >= edges(ii) & coh < edges(ii+1) ...
                & taskSelect & good;
            n(ii) = sum(stimSelect);
            Pc(ii) = sum(correct & stimSelect)/n(ii);
        end

        % calculate lapse rate
        stimLapse = coh >= lapseCoh & taskSelect & good;
        nl = sum(stimLapse);
        if nl
            Pl = sum(correct & stimLapse)/nl;
            fitCon(3,:) = 1-Pl;
        end

        z = n~=0;
        if any(z)
            PFD = [centers(z)', Pc(z)', n(z)'];
            [fits{d}, fitCI{d}] = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), ...
                {ciN, ci}, fitCon);

            % weibull curve
            intStims = linspace(edges(1), edges(end), 500);
            intPF = weibu(intStims, fits{d});
            l = line(intStims, intPF, 'Marker', 'none', ...
                'LineStyle', '-', 'Color', colour', 'Parent', axP(s));

            % thresh from fit
            da = [1,1,1]*d;
            Th = [fitCI{d}(1,1), fits{d}(1), fitCI{d}(1,2)];
            %   with confidence interval
            line(da, Th, 'Marker', '+', 'Color', colour, ...
                'Parent', axT(s), 'LineWidth', 2, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);
            set(axT(s), 'XLim', [1,nd], 'XTick', allDay)

            % shape
            %   with confidence interval
            S = [fitCI{d}(2,1), fits{d}(2), fitCI{d}(2,2)];
            line(da, S, 'Marker', '+', 'Color', colour, ...
                'Parent', axB(s)', 'LineWidth', 2, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);
            set(axB(s), 'XLim', [1,nd], 'XTick', allDay)

            % lapse
            line(d, fits{d}(3), 'Marker', '+', 'Color', colour, ...
                'Parent', axL(s), 'LineWidth', 2, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);
            set(axL(s), 'XLim', [1,nd], 'XTick', allDay)

        else
            fits{d} = nan*ones(4,1);
        end

        % get ready to export data to a file for Josh
        %   only mainstream modality
        %   only pre-switch sessions
        if isnan(switchDay) || d < switchDay
            export.(subName).session(d) = d;
            export.(subName).alpha(d) = fits{d}(1);
            export.(subName).alpha_sem(d,:) = [fitCI{d}(1,1), fitCI{d}(1,2)];
            export.(subName).beta(d) = fits{d}(2);
            export.(subName).beta_sem(d, :) = [fitCI{d}(2,1), fitCI{d}(2,2)];
        end
    end
end

function embiggen(obj, event, target)
if ~get(obj, 'UserData')
    set([obj, target], 'LineWidth', 6, 'UserData', true)
else
    set(obj, 'LineWidth', 2, 'UserData', false)
    set(target, 'LineWidth', 1)
end

function err = exponErr(p, x, y)
% least-squares error for exponential fitting
z = expon(x,p);
err = sum((y-z).^2);

function y = expon(x, p)
% exponential function with parameters p
%   p(1) = lower asymptote
%   p(2) = coefficient
%   p(3) = base
y = p(1) + p(2)*(p(3).^x);

function y = weibu(x, p)
% weibull function with parameters p
%   p(1) = threshold
%   p(2) = shape
%   p(3) = lapse
%   p(4) = lower asymptote
y = p(4) + (1 - p(4) - p(3)) .* (1 - exp(-(x./p(1)).^p(2)));
