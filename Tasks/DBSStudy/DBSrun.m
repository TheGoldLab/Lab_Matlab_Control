function [mainTreeNode, datatub] = DBSrun(location, useGUI)
%% function [mainTreeNode, datatub] = DBSrun(location, useGUI)
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

%% ---- Configure experiment based on location
%
%   locations are 'office' (default), 'OR', or 'debug'
if nargin < 1 || isempty(location)
   location = 'OR';
end

switch location
   
   case {'OR'}
      arglist = { ...
         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         'sendTTLs',             true, ...
         };
            
   case {'search'}
      arglist = { ...
         'taskSpecs',            {'VGS' 200 'NN' 200}, ...
         'sendTTLs',             true, ...
         'coherences',           100, ...
         };
       
   case {'debug'}
      arglist = { ...
         'taskSpecs',            {'VGS' 1, 'MGS', 1, 'Quest' 8 'SN' 2 'AN' 2}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'sendTTLs',             false, ...
         'userInput',            'dotsReadableEyePupilLabs', ...%'dotsReadableEyePupilLabs', ... %'dotsReadableHIDKeyboard', ... % or 'dotsReadableEyeMouseSimulator'
         'displayIndex',         0, ... % 0=small, 1=main
         'useRemoteDrawing',     false, ...
         };
        
   otherwise % office
      arglist = { ...
         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 10 'SN' 5 'AN' 5}, ...
...%         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         };
end

% Call the configuration routine
%
[mainTreeNode, datatub] =  DBSconfigure(arglist{:});

%% ---- Start the gui or run the task
if nargin < 2 || isempty(useGUI)
   useGUI = true;
end

if useGUI
   mainTreeNode.startGUI('eyeGUI', datatub{'Control'}{'userInputDevice'});
else
   mainTreeNode.run();
end
