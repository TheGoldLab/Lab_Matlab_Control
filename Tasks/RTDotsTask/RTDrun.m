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
   'displayIndex',         0, ...
   'remoteInfo',           {false}, ...
   };

%% ---- Configure experiment
[datatub, maintask] = RTDconfigure(arguments{:});

%% ---- RUN IT
maintask.run();

%% ---- Save the data
topsDataLog.writeDataFile();

