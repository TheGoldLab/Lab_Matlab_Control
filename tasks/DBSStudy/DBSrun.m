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
if nargin < 1 || isempty(location)
   location = 'OR';
end

switch location
   
   case {'or' 'OR'}
      arglist = { ...
         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         'sendTTLs',             true, ...
         };
            
   case {'search' 'Search'}
      arglist = { ...
         'taskSpecs',            {'VGS' 200 'NN' 200}, ...
         'sendTTLs',             true, ...
         'coherences',           100, ...
         };
      
   case {'debug' 'Debug'}
      arglist = { ...
...%         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 4 'SN' 1 'AN' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 1}, ... % 'SN' 1 'AN' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'sendTTLs',             false, ...
         'uiList',               'dotsReadableEyePupilLabs', ... %'dotsReadableEyeEyelink', ...%'dotsReadableEyePupilLabs', ... %'dotsReadableHIDKeyboard', ... % or 'dotsReadableEyeMouseSimulator'
         'displayIndex',         0, ... % 0=small, 1=main
         'remoteDrawing',        false, ...
         };
      
   otherwise % office
      arglist = { ...
         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         };
end

%% ---- Call the configuration routine
%
topNode = DBSconfigure(arglist{:});

%% ---- Run it!
%
topNode.run();