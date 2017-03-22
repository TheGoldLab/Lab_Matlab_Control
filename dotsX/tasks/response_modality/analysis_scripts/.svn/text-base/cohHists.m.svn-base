clear global FIRA
clear all
global FIRA
modalityMetaFIRA(2)

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = ~isnan(FIRA.ecodes.data(:,eGood));

% get coh as recorded by low quest
eCoh = strcmp(FIRA.ecodes.name, 'dot_coh_low_used');
coh = FIRA.ecodes.data(:,eCoh);

% bin coherences
edges = ([0, 90, 100]);
%edges = unique(prctile(coh, 0:5:100));

eTask = strcmp(FIRA.ecodes.name, 'oc_taskID');
tid = FIRA.ecodes.data(:, eTask);

% find the switch day
eDate = strcmp(FIRA.ecodes.name, 'oc_date');
dat = FIRA.ecodes.data(:,eDate);
dats = unique(dat);
day = floor(FIRA.ecodes.data(:,eDate));
days = unique(day);
nd = length(days);

yesterdayWasLevers = false;
switchDay = nan;
preSwitch = logical(zeros(size(dat)));
for d = 1:nd

    % pick out one day
    %   lump together the blocks
    daySelect = dat>days(d) & dat<days(d)+1;

    % find the switch day
    todayIsLevers = ...
        nansum(daySelect & tid == 737) > nansum(daySelect & tid == 738);
    if d>1 && xor(yesterdayWasLevers, todayIsLevers);
        switchDay = d;
    end
    preSwitch(daySelect) = isnan(switchDay);

    yesterdayWasLevers = todayIsLevers;
end

% show data before [and after] the switch
if isnan(switchDay)
    da = {preSwitch};
else
    da = {preSwitch, ~preSwitch};
end

% plot the histcograms
clf(figure(623))

cm = [ ...
    .2  .2  1; ...
    1   0   0; ...
    ];
colormap(cm);

prefix = {'BEFORE', 'AFTER'};
w = 4;

ld = length(da);
for ii = 1:ld

    % hitogram the stimuli
    levers_all = histc(coh(tid==737&good&da{ii}), edges);
    levers_correct = histc(coh(tid==737&good&correct&da{ii}), edges);
    levers_Pc = levers_correct./levers_all;

    eyes_all = histc(coh(tid==738&good&da{ii}), edges);
    eyes_correct = histc(coh(tid==738&good&correct&da{ii}), edges);
    eyes_Pc = eyes_correct./eyes_all;

    % all stims
    s(1) = subplot(2*ld,1,2*ii-1);
    b=bar(edges, [levers_all, eyes_all], w);
    title(sprintf('%s: all stimuli %s', ...
        FIRA.allHeaders(1).subject(2:end), prefix{ii}))
    legend({'levers', 'eyes'})
    
    % down in front!
    if nansum(eyes_all) > nansum(levers_all)
        set(s(1), 'Children', b);
    else
        set(s(1), 'Children', fliplr(b));
    end

    % proportion correct
    s(2) = subplot(2*ld,1,2*ii);
    b=bar(edges, [levers_Pc, eyes_Pc], w);
    title(sprintf('%s: proportion correct %s', ...
        FIRA.allHeaders(1).subject(2:end), prefix{ii}))

    % down in front!
    if nansum(eyes_Pc) > nansum(levers_Pc)
        set(s(2), 'Children', b);
    else
        set(s(2), 'Children', fliplr(b));
    end

    % estimate slopiness of histcogram
    line(edges, levers_Pc, 'Color', cm(1,:), 'LineStyle', 'none')
    line(edges, eyes_Pc, 'Color', cm(2,:), 'LineStyle', 'none')
    l = lsline;

    % come on, now
    set(s, 'XLim', [0,100])
    set(s(2), 'YLim', [0,1])
end