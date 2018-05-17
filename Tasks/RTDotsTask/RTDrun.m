function RTDrun(location)
%% function RTDrun(location)
%
% RTD = Response-Time Dots
%
% This function configures, initializes, runs, and cleans up an RTD
% experiment.
%
% 11/17/18   jig wrote it

%% ---- Clear globals
clear globals

%% ---- Set argument list based on location
%   locations are 'office' (default), 'OR', or 'debug'
if nargin < 1 || isempty(location)
    location = 'office';
end

switch location
    
    case {'OR'}        
        arguments = { ...
            'taskSpecs',            {'Quest' 60 'SN' 40 'AN' 40}, ...
            'sendTTLs',             true, ...
            'useEyeTracking',       true, ...
            'displayIndex',         1, ... % 0=small, 1=main
            'useRemote',            true, ...
            };

    case {'debug'}    
        arguments = { ...
            'taskSpecs',            {'Quest' 50 'SN' 50 'AN' 50}, ...
            'sendTTLs',             false, ...
            'useEyeTracking',       false, ...
            'displayIndex',         0, ... % 0=small, 1=main
            'useRemote',            false, ...
            };
        
    otherwise        
        arguments = { ...
            'taskSpecs',            {'Quest' 60 'SN' 60 'AN' 60}, ...
            'sendTTLs',             false, ...
            'useEyeTracking',       true, ...
            'displayIndex',         1, ... % 0=small, 1=main
            'useRemote',            true, ...
            };
end

%% ---- Configure experiment
[datatub, maintask] = RTDconfigure(arguments{:});

%% ---- Initialize

% Get the screen ensemble
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};

% Open the screen
screenEnsemble.callObjectMethod(@open);

% Possibly calibrate the eye tracker
RTDcalibratePupilLabs(datatub);

%% ---- Run the task
maintask.run();

%% ---- Clean up
% Close the screen
screenEnsemble.callObjectMethod(@close);

% Close the uis
close(datatub{'Control'}{'ui'});
close(datatub{'Control'}{'keyboard'});

%save the data
topsDataLog.writeDataFile();
