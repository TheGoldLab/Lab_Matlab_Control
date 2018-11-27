function topNode = DBSrun(location)
%% function [mainTreeNode, datatub] = DBSrun(location)
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
%
% UIs:
%  'dotsReadableEyeEyelink'
%  'dotsReadableEyePupilLabs'
%  'dotsReadableEyeEOG'
%  'dotsReadableHIDKeyboard'
%  'dotsReadableEyeMouseSimulator'
%  'dotsReadableHIDButtons'
%  'dotsReadableHIDGamepad'

if nargin < 1 || isempty(location)
   location = 'OR';
end

% add something different

switch location
   
   case {'or' 'OR'}
      arglist = { ...
         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         'readables',            {'dotsReadableEyeEOG'}, ... 
         'sendTTLs',             true, ...
         };
      
   case {'orSaccades' 'ORSACCADES'}
      arglist = { ...
         'taskSpecs',            {'VGS' 5 'MGS' 5 'VGS' 5 'MGS' 5 'VGS' 5 'MGS' 5}, ...
         'readables',            {'dotsReadableDummy', 'dotsReadableEyePupilLabs'}, ...
         'doCalibration',        false, ...
         'sendTTLs',             true, ...
         };
            
   case {'buttons' 'Buttons'}  % Or using buttons
      arglist = { ...
         'taskSpecs',            {'Quest' 40 'SN' 40 'AN' 40}, ...
         'sendTTLs',             true, ...
         'readables',            {'dotsReadableHIDButtons'}, ... 
         };
   
   case {'search' 'Search'}
      arglist = { ...
         'taskSpecs',            {'VGS' 200 'NN' 200}, ...
         'sendTTLs',             true, ...
         'coherences',           100, ...
         };
      
   case {'debug' 'Debug'}
      arglist = { ...
         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 4 'SN' 1 'AN' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'readables',            {'dotsReadableHIDKeyboard'}, ... 
         'displayIndex',         1, ... % 0=small, 1=main
         'remoteDrawing',        false, ...
         'sendTTLs',             true, ...
         };
      
   otherwise % office
      arglist = { ...
         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 8 'SN' 1 'AN' 1}, ...
...%         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 25 'AN' 25}, ...
         };
end

%% ---- Call the configuration routine
%
topNode = DBSconfigure(arglist{:});

%% ---- Run it!
%
topNode.run();