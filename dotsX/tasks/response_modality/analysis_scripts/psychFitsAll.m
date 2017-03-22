function psychFitsAll

% plot psychometric function fit parameters per session

% which of three quest instances to examine?
qn = 2;

clear global FIRA
modalityMetaFIRA(qn)

clf(figure(18));

global FIRA fits leverP eyeP

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

% bin coherences
edges = (.5:1:100);
centers = edges(2:end)-edges(2)/2;

% how many sessions?
nd = length(days);
allDay = 1:nd;

lapseCoh = 90;

% initial values and boundaries for weibull fitting
lMax = 0.1;
bot = 0.5;
fitCon = [ ...
    80      20      200;    ... % thresh
    1.5     1.5     1.5;    ... % shape
    ...2.5     1       20;    ... % shape
    lMax    lMax    lMax;	... % lapse
    bot     bot     bot];       % lower asymptote

% confidence interval and repetitions for Weibull fit bootstrapping
ci = 95;
ciN = 100;

% initial values and boundaries for exponential fitting
pInits = [ ...
    10,     1,      100;    ... % lower asymptote
    50,     1,      200;    ... % coefficient
    0.5,    0.001,  .999];      % base

% details for exponential fitting
opt = optimset( ...
    'LargeScale', 'off', ...
    'Display', 'off', ...
    'MaxFunEvals', 1000, ...
    'MaxIter', 1000, ...
    'TolFun', .001, ...
    'TolX', .001, ...
    'DiffMinChange', 0, ...
    'DiffMaxChange', 10);

dayLim = [.9,nd+1];

% axes for thresh, lapse, shape, and bottom per session
axT = subplot(5,1,1, ...'YLim', fitCon(1,2:3).*[.9 1.1], ...
    'YScale', 'log', 'XLim', dayLim, 'XTick', allDay);
title(axT, FIRA.allHeaders(1).subject(2:end))
ylabel(axT, 'thresh (+/- 95%)')

axL = subplot(5,1,2, ...'YLim', [0 lMax], ...
    'XLim', dayLim, 'XTick', allDay);
ylabel(axL, 'lapse (measured)')

axB = subplot(5,1,3, ...'YLim', fitCon(2,2:3).*[.9 1.1], ...
    'XLim', dayLim, 'XTick', allDay);
ylabel(axB, 'shape (+/- 95%)')

axG = subplot(5,1,4, ...'YLim', fitCon(4,2:3).*[.9 1.1], ...
    'XLim', dayLim, 'XTick', allDay);
ylabel(axG, 'bottom (fixed)')
xlabel('session number')

% axes for showing weibull curves
axP = subplot(5,1,5, 'YLim', [0,1], 'Xlim', edges([1,end]));
ylabel(axP, 'Weibage')
xlabel('% coherence')

% markers for data types
mDayFit = '.';
mBlockFit = 'none';
mBlockQuest = 'none';

fits = cell(nd, 2);
yesterdayWasLevers = false;
switchDay = nan;
for d = 1:length(days)

    % pick out one day
    %   lump together the blocks
    daySelect = dat>days(d) & dat<days(d)+1;

    % find the blocks
    dayBlock = FIRA.ecodes.data(daySelect,eBlock);
    dayBlocks = unique(dayBlock(~isnan(dayBlock)));

    % find the switch day
    todayIsLevers = ...
        sum(daySelect & tid == 737) > sum(daySelect & tid == 738);
    if d>1 && xor(yesterdayWasLevers, todayIsLevers);
        switchDay = d;
    end
    yesterdayWasLevers = todayIsLevers;

    % show session-wide performance
    ID = [737, 738];
    for t = 1:length(ID)

        taskSelect = daySelect & tid == ID(t);
        colour = [ID(t)==738 0 ID(t)==737];

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
        else
            fitCon(3,:) = lMax;
        end

        % disp(sprintf('%d %©', d, fitCon(3,1)))

        z = n~=0;
        if any(z)
            PFD = [centers(z)', Pc(z)', n(z)'];
            [fits{d,t}, fitsCI{d,t}] = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), ...
                {ciN, ci}, fitCon);

            % weibull curve
            intStims = linspace(edges(1), edges(end), 500);
            intPF = weibu(intStims, fits{d,t});
            l = line(intStims, intPF, 'Marker', 'none', ...
                'LineStyle', '-', 'Color', colour', 'Parent', axP);

            % thresh from fit
            doff = d+.05*(t-1);
            da = [1,1,1]*doff;
            T = [fitsCI{d,t}(1,1), fits{d,t}(1), fitsCI{d,t}(1,2)];
            line(da, T, 'Marker', mDayFit, 'Color', colour, ...
                'Parent', axT, 'LineWidth', 1, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);

            % lapse
            line(doff, fits{d,t}(3), 'Marker', mDayFit, 'Color', colour, ...
                'Parent', axL, 'LineWidth', 1, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);

            % shape
            S = [fitsCI{d,t}(2,1), fits{d,t}(2), fitsCI{d,t}(2,2)];
            line(da, S, 'Marker', mDayFit, 'Color', colour, ...
                'Parent', axB', 'LineWidth', 1, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);

            % bottom
            line(doff, fits{d,t}(4), 'Marker', mDayFit, 'Color', colour, ...
                'Parent', axG, 'LineWidth', 1, ...
                'ButtonDownFcn', {@embiggen, l}, 'UserData', false);
        else
            fits{d,t} = nan*ones(4,1);
        end

        % show block-wide performance for each session
        for b = 1:dayBlocks(end)

            % pick out one block
            blockSelect = block == b & taskSelect;

            if sum(blockSelect)
                s = find(blockSelect, 1, 'first');
                n = find(blockSelect, 1, 'last');

                % Show each final thresh estimate with QUEST chi-square error
                %   offset each block by arbitrary amount
                line([1,1,1]*(d+b/20)+.5, [Thlb(n), Th(n), Thub(n)], ...
                    'Marker', mBlockQuest, 'Color', colour, 'Parent', axT);

                % calculate performance in each bin, for this block
                Pc = nan*ones(size(centers));
                n = nan*ones(size(centers));
                for ii = 1:length(centers)
                    stimSelect = coh >= edges(ii) & coh < edges(ii+1) ...
                        & blockSelect & good;
                    n(ii) = sum(stimSelect);
                    Pc(ii) = sum(correct & stimSelect)/n(ii);
                end

                % do weibull fits for this session
                z = n~=0;
                if any(z)

                    % only reestimate threshold by block
                    %   offset each block by arbitrary amount
                    blockCon(1,:) = fitCon(1,:);
                    blockCon(2,:) = fits{d,t}(2);
                    blockCon(3,:) = fits{d,t}(3);
                    blockCon(4,:) = fits{d,t}(4);

                    PFD = [centers(z)', Pc(z)', n(z)'];
                    [fit, fitCI] = ctPsych_fit(@quick4, PFD(:,1), PFD(:,2:3), ...
                        {ciN, ci}, blockCon);

                    % thresh
                    dabl = (d+b/20)+.1;
                    da = [1,1,1]*dabl;
                    T = [fitCI(1,1), fit(1), fitCI(1,2)];
                    line(da, T, 'Marker', mBlockFit, 'Color', colour, ...
                        'Parent', axT, 'LineWidth', 1, ...
                        'ButtonDownFcn', {@embiggen, l}, 'UserData', false);
                end
            end
        end
    end
    drawnow
end

% draw performance fits before and after switch
if ~isnan(switchDay)
    someDays = {1:switchDay-1, switchDay:nd};
else
    someDays = {1:nd};
end

for da = someDays
    % fit and draw exponential for levers
    colour = [0 0 1];
    leverFits = [fits{da{1},1}];
    z = ~isnan(leverFits(1,:));
    daShift = da{1}-da{1}(1)+1;
    leverP = fmincon(@exponErr, pInits(:,1), [], [], [], [], ...
        pInits(:,2), pInits(:,3), [], ...
        opt, ...
        daShift(z), leverFits(1,z));
    line(da{1}, expon(daShift, leverP), 'Marker', 'none', 'LineStyle', '-', ...
        'Color', colour, 'Parent', axT);

    % fit and draw exponential for eye
    colour = [1 0 0];
    eyeFits = [fits{da{1},2}];
    z = ~isnan(eyeFits(1,:));
    daShift = da{1}-da{1}(1)+1;
    eyeP = fmincon(@exponErr, pInits(:,1), [], [], [], [], ...
        pInits(:,2), pInits(:,3), [], ...
        opt, ...
        daShift(z), eyeFits(1,z));
    line(da{1}, expon(daShift, eyeP), 'Marker', 'none', 'LineStyle', '-', ...
        'Color', colour, 'Parent', axT);
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
