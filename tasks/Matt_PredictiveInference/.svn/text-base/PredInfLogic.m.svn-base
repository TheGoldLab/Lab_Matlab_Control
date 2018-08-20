classdef PredInfLogic < handle
    % This class defines numeric and logical behaviors for the Predictive
    % Inference task by Matt Nasser.
    %
    % This class should be portable, so that multiple versions of the task
    % can reuse this same core.  It should be pure Matlab code, so it
    % should not "know about" Tower of Psych or Snow Dots.  In general, it
    % it should not care about timing, flow control, graphics, or how the
    % subject interacts with the task.  It should just do math and
    % bookkeeping.
    %
    % Ben Heasly created this in 2011, based on Matt Nasser's
    % configurePredInfTask.m from 2010
    %
    
    properties
        % a name to identify this session
        name = '';
        
        % a time to identify this session
        time = 0;
        
        % the number of blocks to run
        nBlocks = 1;
        
        % a standard deviation for each block
        blockStds = 0;
        
        % a hazard rate for each block
        blockHazards = 0;
        
        % number of zero-hazard trials following a change trial
        safetyTrials = 1;
        
        % number of trials within each block
        trialsPerBlock = 1;
        
        % whether to shuffle the order of blockStds and blockHazards
        isBlockShuffle = false;
        
        % a list of outcomes to choose sequentially, instead of randomly
        fixedOutcomes = [];
        
        % seed for initializing random number generators
        randSeed = 0;
        
        % maximum value for randomly chosen outcomes
        maxOutcome = 1;
        
        % whether to reset subject's prediction each trial
        isPredictionReset = false;
        
        % whether to limit subject's prediction each trial
        isPredictionLimited = true;
        
        % whether the subject is currently allowed to make a prediction
        isPredictionActive = true;
        
        % arbitrary grand count of subject's "score" per block
        blockScore = 0;
        
        % arbitrary per-trial data to include in getStatus()
        trialData = [];
        
        % "gold medal" mix of omniscient and amnesiac observer behaviors
        goldObserverWeights = [2 1];
        
        % string amount paid to subjects for "gold medal" performance
        goldPayout = '$15';
        
        % "silver medal" mix of omniscient and amnesiac observer behaviors
        silverObserverWeights = [1 2];
        
        % string amount paid to subjects for "silver medal" performance
        silverPayout = '$12';
        
        % "bronze medal" mix of omniscient and amnesiac observer behaviors
        bronzeObserverWeights = [0 1];
        
        % string amount paid to subjects for "bronze medal" performance
        bronzePayout = '$10';
        
        % name of a file that can be used for writing data
        dataFileName = 'PredInfData'
    end
    
    properties (SetAccess = protected)
        % which element of fixedOutcomes was last picked
        fixedOutcomeIndex;
        
        % index of the current block
        currentBlock;
        
        % sequence of block numbers for choosing blockStds and blockHazards
        blockSequence;
        
        % whether the current trial is a change trial
        isChangeTrial;
        
        % running count of trials since the last change trial (1-based)
        steadyTrials;
        
        % remaining safety trials since the last change trial
        remainingSafety;
        
        % change hazard rate used in the current trial
        currentHazard;
        
        % std of the outcome distribution used in the current trial
        currentStd;
        
        % mean of the outcome distribution used in the current trial
        currentMean;
        
        % mean of the outcome distribution used in the previous trial
        lastMean;
        
        % pick from the outcome distribution for the current trial
        currentOutcome;
        
        % pick from the outcome distribution from the previous trial
        lastOutcome;
        
        % subject's pick for the current trial
        currentPrediction;
        
        % subject's pick from the previous trial
        lastPrediction;
        
        % subject's change in prediction for the current trial
        currentUpdate;
        
        % subject's change in prediction from the previous trial
        lastUpdate;
        
        % subject's eroor for the current trial
        currentDelta;
        
        % subject's eroor from the previous trial
        lastDelta;
        
        % subject's leaning rate for the current trial
        currentAlpha;
        
        % subject's leaning rate from the previous trial
        lastAlpha;
        
        % whether the current trial is good and complete
        isGoodTrial;
        
        % running count of good trials in each block
        blockCompletedTrials;
        
        % running count of good and bad trials in each block
        blockTotalTrials;
        
        % running sum of subject absolute errors over all blocks
        cumulativeError;
        
        % mean outcome estimated by an "omniscient" observer
        omniscientMean;
        
        % running sum of absolute errors for an "omniscient" observer
        omniscientCumulativeError;
        
        % running sum of absolute errors for an "amnesiac" observer
        amnesiacCumulativeError;
    end
    
    methods
        
        % Constructor takes no arguments.
        function self = PredInfLogic(randSeed)
            if nargin
                self.randSeed = randSeed;
            end
            self.startSession();
        end
        
        % Initialize random number functions from randSeed.
        function initializeRandomGenerators(self)
            rand('seed', self.randSeed);
            randn('seed', self.randSeed);
            %rng(self.randSeed, 'twister');
        end
        
        % Set up for the first trial of the first block.
        function startSession(self)
            self.initializeRandomGenerators();
            
            % pick straight or shuffled sequence for block parameters
            if self.isBlockShuffle
                self.blockSequence = randperm(self.nBlocks);
            else
                self.blockSequence = 1:self.nBlocks;
            end
            
            % reset session totals
            self.fixedOutcomeIndex = 0;
            self.currentBlock = 0;
            self.blockCompletedTrials = 0;
            self.blockTotalTrials = 0;
            self.cumulativeError = 0;
            self.omniscientCumulativeError = 0;
            self.amnesiacCumulativeError = 0;
        end
        
        % Set up for a new block.
        function startBlock(self)
            % increment the block and choose block parameters
            self.currentBlock = self.currentBlock + 1;
            sequenceIndex = self.blockSequence(self.currentBlock);
            self.currentStd = self.blockStds(sequenceIndex);
            self.currentHazard = self.blockHazards(sequenceIndex);
            
            % pick the first mean outcome at random
            self.pickChangeTrial();
            
            % reset trial-by-trial state
            self.isPredictionActive = true;
            self.blockScore = 0;
            self.blockCompletedTrials = 0;
            self.blockTotalTrials = 0;
            self.isChangeTrial = false;
            self.steadyTrials = 0;
            self.remainingSafety = self.safetyTrials;
            halfWay = round(self.maxOutcome ./ 2);
            self.omniscientMean = halfWay;
            self.currentOutcome = nan;
            self.currentPrediction = halfWay;
            self.currentUpdate = 0;
            self.currentDelta = 0;
            self.currentAlpha = 0;
            self.lastMean = nan;
            self.lastOutcome = nan;
            self.lastPrediction = nan;
            self.lastUpdate = 0;
            self.lastDelta = 0;
            self.lastAlpha = 0;
        end
        
        % Set up for a new trial.
        function startTrial(self)
            % remember several values from the previous trial
            self.lastMean = self.currentMean;
            self.lastOutcome = self.currentOutcome;
            self.lastPrediction = self.currentPrediction;
            self.lastUpdate = self.currentUpdate;
            self.lastDelta = self.currentDelta;
            self.lastAlpha = self.currentAlpha;
            
            % move the subject's prediction to a consistent alpha?
            if self.isPredictionReset ...
                    && isfinite(self.lastPrediction) ...
                    && isfinite(self.lastOutcome)
                halfWay = floor( ...
                    (self.lastPrediction + self.lastOutcome) ./ 2);
                self.currentPrediction = halfWay;
            end
            
            % should this trial be a change trial?
            if self.remainingSafety > 0
                % no, its still a safety trial
                self.isChangeTrial = false;
                self.remainingSafety = self.remainingSafety - 1;
                self.steadyTrials = self.steadyTrials + 1;
                
            else
                % maybe, toss a coin to find out
                self.isChangeTrial = rand(1) < self.currentHazard;
                if self.isChangeTrial
                    self.pickChangeTrial();
                    self.steadyTrials = 1;
                    self.remainingSafety = self.safetyTrials - 1;
                else
                    self.steadyTrials = self.steadyTrials + 1;
                end
            end
            
            % generate a new outcome
            if isempty(self.fixedOutcomes)
                % pick a random outcome
                mu = self.currentMean;
                sigma = self.currentStd;
                outcome = round(normrnd(mu, sigma));
                while outcome < 0 || outcome > self.maxOutcome
                    outcome = round(normrnd(mu, sigma));
                end
                
            else
                % pick the next fixed outcome
                self.fixedOutcomeIndex = self.fixedOutcomeIndex + 1;
                outcome = self.fixedOutcomes(self.fixedOutcomeIndex);
            end
            self.currentOutcome = outcome;
            
            % default to bad trial, unless set to good
            self.isGoodTrial = false;
        end
        
        % Assign a subject prediction for the current trial.
        function setPrediction(self, prediction)
            
            if self.isPredictionLimited ...
                    && isfinite(self.lastPrediction) ...
                    && isfinite(self.lastOutcome)
                
                % limit to "alpha" between 0 and 1
                bounds = [self.lastPrediction, self.lastOutcome];
                
            else
                % limit to the full number line
                bounds = [0, self.maxOutcome];
            end
            
            lowerBound = min(bounds);
            upperBound = max(bounds);
            prediction = min(max(prediction, lowerBound), upperBound);
            self.currentPrediction = prediction;
            self.computeBehaviorParameters();
        end
        
        % Compute behavioral parameters for the current prediction.
        function computeBehaviorParameters(self)
            self.currentUpdate = ...
                self.currentPrediction - self.lastPrediction;
            self.currentDelta = ...
                self.currentOutcome - self.currentPrediction;
            self.currentAlpha = self.currentUpdate ./ self.lastDelta;
        end
        
        % Access the prediction which was reset or chosen by the subject.
        function prediction = getPrediction(self)
            prediction = self.currentPrediction;
        end
        
        function setGoodTrial(self, isGoodTrial)
            self.isGoodTrial = isGoodTrial;
        end
        
        % Finish up the current trial.
        function finishTrial(self)
            
            if self.isGoodTrial
                self.blockCompletedTrials = self.blockCompletedTrials + 1;
            end
            self.blockTotalTrials = self.blockTotalTrials + 1;
            
            % if prediction is not active, revert to last prediction
            if ~self.isPredictionActive
                self.currentPrediction = self.lastPrediction;
            end
            
            % compute final subject behavior parameters for this trial
            self.computeBehaviorParameters();
            self.cumulativeError = ...
                self.cumulativeError + abs(self.currentDelta);
            
            % compute behavior parameters for an "omniscient" observer
            omniscientDelta = self.currentOutcome - self.omniscientMean;
            self.omniscientCumulativeError = ...
                self.omniscientCumulativeError + abs(omniscientDelta);
            self.omniscientMean = self.omniscientMean ...
                + (omniscientDelta ./ self.steadyTrials);
            
            % compute behavior parameters for an "amnesiac" observer
            if isfinite(self.lastOutcome)
                amnesiacDelta = self.currentOutcome - self.lastOutcome;
            else
                halfWay = round(self.maxOutcome ./ 2);
                amnesiacDelta = self.currentOutcome - halfWay;
            end
            self.amnesiacCumulativeError = ...
                self.amnesiacCumulativeError + abs(amnesiacDelta);
        end
        
        % Update values for a change trial.
        function pickChangeTrial(self)
            self.currentMean = round(rand(1) .* self.maxOutcome);
            self.remainingSafety = self.safetyTrials;
            self.steadyTrials = 1;
        end
        
        % Compute subject payout, based on performance over all blocks.
        function payoutInfo = getPayout(self)
            
            % compute subject's mean error over all trials
            % this calculation from Matt looks incomplete to me
            %   subjectMeanError = self.cumulativeError ...
            %       ./ (self.blockCompletedTrials .* self.currentBlock);
            % this looks better to me
            totalTrials = self.blockCompletedTrials ...
                + (self.trialsPerBlock .* max(self.currentBlock-1, 0));
            subjectMeanError = self.cumulativeError ./ totalTrials;
            
            % compute average errors made by imaginary observers
            omniscientMeanError = ...
                self.omniscientCumulativeError ./ totalTrials;
            amnesiacMeanError = ...
                self.amnesiacCumulativeError ./ totalTrials;
            observersErrors = [omniscientMeanError, amnesiacMeanError];
            
            % mix the observer errors to define performance tiers
            mix = self.goldObserverWeights;
            goldLevel = sum(mix .* observersErrors) / sum(mix);
            mix = self.silverObserverWeights;
            silverLevel = sum(mix .* observersErrors) / sum(mix);
            mix = self.bronzeObserverWeights;
            bronzeLevel = sum(mix .* observersErrors) / sum(mix);
            
            % assemble strings which summarize performance, tiers
            errorString = sprintf('Your average error was %.1f !', ...
                subjectMeanError);
            goldString = sprintf('gold (%s) < %.1f', ...
                self.goldPayout, goldLevel);
            silverString = sprintf('silver (%s) < %.1f', ...
                self.silverPayout, silverLevel);
            bronzeString = sprintf('bronze (%s) < %.1f', ...
                self.bronzePayout, bronzeLevel);
            
            % report lots of performance info
            payoutInfo.blockTotalTrials = totalTrials;
            payoutInfo.subjectMeanError = subjectMeanError;
            payoutInfo.omniscientMeanError = omniscientMeanError;
            payoutInfo.amnesiacMeanError = amnesiacMeanError;
            payoutInfo.goldLevel = goldLevel;
            payoutInfo.silverLevel = silverLevel;
            payoutInfo.bronzeLevel = bronzeLevel;
            payoutInfo.errorString = errorString;
            payoutInfo.goldString = goldString;
            payoutInfo.silverString = silverString;
            payoutInfo.bronzeString = bronzeString;
        end
        
        % Summarize the current status of the session in a struct.
        function status = getStatus(self)
            props = properties(self);
            values = cell(size(props));
            for ii = 1:numel(props)
                values{ii} = self.(props{ii});
            end
            status = cell2struct(values, props);
        end
        
        % Get big struct arrays to status and payout per block and trial.
        function [bigStatus, bigPayout] = getDataArrays(self, extraTrials)
            if nargin < 2 || isempty(extraTrials)
                extraTrials = 0;
            end
            nTrials = self.trialsPerBlock + extraTrials;
            
            statusFields = fieldnames(self.getStatus());
            empties = cell(size(statusFields));
            template = cell2struct(empties, statusFields);
            bigStatus = repmat(template, nTrials, self.nBlocks);
            
            payoutFields = fieldnames(self.getPayout());
            empties = cell(size(payoutFields));
            template = cell2struct(empties, payoutFields);
            bigPayout = repmat(template, nTrials, self.nBlocks);
        end
    end
end