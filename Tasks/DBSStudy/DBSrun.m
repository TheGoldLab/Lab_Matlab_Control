function DBSrun(location)
%% function DBSrun(location)
%
% DBSrun = Response-Time Dots
%
% This function configures, initializes, runs, and cleans up a DBS 
%  experiment (OR or office)
%
% 11/17/18   jig wrote it

%% ---- Clear globals
%
% umm, duh
clear globals
clear classes

%% ---- Create a topsGroupedList
%
% This is a versatile data structure that will allow us to pass all
%  relevant variables to the state machine as it advances
%
% We also start by making topsCallLists for the main task start and
%  finish fevalables. These can be filled in by various configuration
%  subroutines so we don't need to know where what has and has not been
%  added/configured
datatub = topsGroupedList();

startCallList = topsCallList();
startCallList.alwaysRunning = false;
datatub{'Control'}{'startCallList'} = startCallList();

finishCallList = topsCallList();
finishCallList.alwaysRunning = false;
finishCallList.invertOrder = true;
datatub{'Control'}{'finishCallList'} = finishCallList();

%% ---- Set up the main tree node and save it
%
% We set this up here because we might have multiple task configuration
% files (see below) that each add chidren to it
maintask = topsTreeNode('dotsTask');
maintask.iterations = 1; % Go once through the set of tasks
maintask.startFevalable = {@run, startCallList};
maintask.finishFevalable = {@run, finishCallList};
datatub{'Control'}{'mainTask'} = maintask;

%% ---- Configure experiment
%
%
% Set argument list based on location
%   locations are 'office' (default), 'OR', or 'debug'
if nargin < 1 || isempty(location)
   location = 'office';
end

switch location
   
   case {'OR'}
      arguments = { ...
         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         'sendTTLs',             true, ...
         'displayIndex',         1, ... % 0=small, 1=main
         'useRemoteDrawing',     true, ...
         };
      
   case {'debug'}
      arguments = { ...
         'taskSpecs',            {'VGS' 1, 'MGS', 1, 'Quest' 6 'SN' 2 'AN' 2}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'sendTTLs',             false, ...
         'uiDevice',             'dotsReadableHIDKeyboard', ... % or 'dotsReadableEyeMouseSimulator'
         'displayIndex',         0, ... % 0=small, 1=main
         'useRemoteDrawing',     true, ...
         };
      
   otherwise
      arguments = { ...
         'taskSpecs',            {'Quest' 5 'SN' 5 'AN' 5}, ...
... %         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         'sendTTLs',             false, ...
         'displayIndex',         0, ... % 0=small, 1=main
         'useRemoteDrawing',     false, ...
         };
end

% Call the configuration routine
%
DBSconfigure(maintask, datatub, arguments{:});

%% ---- Start data logging
%
% Start data logging and save the datatub to the data file
topsDataLog.flushAllData(); % Flush stale data, just in case
topsDataLog.logDataInGroup(struct(datatub), 'datatub');
topsDataLog.writeDataFile(fullfile(datatub{'Input'}{'filePath'}, 'Raw', ...
   datatub{'Input'}{'fileName'}));

%% ---- Run the task
%
maintask.run();

%% ---- Write data log to file
%
topsDataLog.writeDataFile();
