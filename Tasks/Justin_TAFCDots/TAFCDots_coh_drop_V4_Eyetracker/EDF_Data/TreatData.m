function [DATA] = TreatData()
%This function will collect all the matlab-format (.m) EDF files and use
%them to make a structure with 6 fields and nSubject rows. Each row represents
%a subject.  Raw contains the raw pupil size data, time contains the 
% Eyelinktimestamp of the raw pupil data.  Blinks contains a list with the
% blink onset times (first row) and offset times (second row) for a
% person's session.  Clean pupil is the interpolated pupil data after
% filtering out the blinks.  zCPupil is the zscored pupil for a subject
% over the sesson.
%%
clear all; close all;

% VARIABLES (to modify if needed)


%This variable is how far on either side of the blink you want to consider
%the start time.  Eyelink has a timestamp for when it considers a blink to
%have started but it does have a bit of a delay.  This number is used to
%pad the Eyelink blink time to encompase data affected by the blink
temporalMargin = 150;% for Hannah 70;

%This variable is how far back in time do you want to use from either side
%of the blink to interpret what the pupil size would have been if the blink
%had not occured. 
interpolationMargin = 50;

% This has something to do with medfilt1, a prefilter on the data used by
% CleanBlinks, but I'm not quite sure what it does
filterOrder = 200;

%##########################################################################
%LOAD FILES
%--------------------------------------------------------------------------
%Put the path 
pathEDF = fullfile(pwd); % My EDF files are in a folder called 'EyeData' 
pathFilesEDF = dir(fullfile(pathEDF,'*.mat'));
nbSubjects = size(pathFilesEDF,1);


% all the data are stored here:
DATA = struct([]); 


for i = 1 : nbSubjects
    
    % 1- Load edf file:
    fileEDF = fullfile(pathEDF,pathFilesEDF(i).name)
    varEDF  = load(fileEDF);
    nameEDF = fieldnames(varEDF);
    DATA(i).raw = varEDF.(nameEDF{1,1}).FSAMPLE.pa(1,:);
    DATA(i).time = varEDF.(nameEDF{1,1}).FSAMPLE.time;  
    %%Find blink off events (type 4, type 3 is blink on, but type 4 has onset
%%and offset times
BlinkEvents=varEDF.(nameEDF{1,1}).FEVENT(1,find([varEDF.(nameEDF{1,1}).FEVENT(1,:).type]==4));
BlinksOnTimes=[BlinkEvents.sttime];
BlinksOffTimes=[BlinkEvents.entime];
[C,B, BlinkOnIndex]=intersect(BlinksOnTimes,DATA(i).time);
[C,B, BlinkOffIndex]=intersect(BlinksOffTimes,DATA(i).time);

% Gather the Blink on times (row 1) and offset times (row 2)
OnsAndOffs=[BlinkOnIndex';BlinkOffIndex'];

j=length(OnsAndOffs);

%If two blinks are close together, those blinks are combined into a single
%onset and offset time
while j>1
    if OnsAndOffs(1,j)-OnsAndOffs(2,j-1)<300
        OnsAndOffs(2,j-1)=OnsAndOffs(2,j);
        OnsAndOffs(:,j)=[];
        
    end
    j=j-1;
 
end
    
DATA(i).blinks=OnsAndOffs;    

end

% some more variables
frequency    = varEDF.(nameEDF{1,1}).RECORDINGS.sample_rate;



%%
%##########################################################################
% FUNCTIONS
%--------------------------------------------------------------------------

for i = 1 : nbSubjects
 disp(i);
    %--------RUN FUNCTIONS-------------------------------------------------
    %----------------------------------------------------------------------
    

    sub=i;
    % 1 -  Get rid of the blinks and filter the data
    DATA(i).cleanPupil = CleanBlinks(DATA(i).raw, frequency, temporalMargin,...
        interpolationMargin,filterOrder,sub,DATA(i).blinks); 
    DATA(i).zCPupil=zscore(DATA(i).cleanPupil);

end

% 
% 
%% 
end
