
classdef TAFCDotsLogic < handle
    % TDK, 6/29/2012
    % For the within trials hazard rate TAFC task 9/11/2013
    
    properties
        % a name to identify this session
        name = '';
        
        % total stimulus duration within a trial (for interrogation
        % paradigm only)
        duration = 0.5;
        
        % hazard rate within trial
        H = 0.03; % time-step in 1/60 sec, since frames change in 60 Hz
             
        % a time to identify this session
        time = 0;
        
        % the number of blocks to run
        nBlocks = 1;
        
        % indicates the current block
        currentBlock = 0;

        % number of trials within each block
        trialsPerBlock = 1;
        
        % running count of good trials in each block
        blockCompletedTrials = 0;
        
        % running count of good and bad trials in each block
        blockTotalTrials = 0;
        
        % catch trial probability
        catchTrialProbability = 0;
            
        % seed for initializing random number generators
        randSeed = 1;
        
        % initial direction
        direction0 = 0;
        
        % set of coherences to pick from
        coherenceset = [0 0 0];

        choice = 0;
        % temporary variables for storing data
        ReactionTimeData = [];
        PercentCorrData = [];
        CatchNoCatch = [];
        
        score = 0;
        
        correct = -1;
        
        directionvc = [];
        
        coherencevc = [];
        
        tind = 0;
        
        minT;
        
        maxT;
        
        decisiontime_max = Inf;
        
        stimstrct = [];
        
        practiceN = 0;
        
        % name of a file that can be used for writing data
        dataFileName = 'TAFCDotsData'
        
        keyhistory = [];
        
        stimtime = [];
        stimOnset = nan;
        coherence = 100;

    end
    
    properties (SetAccess = protected)
        % time after the change of direction
        tAfter;

        % reaction time: the tic starts when the dots change direction
        % this measures the reaction time for hits
        reactionTime;
        
        % the tic of reaction time
        t;
        
        % whether the current trial is good and complete
        isGoodTrial;
        
        % whether the current trial is a catch trial
        isCatchTrial;
        
        % trial tracker for interleave
        tracker;
        
        
        

        
    end
    
    methods
        
        % Constructor takes no arguments.
        function self = TAFCDotsLogic(randSeed)
            if nargin
                self.randSeed = randSeed;
            end
            self.startSession();
        end
        
        % Initialize random number functions from randSeed.
        function initializeRandomGenerators(self)
            %             rand('seed', self.randSeed);
            %             randn('seed', self.randSeed);
            
            rng(self.randSeed);
        end
        
        % Set up for the first trial of the first block.
        function startSession(self)
            self.initializeRandomGenerators();
            
            % reset session totals
            self.currentBlock = 0;
            self.blockCompletedTrials = 0;
            self.blockTotalTrials = 0;
        end
        
        % Set up for a new block.
        function startBlock(self)
            % increment the block and choose block parameters
            self.currentBlock = self.currentBlock + 1;
            
            % reset trial-by-trial state
            self.blockCompletedTrials = 0;
            self.blockTotalTrials = 0;

        end
        
        % Set up for a new trial.
        function startTrial(self)
            
            % initialize the variables
            timetmp = clock;
            self.randSeed = timetmp(6)*10e6;
            rng(self.randSeed);
            
            self.reactionTime = -1;
            self.t = -1;
            self.choice = 0;
            self.keyhistory = [];
            % default to bad trial, unless set to good
            self.isGoodTrial = false;
            
            %Choosing Coherence from a set
            %practice N influences coherence. Don't need for our trials
            %if self.blockCompletedTrials <= self.practiceN
            %    self.coherence = max(self.coherenceset);
            %else
            %    randind = randperm(length(self.coherenceset));
            %    self.coherence = self.coherenceset(randind(1));
            %end

            %self.duration = min(self.minT + exprnd(1),self.maxT);

            self.setTimeAfter(0);
            
%             
        end
        
        % records the reaction time
        function setDetection(self)
                self.reactionTime = mglGetSecs(self.t);
        end
        
        function setTimeStamp(self)
                self.t = mglGetSecs;
        end
                

        % the inputTime should be in milliseconds
        function setTimeAfter(self, inputTime) % We are not using tAfter for now.
            self.tAfter = inputTime / 1000; % converting to seconds
        end
        
        % Compute behavioral parameters for the current prediction.
        function computeBehaviorParameters(self)
            if self.choice ~= 0
                self.ReactionTimeData = [self.ReactionTimeData self.reactionTime];
                self.PercentCorrData = [self.PercentCorrData self.correct];
                %self.score = (mean(self.PercentCorrData))./(mean(self.ReactionTimeData));
            end
        end
        
        function setGoodTrial(self)
            self.isGoodTrial = true;
        end
        
        % Finish up the current trial.
        function finishTrial(self)
            if self.isGoodTrial
                self.blockCompletedTrials = self.blockCompletedTrials + 1;
            end
            self.blockTotalTrials = self.blockTotalTrials + 1;
        end
        
        function finishBlock(self)
            % computing
        end

        % getting a data array
        function status = getDataArray(self, extraTrials)
            if nargin < 2 || isempty(extraTrials)
                extraTrials = 0;
            end
            nTrials = self.trialsPerBlock + extraTrials;
            
            statusFields = fieldnames(self.getStatus());
            empties = cell(size(statusFields));
            template = cell2struct(empties, statusFields);
            status = repmat(template, nTrials, self.nBlocks);
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
    end
end