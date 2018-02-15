%% RealDataPilot
%
% This script is using some pilot data I recorded on myself to verify the
% differences in threshold determined by QUEST and using a method of
% constant stimulus. Furthermore, this script also examine the differences
% in timing recorded during a real experimental run. The Palamedes Toolbox
% 1.8.2 will be used for psychometric curve fitting.
%
% 9/22/17    xd  wrote it

% clearvars; close all;
%% File names
fileNames = {'Xiaomao' 'Justin' 'Yunshu'};

%% Load psychophysics data
h = figure('Position',[0 0 1200 1200]);
for ff = 1:length(fileNames)
%     cohData{ff} = load(['MatlabState_' fileNames{ff} 'Coherence']);
%     questData{ff} = load(['MatlabState_' fileNames{ff} 'QUEST']);
%     satData{ff} = load(['MatlabState_' fileNames{ff} 'SATBIAS']);
%     
    % Extract relevant variables from the state object
    q = questData{ff}.state{'Quest'}{'object'};
    stimLevels = cohData{ff}.state{'Coherence'}{'coherences'};
    trials = cohData{ff}.state{'Coherence'}{'trials'};
    trials = cell2mat(trials);
    
    %% Generate parameters for psychometric fit
    %
    % First we will remove NaN trials from the data set (noting the number
    % there were). Then we will organize the performance into a format suitable
    % for Palamedes.
    nanTrials = isnan([trials.response]);
    trials(nanTrials) = [];
    
    fprintf('%d trials were invalid!\n',sum(nanTrials));
    
    numPos = zeros(size(stimLevels));
    outOfNum = zeros(size(stimLevels));
    
    for ii = 1:length(stimLevels)
        stimIdx = [trials.coherence] == stimLevels(ii);
        numPos(ii) = sum([trials(stimIdx).response]);
        outOfNum(ii) = sum(stimIdx);
    end
    
    %% Fit psychometric function
    
    PF = @PAL_Weibull;
    paramsFree = [1 1 0 0];
    params = [10 5 0.5 0];
    
    [paramsValues LL exitflag] = PAL_PFML_Fit(stimLevels,numPos,outOfNum,params,paramsFree,PF);
    
    threshold = PF(paramsValues, 0.82, 'inverse');
    
    coherenceFine = stimLevels(1):0.01:stimLevels(end);
%     figure; 
    subplot(3,3, ff);
    hold on;
    plot(coherenceFine,PF(paramsValues,coherenceFine),'LineWidth',2);
    plot(stimLevels,numPos ./ outOfNum,'ko','MarkerSize',20);
    
    psiParamsIndex = qpListMaxArg(q.posterior);
    psiParamsQuest = q.psiParamsDomain(psiParamsIndex,:);
    % psiParamsFit = qpFit(q.trialData,q.qpPF,psiParamsQuest,q.nOutcomes,...
    %     'lowerBounds', [0 2 0.5 0],'upperBounds',[100 5 0.5 0.04]);
    
    questThreshold = psiParamsQuest(1);
    h1 = plot([questThreshold questThreshold],[0 PF(paramsValues,questThreshold)],'LineWidth',2);
    h2 = plot([threshold threshold],[0 0.82],'LineWidth',2);
    if ff == 1
        legend([h1, h2], {'QUEST' 'Const stim'},'Location','southeast');
    end
    axis square
    xlim([stimLevels(1) stimLevels(end)]);
    set(gca,'FontSize',16,'LineWidth',2);
    xlabel('Coherence','FontSize',18);
    ylabel('Fraction Correct','FontSize',18);
    
    
    %% Do SAT/BIAS Stuff
    trials = satData{ff}.state{'SAT/BIAS'}{'trials'};
    contexts = satData{ff}.state{'SAT/BIAS'}{'contexts'};
    
    contextSpecificTrials = cell(size(contexts));
    [sortedContexts,sortIdx] = sort(contexts);
    
    for ii = 1:length(contexts)
        s = (ii - 1) * satData{ff}.state{'SAT/BIAS'}{'trialsPerContext'} + 1;
        e = ii * satData{ff}.state{'SAT/BIAS'}{'trialsPerContext'};
        
        trialMat = cell2mat(trials(s:e));
        trialMat(isnan([trialMat.response])) = [];
        contextSpecificTrials{ii} = trialMat;
    end
    
    % Get speed trials
    sTrials = strcmp(contexts,'S');
    sTrials = contextSpecificTrials(sTrials);
    aTrials = strcmp(contexts,'A');
    aTrials = contextSpecificTrials(aTrials);
    
%     figure; 
	subplot(3,3,3 + ff);
    hold on;
    
    for ii = 1:length(sTrials)
        trials = sTrials{ii};
        rt = [trials.mglStimFinishTime] - [trials.mglStimStartTime];
        acc = sum([trials.response]) / length([trials.response]);
        h1 = plot(mean(rt),mean(acc),'or');
    end
    
    for ii = 1:length(aTrials)
        trials = aTrials{ii};
        rt = [trials.mglStimFinishTime] - [trials.mglStimStartTime];
        acc = sum([trials.response]) / length([trials.response]);
        h2 = plot(mean(rt),mean(acc),'ob');
    end
    
    mRT = satData{ff}.state{'MeanRT'}{'value'};
    plot([mRT mRT],[0 1],'k');
    
    axis square;
    ylim([0.5 1]);
    xlim([0.4 2.5]);
    set(gca,'FontSize',16,'LineWidth',2);
    xlabel('Reaction Time','FontSize',18);
    ylabel('Fraction Correct','FontSize',18);
    if ff == 1
        legend([h1,h2], {'Speed','Accuracy'},'Location','southeast');
    end
    %% Get bias trials
    t1Trials = strcmp(contexts,'T1');
    t1Trials = contextSpecificTrials(t1Trials);
    t2Trials = strcmp(contexts,'T2');
    t2Trials = contextSpecificTrials(t2Trials);
    
%     figure; 
    subplot(3,3,6 + ff);
    hold on;
    for ii = 1:length(t1Trials)
        trials = t1Trials{ii};
        directions = [trials.direction];
        response = [trials.response];
        
        leftDir = directions == 180;
        rightDir = ~leftDir;
        
        percentLeft = sum(response(leftDir)) + sum(~response(rightDir));
        percentLeft = percentLeft / length(response);
        
        h1 = bar(ii,percentLeft,'r');
        
    end
    
    for ii = 1:length(t2Trials)
        trials = t2Trials{ii};
        directions = [trials.direction];
        response = [trials.response];
        
        leftDir = directions == 180;
        rightDir = ~leftDir;
        
        percentLeft = sum(response(leftDir)) + sum(~response(rightDir));
        percentLeft = percentLeft / length(response);
        
        h2 = bar(ii+2,percentLeft,'b');
        
    end
    
    plot([0 5],[0.5 0.5],'k');
    plot([0 5],[0.66 0.66],'k--');
    plot([0 5],[0.34 0.34],'k--');
    
    axis square;
    ylim([0 1]);
    xlim([0 5]);
    set(gca,'FontSize',16,'LineWidth',2,'XTickLabel',{});
    ylabel('Percent Left','FontSize',18);
    xlabel('Block','FontSize',18);
    if ff == 1
        legend([h1,h2], {'3:1','1:3'},'Location','northeast');
    end
    
end
set(h, 'PaperPositionMode', 'auto');

set(h,'Units','Inches');
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);