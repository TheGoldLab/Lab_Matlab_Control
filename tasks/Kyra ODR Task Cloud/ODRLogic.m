
classdef ODRLogic < handle
    % Kyra Schapiro,
    % For the within trials hazard rate ODR task 2/06/2017
    
    properties
        % a name to identify this session
        name = '';
        
        %Sampling Variables
                %Whether a trial is Sample Trial, in which case there will
                %be a delay at the end, after which the subject must make a
                %guess
                isSampled=false;
                
                
                %Whether this sample is prediction or Perception
                sampleType=0; %1=Perception, 2=Prediction

                %has a sample happened under the current generative mean?
                samplesThisRun=0;

                %How many trials since last sample?
                sampleRunLength=0;
                
                %Index of what is next TAC to be sampled
                sampleIndex=1;
                
                %P next trial with appropriate TAC will be pick based on
                %frequency
                pSample=[0.55 0.66 0.72 0.78 0.95 1.0]; % My numbers commented[0.39,0.48,0.57,0.69,0.82,1]
                                                        % Kamesh numbers [0.55 0.64 0.67 0.78 0.95 1.0]
                                                        
                %List of randomly generated next sample TAC to ensure equal
                %number of each TAC picked
                trialList=[];
                
                %What is the next TAC sample?
                nextSampleTAC=0;
                
        % IS there a masking stimulus?
        isMask=1;
        
        %How many targets in mask?
        MaskTargets=15;
        
        %How long is the mask on for;
        durationMask=.1;

        %Intertrial interval
        ITI= 0;%  .45 ;  %.15 for Kamesh Task shoot for ~2 ms
        
        
        
        % time target is on screen
        durationTarget =  .1; %for real .05 for me,  .05 for Kamesh Task %.1 for Hannah
        
        %time of delay between target presentation and response
        durationDelay=  2;%  2;      %Constantidndis, Franowicz, Goldman-Rakic, 15
        
        %What the variable delay options are
        delayOptions=[2,5,8];
        
        %Whether the delay time varries (2) or not (1)
        varDelay=0
        
        %Center of generative distribution
        nextdistMean=nan;
        
        targGenDistMean=nan;
        
        %Center of target distribution by angle degrees 
        targetAngle = 0;
        
        %
        NextAngle =0;
        
        %Square run or triangle run
        CPflag=3;
       
        %List of Targets since the last CP
        targPerCP=[];
        
        %List of Targs since last Sample, not including ones in current run
        targPerSample=[];
        
        % direction of answer 
        guessAngle=90;
        
        %Std of generative distribution
        distSTD=15;
        
        %Std of the blue dots distribution
        miniSTD=25;
        
        %How many trials since change point
        sinceChangePT=0;
        
        %How many trials in this sequence?
        seqLen=5;
        
        
        %How many targets are on screen at a time
        overlapTargets=1;
        
        %Decay coefficient
        decayCoeff=.55;
        
        %If=1, shows the previous targets in a CP during feedback
        extraFeedback=0;
        
        
        %Random number to determine if the generative mean should switch
        Randnumber=0;
        
        % hazard rate to determine if the generative mean should switch
        H = 0.1667; %
             
        % a time to identify this session
        time = 0;
        
        % the number of blocks to run
        nBlocks = 1;
        
        % indicates the current block
        currentBlock = 0;
        
        %Block Type, 1=Random, 2=Dynamic
        blockType=0;

        % number of trials within each block
        trialsPerBlock = 3;
        
        
        % running count of good trials in each block
        blockCompletedTrials = 0;
        
        % running count of good and bad trials in each block
        blockTotalTrials = 0;
       
            
        % seed for initializing random number generators
        randSeed = 1;
        
        %radius of target
        targRadius=8; %Should be ~8 for 2016 but is 6 for 2013
                        

       
        % Was the guess correct on the trial? 1= yes, .5= close
        correct = -1;
        
        %1=yes, 2=no
        isDemo=2;
            
            %List of responses to demo, randomized
            
            demoResponseList=repmat([-2.25,-1.25,-.5,0, .5,1.25,2.25,],1,3);
          
            
            %Counter of which demopoint we are on
            demoPointIndex=1;
            
            %
            demoTarget=90;

       
        %Density values 
                %number of dots that *could* be blue
                    nDots=75; %30 for cloud task
                
                %Average proportion of dots that will be blue, calculated
                %in configureODRtask in line 439
                    density=.25;
                    
                % Number of dots chosen to be blue on a given trial
                    nCoherentDots=0;
                    
            %angles of random dots;
                
                    cloudAngles=[];
                %Radii of random dots    
                    randtargRadius=[];
        

        
 
       %Using mouse or eye 1=mouse, 2=eye
            useMouse=1; 
            
       %Samples with broken fixation this CP
            brokenFixes=[];
            
       %If they broke fixation during the delay
            delayFixBreak=0;
        
        %name Kabir's file makes for the eye    
        EDFfilename=[];
        
        %Saved Pupil Data yes=1, no=2
        savePupil=2;
        
        eyelinkTimeStampFix=0;
        
        matlabTimeStampFix=0;
        
        eyelinkTSDelay=0;
        
        matlabTSDelay=0;
        
        %***
        
        decisiontime_max = Inf;
        
%         targetstrct = [];
        
        practiceN = 0;
        
        % name of a file that can be used for writing data
        dataFileName = 'ODR task'
        
        
       
  
      
        

        

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
            %Pick list of Trials After Changepoint to sample
            if self.varDelay==2
                trialmult=3;
            elseif self.varDelay==1
                trialmult=1;
            end
            
               
            totalSamplePicks=repmat([1:6],1,24*trialmult); % want 10 of each TAC type  *** Need to do 1:6 if you want to do perception
            self.trialList=datasample(totalSamplePicks,size(totalSamplePicks,2),'Replace',false); %shuffle
            self.trialList=[4, self.trialList];  %want the first sample to be 4 in so that have time to gather h rate info
            % increment the block and choose block parameters
            self.currentBlock = self.currentBlock + 1;
            
            self.nextdistMean=360*rand;      %pick the first generative mean
                            self.targGenDistMean=self.nextdistMean;

            self.NextAngle=self.distSTD*randn+self.nextdistMean; % pick first target
            
           %Set the hazard rate.  Switch every trial in block 1, approx every tenth trial in block 2 

            
            % reset trial-by-trial state
            self.blockCompletedTrials = 0;
            self.blockTotalTrials = 0;

        end
        
        % Set up for a new trial.
        function startTrial(self)
            % initialize the variables
            if self.targGenDistMean~=self.nextdistMean
                self.sinceChangePT=1;
                self.CPflag=3+mod(self.CPflag,2);           
            else
                self.sinceChangePT=self.sinceChangePT+1;
                
            end

                            self.targGenDistMean=self.nextdistMean;

            timetmp = clock;
            self.randSeed = timetmp(6)*10e6;
            rng(self.randSeed);
            
            self.reactionTime = -1;
            self.t = -1;
%             self.choice = 0;

            % default to bad trial, unless set to good
            self.isGoodTrial = false;
            
            
            if self.varDelay==2
                index=ceil(length(self.delayOptions)*rand);
              
                self.durationDelay=self.delayOptions(index);
            end
            
            
            %pick a new generative mean if appropriate
          
            
      
            
            %Added 12/6/18 to make distribution cut off at 8 while still
            %exponential
            
            if  self.sinceChangePT>=self.seqLen
                self.nextdistMean=360*rand;      %pick the generative mean
                self.samplesThisRun=0;
                self.targPerCP=[];          %Reset the list of samples in this CP condition
                self.brokenFixes=[];
                %Pick new seq length
                   self.seqLen=ceil(exprnd(1/self.H));
                    while self.seqLen>8
                        self.seqLen=ceil(exprnd(1/self.H)); 
                    end
            end
            
            
            
%             
%                   self.Randnumber=rand;
            
%             if self.Randnumber<self.H
%                 self.nextdistMean=360*rand;      %pick the generative mean
%                 self.samplesThisRun=0;
% %                 self.targPerSample=[self.targPerSample,self.targPerCP]; %append list of targs from previous CP to total since last sample
%                 self.targPerCP=[];          %Reset the list of samples in this CP condition
%                 self.brokenFixes=[];
%                 
%             % Added 5/31/18, make it more likely to change if had 10 TACP    
%             elseif self.sinceChangePT>=10 && rand<.075*self.sinceChangePT
%                 
%                 self.nextdistMean=360*rand;      %pick the generative mean
%                 self.samplesThisRun=0;
% %                 self.targPerSample=[self.targPerSample,self.targPerCP]; %append list of targs from previous CP to total since last sample
%                 self.targPerCP=[];          %Reset the list of samples in this CP condition
%                 self.brokenFixes=[];
% 
%             end
            
            %Pick target radius
%             self.targRadius=8; %max(2*randn+8, 5);
            
            
            self.nextSampleTAC=self.trialList(self.sampleIndex);
            %Decide whether to sample
            if self.blockType==1 %Sample half in random blocks
                self.isSampled=true;
%             else
%                 %If no samples this run, correct number after CP and enough
%                 %trials since last sampel
%                 if(self.samplesThisRun==0 && self.nextSampleTAC==self.sinceChangePT...
%                         && self.sampleRunLength>6)  %min of 10 trials between samples
%                     %Check to see if this trial will be sample based on how
%                     %frequently it occurs
%                     self.isSampled=rand(1)<self.pSample(self.nextSampleTAC);
%                     if (self.isSampled)
%                         self.samplesThisRun=1;
%                         self.sampleRunLength=1;
%                         self.sampleIndex=self.sampleIndex+1;
%                         
%                     end
%                 else
%                     self.isSampled=false;
%                     self.sampleRunLength=self.sampleRunLength+1;
%                     if self.sampleRunLength==2
%                         self.targPerSample=[];
%                         self.targPerCP=[];
%                         self.delayFixBreak=0;
%                     end
%                 end
            end
            
            %Pick if the sample is  or Perceptual (sampleType1) Predictive
            %(sampleType2
%             if self.isSampled && self.blockType==2 %&& self.nextSampleTAC>1
% %                 if rand<.05
% %                     self.sampleType=1;
% % 
% %                 else
%                      self.sampleType=2;
% %                 end
%             else
%                 self.sampleType=1;
%                 
%              end
            
            
         
            

                   
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