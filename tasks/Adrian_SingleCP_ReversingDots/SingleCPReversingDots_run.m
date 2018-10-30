function topNode = SingleCPReversingDots_run(location)
%% function [mainTreeNode, datatub] = DBSrun(location)
%
%
% This function configures, initializes, runs, and cleans up a single change point reversal dots  
%  experiment 
%
% 10/29/18   aer wrote it

%% ---- Clear globals
%
clear globals

%% ---- Configure experiment based on location
%
%   locations are 'office', 'saccades', 'buttons', or 'debug' (default)
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
   location = 'debug';
end

% add something different

switch location
      
   case {'saccades' 'Saccades'}
      arglist = { ...
         'taskSpecs',            {'CP' 5}, ...
         'uiList',               {'dotsReadableDummy', 'dotsReadableEyePupilLabs'}, ...
         'doCalibration',        false, ...
         'sendTTLs',             true, ...
         };
            
   case {'buttons' 'Buttons'}  % Or using buttons
      arglist = { ...
         'taskSpecs',            {'Quest' 40 'CP' 40}, ...
         'sendTTLs',             true, ...
         'uiList',               'dotsReadableHIDButtons', ... 
         };
   
   case {'debug' 'Debug'}
      arglist = { ...
         'taskSpecs',            {'CP' 2}, ...% 'Quest' 4 'SN' 1 'AN' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'uiList',               'dotsReadableHIDKeyboard', ... 
         'displayIndex',         0, ... % 0=small, 1=main
         'remoteDrawing',        false, ...
         'instructionDuration',  20.0,...
         };
      
   otherwise % office
      arglist = { ...
         'taskSpecs',            {'Quest' 8 'CP' 1}, ...
         };
end

%% ---- Call the configuration routine
%
topNode = SingleCPReversingDots_configure(arglist{:});

%% ---- Run it!
%
topNode.run();