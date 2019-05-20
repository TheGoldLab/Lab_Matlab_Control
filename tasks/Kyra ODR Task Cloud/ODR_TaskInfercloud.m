function [tree, list] = ODR_TaskInfercloud(decisiontime_max)
% Kyra Schapiro 2/6/17


%3/30/18
%This task show targets drawn  from a generative distribution which has a
%chance of changing it's mean with a hazard rate.  This hazard rate can be
%set in ODRLogic under the variable H.  Currently, four targets are shown
%in sequence and fade out as new targets apear.  This number can be changed with the ODRLogic Variable "overlapTargets'
%and the rate of decay (how dim past targets get) with ODRLogic Variable
%"decayCoeffiecient".
    %4/5/18 overlap targerts set to 1 to make same as monkey task

%Currently, sampling is done semi-randomly according to methods developed
%by Kamesh designed to not let the sampling be predictable to but get
%approximately equal number of trials with 1-6 targets since most recent
%change point.  If one wanted all trials to be sampled (with the subject
%being able to respond to the current target or generative mean),
    %4/5/18 Sample set to every time via logic.blockType=1;

%Current default delay between final sample and choice is 2 seconds, but
%can be changed by entering 2 when prompted if you want a variable delay.
%The delay for a given trial will be randomly chosen from the ODRLogic
%variable "Delay Options".  

%The objective for the
%subject is to identify the current generative mean using the samples, as
%dictated by the fact that ODRLogic.sampleType is always set to 2.  There
%is some code in the comments to randomly choose if the subject should
%respond to the most recent target (sampleType=1) or the generative mean, but there is not currently and indicator to the subject of which type of repsonse (Predict=mean, percieve=target) is desired if the response contingency is changed
%These two options could probably pretty easily be separated by blocks or
%just change the feedback indicator from being on the generative mean to
%the target if one wanted to do a purly perceptual block, more similar to
%what monkeys are doing.

%Currently there isn't a particulalry good/tailered reward/payment paradigm
%to determine how much a subject should get for his/her responses.
%Currenlty, responses within 1 (generative dist) STD of the correct
%response (which again could be either the target or the generative mean)
%is worth 1 point, 1-2 STD is .5 points, and farther away is 0 points. 

%The Demo shows this by demonstrating the generative distribution, possible
%responses, and the correctness of these responses (red=bad, yellow=ok,
%green=good)

%SubjectData; %this will open the subject storage GUI


% subject ID info
[dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo('Cloud task');

topsDataLog.flushAllData();

% initializing
disp('--INITIALIZING--');
time = clock;
randSeed = time(6)*10e6;

if nargin==0
    decisiontime_max = Inf;
end

logic = ODRLogic(randSeed);
logic.name = 'TAFC Reaction Time Perceptual Task';
logic.dataFileName = dataFileName;
logic.time = time;
isClient = 0;
logic.nBlocks = 1;      
logic.blockType= 1; %1=sample every time; 2=random sample;
 logic.H=.15;



logic.isDemo=input('Demo?: 1=demo, 2=normaltask ');
logic.sampleType= input('Perception=1 or Prediction=2  '); 
logic.isMask=0; %input('Mask?: 1=no, 2=yes ')-1;
%disp(logic.isMask);
logic.varDelay=1;
logic.durationDelay=input('Delay Duration? ');
logic.useMouse=input('Using mouse or eye 1=mouse, 2=eye  ');
if logic.useMouse==2 && logic.isDemo==2
    logic.savePupil=input('Save Pupil?: 1=yes, 2=no ');
end

if logic.varDelay==2
        logic.trialsPerBlock=6000;

    else
        logic.trialsPerBlock= 200;  %do 200
       
end


if logic.isDemo==1
    logic.nBlocks = 2;  %1 for sub Samples on, 2 for training with samples off, 3 with fading trainer
    logic.trialsPerBlock=12; %150 seems to get through enough examples
    logic.H=.15;
    logic.durationTarget= .15;
end


% % SubjectData;  %**********************************Return to path when fully working!
logic.decisiontime_max = decisiontime_max;
if logic.useMouse==2;
if logic.savePupil==1    
    [subID, EDFfilename] = MKEyelinkCalibrate();
logic.EDFfilename=EDFfilename;
else
CPEyelinkCalibrateTest(); 
end
end
% Experiment paradigm
[tree, list] = configureODRtaskInfercloud(logic, isClient); %Used to be infer as of 5/9/18


%% Execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();

