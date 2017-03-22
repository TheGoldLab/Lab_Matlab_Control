function [times, vars] = RTFixVar(dr, tt)
% look at the variability of eye position during fixation.
%   vs time of day
%   vs time within session?
%   etc
%
%   do analysis for one subject and one task,
%   and pass the result up to a caller.

if ~nargin
    dr = true;
end
if nargin < 2
    tt = 1;
end

% load data
clear global FIRA
global FIRA
concatenateFIRAs(dr);

% make new multisession ecodes, get basic summary data
[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects, times] = findFIRASessionsAndBlocks(100,30);
sessions = unique(sessionID)';
ns = length(sessions);

% get common data structure, d
d = getCommonDataTypes(subjects, blockNum, sessionID);

% get asl camera frame rate
dXasl = struct(FIRA.allHeaders(1).session.dXasl);

vars.sessXMeanVar = nan*zeros(1,ns);
vars.sessXVarMean = nan*zeros(1,ns);
vars.sessYMeanVar = nan*zeros(1,ns);
vars.sessYVarMean = nan*zeros(1,ns);
vars.sessRMeanVar = nan*zeros(1,ns);
vars.sessRVarMean = nan*zeros(1,ns);
vars.sessXVar = nan*zeros(1,ns);
vars.sessYVar = nan*zeros(1,ns);
vars.sessRVar = nan*zeros(1,ns);
for ss = sessions

    select = d.good & taskID' == tt & ss == sessionID;

    % concatenate eyepos during fixation
    %   for all trials in this session and task
    nt = sum(select);
    n = 1;
    trialXMean = nan*zeros(1,nt);
    trialXVar = nan*zeros(1,nt);
    trialRVar = nan*zeros(1,nt);
    trialYMean = nan*zeros(1,nt);
    trialYVar = nan*zeros(1,nt);
    trialRVar = nan*zeros(1,nt);
    allTrialsX = [];
    allTrialsY = [];
    allTrialsR = [];
    for ii = find(select)'

        % get asl data for this trial
        asl = FIRA.aslData{ii};

        % align asl time with ecode time
        %   correct for frame number overrun
        %   this probably belongs in dXasl/saveToFIRA
        aslTime = asl(:,4)-asl(1,4);
        over = find(aslTime < 0, 1, 'first');
        if ~isempty(over)
            aslTime(over:end) = ...
                aslTime(over:end) - aslTime(over) + aslTime(over-1) + 1;
        end
        wrtOffset = FIRA.ecodes.data(ii,4) - FIRA.ecodes.data(ii,2);
        aslTime = (aslTime / dXasl.freq) - wrtOffset;

        % select the time of fixation
        %   from 0.5s before stim on (following acquisition)
        %   until 0.05s before left, right, or choice (RT)
        fixStart = d.showStim(ii)/1000 - 0.500;
        fixEnd = d.RT(ii)/1000 - 0.050;
        fixSelect = asl(:,5) ~= 1 ...
            & aslTime >= fixStart & aslTime <= fixEnd;
        
        trialX = asl(fixSelect,2);
        trialY = asl(fixSelect,3);
        trialR = (trialX.^2 + trialY.^2).^(1/2);

        % mean and variance within trial
        trialXMean(n) = mean(trialX);
        trialXVar(n) = var(trialX);
        trialYMean(n) = mean(trialY);
        trialYVar(n) = var(trialY);
        trialRMean(n) = mean(trialR);
        trialRVar(n) = var(trialR);

        n = n + 1;
        
        % all trials together
        allTrialsX = cat(1, allTrialsX, trialX);
        allTrialsY = cat(1, allTrialsY, trialY);
        allTrialsR = cat(1, allTrialsR, trialR);
    end

    % mean of the trial variances
    vars.sessXMeanVar(ss) = mean(trialXVar);
    vars.sessYMeanVar(ss) = mean(trialYVar);
    vars.sessRMeanVar(ss) = mean(trialRVar);

    % variance among the trial means
    vars.sessXVarMean(ss) = var(trialXMean);
    vars.sessYVarMean(ss) = var(trialYMean);
    vars.sessRVarMean(ss) = var(trialRMean);
    
    % variance in total
    vars.sessXVar(ss) = var(allTrialsX);
    vars.sessYVar(ss) = var(allTrialsY);
    vars.sessRVar(ss) = var(allTrialsR);
end