%% TimeDelayBetweenEyelinkAndMatlab
%
% This script investigates the differences in timing between the computer
% on which Matlab runs and the computer hosting Eyelink. Because the
% experiment requires the coordination of the two machines, it is critical
% to understand what the differences in timing will be. Here, several basic
% functions involving timing will be investigated. 
%
% The Matlab timing operations used will be mglGetSecs and the tic-toc
% functions. The Eyelink time will be determined by getting a data sample
% from Eyelink. The WaitSecs and pause functions will be used to test basic
% delays while drawing functions and real time data transfer from the
% Eyelink to Matlab will also be investigated.
%
% 9/21/17    xd  wrote it

clear; close all;
CPEyelinkCalibrateTest();

 %% Parameters
%
% These parameters determine simple factors to be tested including the
% number of times to repeat an experiment as well as the range of times to
% test. All time values will be set in seconds.

testDurations = logspace(-3,1,10);
testRepeatNumber = 10;
tests = {'WaitSecs' 'pause' 'Eyelink Read' 'Eyelink Write' 'Snowdots'};
timers = {'mglGetSecs' 'tictoc' 'Eyelink'};
 
%% Preallocate space for data
%
% We will need to record the data for each of the for test cases, for the
% three different timing mechanisms, and for the number of repeats and
% testDurations.

data = zeros(5,3,length(testDurations),testRepeatNumber);

%% Test WaitSecs
for ii = 1:length(testDurations)
    fprintf('Test 1, Duration %d done!\n',ii);
    for jj = 1:testRepeatNumber
        
        % Test mglGetSecs
        t0 = mglGetSecs;
        WaitSecs(testDurations(ii));
        t1 = mglGetSecs;
        data(1,1,ii,jj) = t1 - t0;
        
        % Test tic toc
        tic;
        WaitSecs(testDurations(ii));
        t1 = toc;
        data(1,2,ii,jj) = t1;
        
        % Test Eyelink. Units are MS so we divide by 1000.
        e0 = Eyelink('NewestFloatSample');
        WaitSecs(testDurations(ii));
        e1 = Eyelink('NewestFloatSample');
        data(1,3,ii,jj) = (e1.time - e0.time)/1000;
        
    end
end
save('TimeDelayData','data','testDurations','testRepeatNumber','tests','timers');

%% Test pause
for ii = 1:length(testDurations)
    fprintf('Test 2, Duration %d done!\n',ii);
    for jj = 1:testRepeatNumber
        
        % Test mglGetSecs
        t0 = mglGetSecs;
        pause(testDurations(ii));
        t1 = mglGetSecs;
        data(2,1,ii,jj) = t1 - t0;
        
        % Test tic toc
        tic;
        pause(testDurations(ii));
        t1 = toc;
        data(2,2,ii,jj) = t1;
        
        % Test Eyelink
        e0 = Eyelink('NewestFloatSample');
        pause(testDurations(ii));
        e1 = Eyelink('NewestFloatSample');
        data(2,3,ii,jj) = (e1.time - e0.time)/1000;
        
    end
end
save('TimeDelayData','data','testDurations','testRepeatNumber','tests','timers');

%% Test Eyelink transfer
for ii = 1:length(testDurations)
    fprintf('Test 3, Duration %d done!\n',ii);
    for jj = 1:testRepeatNumber
        
        % Test mglGetSecs
        t0 = mglGetSecs;
        Eyelink('NewestFloatSample');
        t1 = mglGetSecs;
        data(3,1,ii,jj) = t1 - t0;
        
        % Test tic toc
        tic;
        Eyelink('NewestFloatSample');
        t1 = toc;
        data(3,2,ii,jj) = t1;
        
        % Test Eyelink
        e0 = Eyelink('NewestFloatSample');
        Eyelink('NewestFloatSample');
        e1 = Eyelink('NewestFloatSample');
        data(3,3,ii,jj) = (e1.time - e0.time)/1000;
        
    end
end
save('TimeDelayData','data','testDurations','testRepeatNumber','tests','timers');

%% Test sending message to Eyelink
for ii = 1:length(testDurations)
    fprintf('Test 4, Duration %d done!\n',ii);
    for jj = 1:testRepeatNumber
        
        % Test mglGetSecs
        t0 = mglGetSecs;
        Eyelink('Message','test');
        t1 = mglGetSecs;
        data(4,1,ii,jj) = t1 - t0;
        
        % Test tic toc
        tic;
        Eyelink('Message','test');
        t1 = toc;
        data(4,2,ii,jj) = t1;
        
        % Test Eyelink
        e0 = Eyelink('NewestFloatSample');
        Eyelink('Message','test');
        e1 = Eyelink('NewestFloatSample');
        data(4,3,ii,jj) = (e1.time - e0.time)/1000;
        
    end
end
save('TimeDelayData','data','testDurations','testRepeatNumber','tests','timers');

%% Test snowdots drawing

% Create asnowdots drawable object and put it into an ensemble to give us
% more control over the timing.
targets = dotsDrawableTargets();
targets.xCenter = 0;
targets.yCenter = 0;
targets.nSides  = 100;
targets.height  = 1;
targets.width   = 1;

targetE = topsEnsemble();
targetE.addObject(targets);
targetE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

% Open a snowdots window
sc = dotsTheScreen.theObject();
sc.displayIndex = 0;
sc.initialize();
sc.openWindow();

% Loop the actual test
for ii = 1:length(testDurations)
    fprintf('Test 5, Duration %d done!\n',ii);
    for jj = 1:testRepeatNumber
        
        % Test mglGetSecs
        t0 = mglGetSecs;
        targetE.callObjectMethod(@prepareToDrawInWindow);
        targetE.run(testDurations(ii));
        t1 = mglGetSecs;
        data(5,1,ii,jj) = t1 - t0;
        
        % Test tic toc
        tic;
        targetE.callObjectMethod(@prepareToDrawInWindow);
        targetE.run(testDurations(ii));
        t1 = toc;
        data(5,2,ii,jj) = t1;
        
        % Test Eyelink
        e0 = Eyelink('NewestFloatSample');
        targetE.callObjectMethod(@prepareToDrawInWindow);
        targetE.run(testDurations(ii));
        e1 = Eyelink('NewestFloatSample');
        data(5,3,ii,jj) = (e1.time - e0.time)/1000;
        
    end
end
save('TimeDelayData','data','testDurations','testRepeatNumber','tests','timers');

%% Save data
mglClose;
Eyelink('StopRecording');