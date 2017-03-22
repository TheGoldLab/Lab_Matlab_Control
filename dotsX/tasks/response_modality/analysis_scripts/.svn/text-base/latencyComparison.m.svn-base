% plot response latency histograms
%   break down by subject and response mode

clear all
f = clf(figure(222));

% which of three quest instances to examine for each sessions?
qn = 2;

% which subjecs to look at
subs = {...
    '/Volumes/XServerData/Psychophysics/response_modality/AKM', ...
    '/Volumes/XServerData/Psychophysics/response_modality/GYL', ...
    '/Volumes/XServerData/Psychophysics/response_modality/SL', ...
    '/Volumes/XServerData/Psychophysics/response_modality/MZ', ...
    '/Volumes/XServerData/Psychophysics/response_modality/NLM', ...
    '/Volumes/XServerData/Psychophysics/response_modality/XS', ...
    };
ns = length(subs);

% bins for response latency histograms (ms)
edges = 0:10:500;
centers = edges(2:end) - edges(2)/2;

% divvy up figure realestate
rows = 2;
cols = ceil(ns/rows);
npg = rows*cols;
pw = 1/cols;
ph = 1/rows;

% bottom-left corners of major figure sub-regions
margain.x = .05;
page(1,1:npg) = repmat(linspace(margain.x, 1-pw, cols), 1, rows);
for r = 1:rows
    page(2, 1+((r-1)*cols):r*cols) = (rows-r)*ph;
end
page(3,1:ns) = 0;
page(4,1:ns) = 0;

% bottom-left corners of minor figure sub-regions (within major subregions)
%   for arranging some number of axes
nax = 2;
gap.x = pw/10;
gap.y = ph/5;
paragraph(1,1:nax) = gap.x;
paragraph(2,1:nax) = linspace(gap.y, (page(2,1)+gap.y)/2, nax);
paragraph(3,1:nax) = pw-(2*gap.x);
paragraph(4,1:nax) = (ph/2)-gap.y;

for s = 1:ns
    % axes for lever latencies
    axL(s) = axes('Position', paragraph(:,1)+page(:,s), ...
        'YTick', [], 'XLim', edges([1 end]), ...
        'Parent', f);

    % axes eye latencies
    axE(s) = axes('Position', paragraph(:,2)+page(:,s), ...
        'XTick', [], 'YTick', [], 'Parent', f);
end

% label only the y-axes on the left side of each page
for s = [1, min(floor(npg/2)+1, ns)];
    ylabel(axL(s), sprintf('P_l_a_t_e_n_c_y | lever'))
    set(axL(s), 'YTickMode', 'auto')

    ylabel(axE(s), sprintf('P_l_a_t_e_n_c_y | eye'))
    set(axE(s), 'YTickMode', 'auto')
end

for s = 1:ns
    xlabel(axL(s), 'latency (ms)')
end

for s = 1:ns
    clear global FIRA
    modalityMetaFIRA(qn, subs{s})
    global FIRA

    eTask = strcmp(FIRA.ecodes.name, 'oc_taskID');
    tid = FIRA.ecodes.data(:, eTask);

    eDate = strcmp(FIRA.ecodes.name, 'oc_date');
    dat = FIRA.ecodes.data(:,eDate);
    dats = unique(dat);
    day = floor(FIRA.ecodes.data(:,eDate));
    days = unique(day);

    eGood = strcmp(FIRA.ecodes.name, 'good_trial');
    good = FIRA.ecodes.data(:,eGood);

    eCorrect = strcmp(FIRA.ecodes.name, 'correct');
    correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

    % get coh as recorded by low quest
    eCoh = strcmp(FIRA.ecodes.name, 'dot_coh_low_used');
    coh = FIRA.ecodes.data(:,eCoh);

    % get response latencies
    eLate = strcmp(FIRA.ecodes.name, 'oc_latency');
    late = FIRA.ecodes.data(:,eLate);

    % get response direction codes
    eResponse = strcmp(FIRA.ecodes.name, 'oc_response');
    response = FIRA.ecodes.data(:,eResponse);

    % how many sessions?
    nd = length(days);
    allDay = 1:nd;

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
        title(axE(s), sprintf('%s', subName));

        % find the switch day
        todayIsLevers = ...
            sum(leverage) > sum(eyeage);
        if d>1 && xor(yesterdayWasLevers, todayIsLevers);
            switchDay = d;
        end
        yesterdayWasLevers = todayIsLevers;

        % show normalized histograms for Lever trial response latencies
        %   all trials
        %   correct vs incorrect
        %   left vs right or down vs up
        %   super or sub threshold
        histAllL = hist(late(tid==737 & good), edges);
        line(edges, histAllL/sum(histAllL), 'Color', [0 0 0], ...
            'LineWidth', 3, 'Parent', axL(s))

        histCorrectL = hist(late(tid==737 & good & correct), edges);
        line(edges, histCorrectL/sum(histCorrectL), 'Color', [0 1 0], ...
            'LineWidth', 1, 'Parent', axL(s))
        histIncorrectL = hist(late(tid==737 & good & ~correct), edges);
        line(edges, histIncorrectL/sum(histIncorrectL), 'Color', [1 0 0], ...
            'LineWidth', 1, 'Parent', axL(s))

        % left=0, right=1
        histLeftL = hist(late(tid==737 & good & response==0), edges);
        line(edges, histLeftL/sum(histLeftL), 'Color', [1 1 0], ...
            'LineWidth', 1, 'Parent', axL(s))
        histRightL = hist(late(tid==737 & good & response==1), edges);
        line(edges, histRightL/sum(histRightL), 'Color', [0 0 1], ...
            'LineWidth', 1, 'Parent', axL(s))

        % same for eye trials
        histAllE = hist(late(tid==738 & good), edges);
        line(edges, histAllE/sum(histAllE), 'Color', [0 0 0], ...
            'LineWidth', 3, 'Parent', axE(s))

        histCorrectE = hist(late(tid==738 & good & correct), edges);
        line(edges, histCorrectE/sum(histCorrectE), 'Color', [0 1 0], ...
            'LineWidth', 1, 'Parent', axE(s))
        histIncorrectE = hist(late(tid==738 & good & ~correct), edges);
        line(edges, histIncorrectE/sum(histIncorrectE), 'Color', [1 0 0], ...
            'LineWidth', 1, 'Parent', axE(s))

        % down=0, up=1
        histDownE = hist(late(tid==738 & good & response==0), edges);
        line(edges, histDownE/sum(histDownE), 'Color', [1 1 0], ...
            'LineWidth', 1, 'Parent', axE(s))
        histUpE = hist(late(tid==738 & good & response==1), edges);
        line(edges, histUpE/sum(histUpE), 'Color', [0 0 1], ...
            'LineWidth', 1, 'Parent', axE(s))
    end
    drawnow
end

% thing
legend(axL(1), {'all', '| correct', '| incorrect', '| left', '| right'})
legend(axE(1), {'all', '| correct', '| incorrect', '| down', '| up'})

% stuff
yL = get(axL, 'YLim');;
yE = get(axE, 'YLim');
ymx = max([yL{:}, yE{:}]);
set([axL, axE], 'YLim', [0, ymx]);