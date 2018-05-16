%% RTDrun
%
% RTD = Response-Time Dots
%
% This script is a wrapper than will execute the function that runs the
% moving dots task. Once the task has finished, this script will attempt to
% transfer the data files to a single place
%
% 10/3/17   xd  wrote it

%% ---- Need to clear everything because globals can exist
clear all

%% ---- Arguments to RTDconfigure
arguments = { ...
   'taskSpecs',            {'Quest' 40 'SN' 20 'AN' 20}, ...
   'sendTTLs',             false, ...
   'displayIndex',         1, ... % 0=small, 1=main
   'useRemote',            true, ...
   };

%% ---- Configure experiment
[datatub, maintask] = RTDconfigure(arguments{:});

%% ---- RUN IT
% Moved open/close screen here because we also want to check whether or not
% to calibrate the eye tracker, which requires the screen

% Get the screen ensemble
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};

% Use error-catching
%try    
    
    % Open the screen
    screenEnsemble.callObjectMethod(@open);
    
    % Wait for the remote screen to start up
%    if datatub{'Input'}{'useRemote'}
%        pause(10);
%    end
    
    % Check to calibrate pupil-lab device   
    ui = datatub{'Control'}{'ui'};
    if isa(ui, 'dotsReadableEyePupilLabs')
        ui.calibrate();
    end

    % Run the task
    maintask.run();
    
    % Close the screen
    screenEnsemble.callObjectMethod(@close);
    
%maintask.finishFevalable = {@callObjectMethod, datatub{'Graphics'}{'screenEnsemble'}, @close};
% 
% catch
%     
%     % Close the screen
%     screenEnsemble.callObjectMethod(@close);
% end

%% ---- Save the data
topsDataLog.writeDataFile();

