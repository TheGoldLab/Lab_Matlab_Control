%% RunMovingDotsEyelink
%
% This script is a wrapper than will execute the function that runs the
% moving dots task. Once the task has finished, this script will attempt to
% transfer the raw Eyelink data over and save the state data generated
% through the task script as well.
%
% 10/3/17   xd  wrote it

clear all; close all;
%% Perform PupilLabs calibration

% 
% Screen('Preference','SkipSyncTests',1);
% displayInfo = mglDescribeDisplays();
% sc = dotsTheScreen.theObject();
% sc.distance = 60;
% sc.width  = displayInfo(2).screenSizeMM(1)/10; % Need units to be cm
% sc.height = displayInfo(2).screenSizeMM(2)/10;
% sc.displayIndex = 2;
% sc.openWindow();



%% Run task
state = movingDotsTaskPupilLabs();
% save('MatlabState_XiaomaoSATBIAS','state');

%% Threshold
q = state{'Quest'}{'object'};
psiParamsIndex = qpListMaxArg(q.posterior);
psiParamsQuest = q.psiParamsDomain(psiParamsIndex,:);
t = psiParamsQuest(1);
fprintf('Final threshold estimate is %.2f\n',t);
