%function [f, axises] = fineProgress(dr)
% show d' per session

%if ~nargin
dr = false;
%end

% load data
clear global FIRA
concatenateFIRAs(dr);

% avoid annoying errors
global FIRA
if isempty(FIRA)
    f = nan;
    axises = nan;
    return
end

% make new multisession ecodes, get basic summary data
[tasks, taskID, allNames] = unifyFIRATaskNames;
tids = unique(taskID)';

[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(20,20);
sessions = unique(sessionID)';
ns = max(sessions);
sAxis = [.7, ns+1];

% return figure to caller
f = figure(5688);
clf(f);

% for plotting d prime
axd = subplot(3,1,1, 'XLim', sAxis, 'XTick', sessions, ...
    'YGrid', 'on');
title(axd, subjects{1})
ylabel(axd, 'd''')

% for plotting tables of probabilities
noTick = {'XTick', [], 'YTick', []};
for ss = sessions
    axP_eye(ss) = subplot(3,ns,ss+ns, noTick{:});
    axP_lever(ss) = subplot(3,ns,ss+(2*ns), noTick{:});
end
rowNames = {'S', 'D1', 'D2', 'tot'};
colNames = {'"s"', '"d"', 'tot'};
format = '%.2f';
colorMap = 'summernight';
textColor = [0 0 0];

% return all axises to caller
axises = [axd axP_lever, axP_eye];

% complete and good trials
eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data(:,eGood);
good(isnan(good)) = false;
good = logical(good);

% correct
eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(FIRA.ecodes.data(:,eCorrect));

% 2afc condition
e2afc = strcmp(FIRA.ecodes.name, 'different_interval');
different = FIRA.ecodes.data(:,e2afc);

eTrialNum = strcmp(FIRA.ecodes.name, 'trial_num');
trialNum = FIRA.ecodes.data(:,eTrialNum);

% look at lever task and eye task for all sessions
leverSelect = taskID == find(strcmp(tasks,'FineDiscrimLever')) ...
    | taskID == find(strcmp(tasks,'FineDiscrimination'));

eyeSelect = taskID == find(strcmp(tasks,'FineDiscrimEye'));

for taskSelect = [leverSelect, eyeSelect];

    % check for eye or lever
    switch allNames{find(taskSelect, 1)}

        case {'FineDiscrimLever', 'FineDiscrimination'}
            % use blue for lever
            col = [0, 0, 1];
            axP = axP_lever;
            modality = 'lever';

        case 'FineDiscrimEye'
            % use red for eye
            col = [1, 0, 0];
            axP = axP_eye;
            modality = 'eye';

    end

    for ss = sessions

        % select one session and one task
        %   ignore the first several trials of each block
        select = good & (trialNum>5) & taskSelect & (sessionID==ss);

        if ~any(select)
            dprime(ss) = nan;
            continue
        end

        % get response frequency for each of 6 cases:
        %   responses s and d
        %   stimuli S, D1, D2
        N = sum(select);
        Ps_S = sum(correct(select & different==0))/N;
        Pd_S = sum(~correct(select & different==0))/N;

        Ps_D1 = sum(~correct(select & different==1))/N;
        Pd_D1 = sum(correct(select & different==1))/N;

        Ps_D2 = sum(~correct(select & different==2))/N;
        Pd_D2 = sum(correct(select & different==2))/N;

        % To compute d prime for this same-different task, I read chapters
        %   6-9 of Macmillan and Creelman, "Detection Theory: a user's
        %   guide".

        % Since this task never uses different-different trials, the best
        %   decision rule is the likelihood rule like in in figure 8.6b.
        %   The corner rule, like in figure 8.6a, is very similar and
        %   easier to solve for d prime.

        % In my solution, I assume the two task intervals are treated
        %   symmetrically (i.e. Pd_D1 = Pd_D2) (even though this was not
        %   really true for BSH data).  In that sense, they are independent
        %   observaions using of equally detectable stimuli with equal
        %   response criteria (i.e. d'1 = d'2 and k1 = k2).
        
        % So here is the solution, d'(H,F), 
        %   we *need not make any assumptions about bias*
        %   that's a good thing
        Phit = mean(correct(select & different~=0));
        Pfa = mean(~correct(select & different==0));
        dprime(ss) = ...
            norminv(sqrt(1-Pfa)) - norminv((1-Phit)/sqrt(1-Pfa));

        % make a table of 6 response probabilites with margiainals
        P = [ ...
            Ps_S,   Pd_S,	Ps_S+Pd_S; ...
            Ps_D1,  Pd_D1,	Ps_D1+Pd_D1; ...
            Ps_D2,	Pd_D2,	Ps_D2+Pd_D2; ...
            Ps_S+Ps_D1+Ps_D2,Pd_S+Pd_D1+Pd_D2,1; ...
            ];

        % plot the table with my sweet new function
        %   looking for bias to explain poor performance
        s = surfTable(P, rowNames, colNames, format, ...
            colorMap, textColor, axP(ss));
        text(2, 5.2, sprintf(['Pc=',format], Ps_S+Pd_D1+Pd_D2), ...
            'Parent', axP(ss));
    end

    % show d' over sessions for this task
    line(sessions, dprime, 'Marker', '.', 'LineStyle', 'none', ...
        'Color', col, 'Parent', axd);

    % label the d prime traces by modality
    first = find(~isnan(dprime), 1, 'first');
    text(first-.2, dprime(first), modality, 'Color', col, 'Parent', axd);
end

% label the leftmost P axes by modality
ylabel(axP_eye(1), 'eye')
ylabel(axP_lever(1), 'lever')