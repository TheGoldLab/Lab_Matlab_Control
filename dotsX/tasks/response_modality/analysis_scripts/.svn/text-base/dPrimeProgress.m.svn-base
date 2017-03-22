function [f, axises] = dPrimeProgress(dir)

% pick a stimulus intensity near d' = .5 - 1 for the first session.
% Compare d' on subsequient sessions at this intensity.  This is like
% figure 3 from Fine and Jacobs 2002.  Use mainstream modality only.

if ~nargin
    dir = true;
end

% load data
clear global FIRA
concatenateFIRAs(dir);

% avoid annoying errors
global FIRA
if isempty(FIRA)
    f = nan;
    axises = nan;
    return
end

% make new multisession ecodes, get basic summary data
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(100,30);

% get common data structure, d
d = getCommonDataTypes(subjects, blockNum, sessionID);
cohs = [3.2 6.4 12.8 25.6 51.2 99];
nc = length(cohs);

% if length(d.epochs >=2)
%     sessions = 1:(d.epochs(2)-1);
% else
    sessions = unique(sessionID)';
% end
ns = length(sessions);
sAxis = [.7 10+1];

% pick quantile bins for RT
nt = 2;
tBin = prctile(d.RT, linspace(5, 90, nt+1));

% get just the mainstrem response modality
TID = mode(taskID);

% organize responses as Hits ("right"|Right) or ("up"|Up)
%   and False Alarms ("right"|Left) or ("up"|Down)
hit = (~isnan(d.right) | ~isnan(d.up)) & d.correct;
falseAlarm = (~isnan(d.left) | ~isnan(d.down)) & ~d.correct;

% get H, F, d', and L
%   for each session, at each coherence, at each time bin
%   for first session, L === 1.
H = nan*zeros(ns, nc, nt);
F = nan*zeros(ns, nc, nt);
dprime = nan*zeros(ns, nc, nt);
L = nan*zeros(ns, nc, nt);
for ss = sessions

    % select one session's main modality
    sessionSelect = d.good & sessionID == ss & taskID == TID;

    % get d prime from Hit and False Alarm,
    %   for each coh and each RT bin
    for cc = 1:nc

        cohSelect = d.coh == cohs(cc);

        for tt = 1:nt

            RTSelect = d.RT >= tBin(tt) & d.RT < tBin(tt+1);

            awesomeSelect = sessionSelect & cohSelect & RTSelect;

            if sum(awesomeSelect) > 10
                l = .01;
                h = .99;
                H(ss,cc,tt) = max(l,min(h,mean(hit(awesomeSelect))));
                F(ss,cc,tt) = max(l,min(h,mean(falseAlarm(awesomeSelect))));
                dprime(ss,cc,tt) = ...
                    (norminv(H(ss,cc,tt)) - norminv(F(ss,cc,tt))) / sqrt(2);
                L(ss,cc,tt) = dprime(ss,cc,tt) / dprime(1,cc,tt);
            end
        end
    end
end

% show learning rate across sessions
%   for each coherence, for each RT
f = figure(654);
clf(f);

axL = axes('XLim', sAxis, 'XTick', d.epochs, 'XGrid', 'on', ...
    'YLim', [-2, 5], 'YGrid', 'on', ...
    'Parent', f);
title(axL, subjects{1})
xlabel(axL, 'session')
ylabel(axL, 'd''')
axises = axL;

% plot session line for coh and each RT bin
ls = {'-', ':', '--', '-.'};
lw = [1 1.5 1 1.5];
mk = {'s', '.', '+', 'o'};
top = 5;
div = 5;
for cc = 1:nc

    col = [dec2bin(cc,3) == '1']*.8;

    % make a coherence legend
    text(1, top-cc/div, sprintf('%.1f', cohs(cc)), ...
        'Color', col, 'Parent', axL)

    for tt = 1:nt
        line(sessions, dprime(:,cc,tt), ...
            'Color', col, 'Marker', mk{tt}, ...
            'LineStyle', ls{tt}, 'LineWidth', lw(tt), ...
            'Parent', axL);

        if cc == 1
            % make a time bin legend
            line([2 3], [1 1]*(top-tt/div), ...
                'Color', [0 0 0], 'Marker', mk{tt}, ...
                'LineStyle', ls{tt}, 'LineWidth', lw(tt), ...
                'Parent', axL);

            text(3.3, top-tt/div, ...
                sprintf('%.0f - %.0f ms', 1000*tBin(tt), 1000*tBin(tt+1)), ...
                'Color', [0 0 0], 'Parent', axL)

        end
    end
end