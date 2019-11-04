
classdef MemLogic < handle
    % Kyra Schapiro,
    % For the within trials hazard rate ODR task 2/06/2017
    
    properties
        % a name to identify this session
        name = '';
        
        
 %Block Based Properties
               
%        %Are the targets spread throughout the period? 0=all at once,
%        %1=sprea
%        tempDelay=0;
%       

        %What is the target? 1=Memory, 2=Average, 3=percentage
        
        exptType=0;
        
        %Probability of mem/avg in type 3;
        proportionMem=.5;
        
               %1=yes, 2=no
        isDemo=2;

       %Using mouse or eye 1=mouse, 2=eye
            useMouse=1; 
        
       
        %Random number to determine if the generative mean should switch
        Randnumber=0;
        
         
        % a time to identify this session
        time = 0;
        
        % the number of blocks to run
        nBlocks = 1;
        
        % indicates the current block. 2 used for demo fade out
        currentBlock = 0;
        


        % number of trials within each block
        trialsPerBlock = 3;
        
        % running count of good trials in each block
        blockCompletedTrials = 0;
        
        % running count of good and bad trials in each block
        blockTotalTrials = 0;
       
        % seed for initializing random number generators
        randSeed = 1;     
            
            
 %Stimulus Properties       
        
        %radius of target
        targRadius=7;   %7,14, 25? in Constatinidis Franowicz Goldman-Rakic
                        %Target size is one degree for them...
        %time of delay between target presentation and response
        PossDelay=  [0,1,3,6];%  2;      %Constantidndis, Franowicz, Goldman-Rakic, 15
                  
 
        %which number of samples do you want to assay?
         PossDots=[1,2,3,5];
    
         
        %number of samples on a given trial
         ndots=0;
         
        %how many dots have been shown so far;
        currentdot=1;

         %Which set was actually used (numb between 1 &5
         theSet=ceil(rand*5) ;

         
        %Possible Samples Arrays:
        PossibleSamples=[
    
     -22    -2    7    13    -11        %20 between first two
    24   -25    -4  12    6             % 50 
    15   -18  29    3   -30             % 30
    17     0    -22    -10    7         %15
     0     9  -19   -12    28    ]     %10
        
        
        %Location around which the samples are scattered, NOT the mean
        Baselocation=NaN;
        
        %Actual Samples shown
        TrueSamples=[];
       
        
        %True Mean of whatever samples were shown in the trial
        TrueMean=NaN;
        
        %color array
        colArray={[0,1,0],[1,0,0],[0,0,1],[1,0,1],[1,1,0],[1,1,1]};
       
        

% Temporal Properties
        %Intertrial interval
        ITI= 0;%  .45 ;  %.15 for Kamesh Task shoot for ~2 ms
        
        %How long is from stim on to response
        totalDelay=NaN;
        
        % time target is on screen
        durationTarget =  .5; 
        
        %if the targets are spaced, then how long is delay between targets?
        durationDelay= NaN;
        

 %Response and Demo properties
        % direction of answer 
        guessAngle=NaN;
        
        %What what the goal?
        targOfInt=NaN;
       
        % Was the guess correct on the trial? 1= yes, .5= close
        correct = -1;
        

      %Demo Prop      
            %List of responses to demo, randomized
            
            demoResponseList=repmat([-2.25,-1.25,-.5,0, .5,1.25,2.25,],1,3);
          
            
            %Counter of which demopoint we are on
            demoPointIndex=1;
            
            %
            demoTarget=90;


            
       %Samples with broken fixation this CP
            brokenFixes=[];
            
       %If they broke fixation during the delay
            delayFixBreak=0;
        
        %name Kabir's file makes for the eye    
        EDFfilename=[];
        
        %Saved Pupil Data yes=1, no=2
        savePupil=2;
        
        eyelinkTimeStamp=0;
        
        matlabTimeStamp=0;
        
        eyelinkTSDelay=0;
        
        matlabTSDelay=0;
        
        %***
        
        decisiontime_max = Inf;
        
%         targetstrct = [];
        
        practiceN = 0;
        
        % name of a file that can be used for writing data
        dataFileName = 'Mem task'
        
        

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
        function self = MemLogic(randSeed)

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
            self.blockCompletedTrials = 0;
            self.blockTotalTrials = 0;

        end
        
        % Set up for a new trial.
        function startTrial(self)
            tic
            % initialize the variables
            timetmp = clock;
            self.randSeed = timetmp(6)*10e6;
            rng(self.randSeed);
            
            self.reactionTime = -1;
            self.t = -1;
%             self.choice = 0;

            % default to bad trial, unless set to good
            self.isGoodTrial = false;
            
            %reset how many dots have been shown
            self.currentdot=1;
            
           %Pick the base location, will randomize around circle
                self.Baselocation=floor(360*rand);      
           %Pick number of dots to use on this trial; and delay to use on
           %this trial
           if self.exptType<3
                self.ndots=self.PossDots(ceil(rand*length(self.PossDots)));
           else
               self.ndots=self.PossDots(1+ceil(rand*(length(self.PossDots)-1)));
           end
                self.totalDelay=self.PossDelay(ceil(rand*4));
           %Pick which set you are using this trial
                self.theSet=ceil(rand*5) ;  
           %Pick the actual sampels
                self.TrueSamples=sort(self.Baselocation+self.PossibleSamples(self.theSet,1:self.ndots));
           %TrueMean on this trial
                self.TrueMean=meanangle(self.TrueSamples);
          
           
           %Figure out the duration delay based on whether spaced or not
%            if self.tempDelay
%                 self.durationDelay=(self.totalDelay-self.ndots*self.durationTarget)/self.ndots;
%            else
                self.durationDelay=max(self.totalDelay-self.durationTarget,0);
%            end


        %Figure out the response goal;
        if self.exptType==1
           self.proportionMem=1;
        elseif self.exptType==2;
            self.proportionMem=0;
        else
            self.proportionMem=.5;  % 10/10/19, made it so that the P(avg)=p(any dot), so set size dependent 
        end
            
        if rand<self.proportionMem     %Mem trial
            self.targOfInt=ceil(rand*self.ndots);
        else %Avg trial
            self.targOfInt=6;
        end


        end
        
        % records the reaction time
        function setDetection(self)
                self.reactionTime = mglGetSecs(self.t);
        end
        
        function setTimeStamp(self)
                self.t = mglGetSecs;
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