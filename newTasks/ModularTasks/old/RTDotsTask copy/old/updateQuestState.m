function updateQuestState(state)
% updateQuestState(state)
% 
% This function checks the results of the previous QUEST trial to update
% the QUEST object as well as the associated counters and flags.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/18/17    xd  wrote it

%% Read relevant fields
q         = state{'Quest'}{'object'};
counter   = state{'Quest'}{'counter'};
trials    = state{'Quest'}{'trials'};
numTrials = state{'Quest'}{'numTrials'};

%% Update fields

% If the trial response is not a NaN, then update the quest object
trial = trials{counter};
if ~isnan(trial.response)
%     q = QuestUpdate(q,result.coherence,result.response);

    % We add 1 to the trial response because Quest+ uses 1 and 2 for
    % response values instead of 0 and 1.
    q = qpUpdate(q,trial.coherence,trial.response + 1); 
end

% Increment the quest counter. If the quest counter exceeds the number of
% desired trials, we will set the QUEST flag to false which tell the
% program to present the real trials. Additionally, we will set the
% stimulus threshold to the value derived from Quest if indicated to do so
% by the flag and update the coherence in all trials to this threshold.
counter = counter + 1;
if counter > numTrials
    state{'Flag'}{'QUEST'} = false;

    useQuestThreshold = state{'SAT/BIAS'}{'useQuestThreshold'};
    if useQuestThreshold
        psiParamsIndex = qpListMaxArg(q.posterior);
        psiParamsQuest = q.psiParamsDomain(psiParamsIndex,:);
        threshold = psiParamsQuest(1);
%         threshold = QuestMean(q);
        state{'SAT/BIAS'}{'coherenceThreshold'} = threshold;
        
        % Since we are using the Quest derived threshold, we need to update
        % the coherence values for the pregenerated trials for the task.
        trials = state{'SAT/BIAS'}{'trials'};
        for ii = 1:length(trials)
            trials{ii}.coherence = threshold;
        end
        state{'SAT/BIAS'}{'trials'} = trials;
        
        % Similarly, if we are testing for the subject's RT, we need to
        % update those trials' coherence with the value found here.
        findRT = state{'Flag'}{'meanRT'};
        if findRT
            trials = state{'MeanRT'}{'trials'};
            for ii = 1:length(trials)
                trials{ii}.coherence = threshold;
            end
            state{'MeanRT'}{'trials'} = trials;
        end
    end
    
    save('tempSaveFile','state');
end

% Update values in state object
state{'Quest'}{'object'} = q;
state{'Quest'}{'counter'} = counter;

end

