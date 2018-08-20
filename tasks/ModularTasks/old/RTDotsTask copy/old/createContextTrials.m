function createContextTrials(state)
% createContextTrials(state)
% 
% This function will generate the trials for all the contexts in the
% SAT/BIAS task. They will all be generated in blocks since the
% experimental paradigm calls for a switch and instruction update at the
% start of each block.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/21/17    xd  wrote it

%% Pull necessary parameters
trialsPerContext = state{'SAT/BIAS'}{'trialsPerContext'};
coherenceThreshold = state{'SAT/BIAS'}{'coherenceThreshold'};
contexts = state{'SAT/BIAS'}{'contexts'};

%% Generate the trials
coherence = coherenceThreshold * ones(length(contexts) * trialsPerContext,1);
direction = zeros(size(coherence));
for ii = 1:length(contexts)
    % Calculate the index to insert the 30 trials
    sIdx = (ii - 1) * trialsPerContext + 1;
    eIdx = ii * trialsPerContext;
    
    % Use a switch statement to classify the context and generate an
    % appropriate subvector of directions
    switch contexts{ii}
        case {'A' 'S'}
            cDir = zeros(trialsPerContext,1);
            cDir(1:end/2) = 180;
        case 'T1'
            numT1 = floor(0.75 * trialsPerContext) + (rand > 0.5);
            cDir = zeros(trialsPerContext,1);
            cDir(1:numT1) = 180;
        case 'T2'
            numT2 = floor(0.75 * trialsPerContext) + (rand > 0.5);
            cDir = zeros(trialsPerContext,1);
            cDir(numT2+1:end) = 180;
    end
    
    % Shuffle and insert trials into main direction vector
    cDir = cDir(randperm(length(cDir)));
    direction(sIdx:eIdx) = cDir;
end

%% Turn coherence and directions into struct cell array
contexts = repmat(contexts',trialsPerContext,1);
trials = [coherence direction];
trials = num2cell(cell2struct([num2cell(trials),contexts(:)],{'coherence','direction','context'},2));
state{'SAT/BIAS'}{'trials'} = trials;

end

