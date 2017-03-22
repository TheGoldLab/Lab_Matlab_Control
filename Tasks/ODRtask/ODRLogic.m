
classdef ODRLogic < handle
    % Kyra Schapiro,
    % For the within trials hazard rate ODR task 2/06/2017
    
    properties
        % a name to identify this session
        name = '';
        
        % time target is on screen
        durationTarget = 0.15;
        
        %time of delay between target presentation and response
        durationDelay=3;      %Constantidndis, Franowicz, Goldman-Rakic, 15
        
        %Center of distribution
        distMean=0;
        
        %Std of distribution
        distSTD=sqrt(10);
        
        %How many trials since change point
        sinceChangePT=0;
        
        %Random number to determine if switch
        Randnumber=0;
        
        % hazard rate within trial
        H = 0.05; % time-step in 1/60 sec, since frames change in 60 Hz
             
        % a time to identify this session
        time = 0;
        
        % the number of blocks to run
        nBlocks = 1;
        
        % indicates the current block
        currentBlock = 0;

        % number of trials within each block
        trialsPerBlock = 3;
        
        
        % running count of good trials in each block
        blockCompletedTrials = 0;
        
        % running count of good and bad trials in each block
        blockTotalTrials = 0;
       
            
        % seed for initializing random number generators
        randSeed = 1;
        
        %radius of target
        targRadius=7;   %7,14, 25? in Constatinidis Franowicz Goldman-Rakic
                        %Target size is one degree for them...
        
        % direction of target by angle degrees 
        targetAngle = 0;
        
        % direction of answer 
        guessAngle=90;
      
        correct = -1;
        

        
 
        
        
        %***
        
        decisiontime_max = Inf;
        
        targetstrct = [];
        
        practiceN = 0;
        
        % name of a file that can be used for writing data
        dataFileName = 'ODR task'
        
        keyhistory = [];

        

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



        
    end
    
    methods
        
        % Constructor takes no arguments.
        function self = ODRLogic(randSeed)
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
            
            self.distMean=360*rand;      %pick the first distribution mean
            
            
            %For the real implemntation, but not useful for testing
%             if self.currentBlock==1
%                 self.trialsPerBlock=72;
%             else
%                 self.trialsPerBlock=3;  %Need to figure out trials per block for prior sturcture portion.
%             end
           
            
            
            if self.currentBlock==2
                self.H=.05;          %should be .05
            else
                self.H=1;
            end
            
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
%             self.choice = 0;
            self.keyhistory = [];
            % default to bad trial, unless set to good
            self.isGoodTrial = false;
            
            
            %pick a new mean
            self.Randnumber=rand;
            if self.Randnumber<self.H
                self.distMean=360*rand;      %pick the first distribution mean
                self.sinceChangePT=0;
            else
                self.sinceChangePT=self.sinceChangePT+1;
            end
            
      
            
            
%        May wish to put something about practice trials being easier here, like change the durTarget or color even     
%             %If we haven't done enough practice trials, this trial has the
%             %highest possible coherence.  Otherwise pick a random coherense
%             %from the set
%             if self.blockCompletedTrials <= self.practiceN
%                 self.coherence = max(self.coherenceset);
%             else
%                 randind = randperm(length(self.coherenceset));
%                 self.coherence = self.coherenceset(randind(1));
%             end
                   
        end
        
        % records the reaction time
        function setDetection(self)
                self.reactionTime = mglGetSecs(self.t);
        end
        
        function setTimeStamp(self)
                self.t = mglGetSecs;
        end
                

        
        % Compute behavioral parameters for the current prediction. NOT
        % CURRENTLY IN USE
%         function computeBehaviorParameters(self)
%             if self.choice ~= 0
%                 self.ReactionTimeData = [self.ReactionTimeData self.reactionTime];
%                 self.PercentCorrData = [self.PercentCorrData self.correct];
%                 %self.score = (mean(self.PercentCorrData))./(mean(self.ReactionTimeData));
                
                %Insert code here to calculate timespent in prefinal state
                    %Get lenght of directonvc, time in prefinal stat=i=0; while
                    %directionvc(final-i)=directionvc(final-i-1), add 1 to
                    %i
                    
                
%             end
%         end
        
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