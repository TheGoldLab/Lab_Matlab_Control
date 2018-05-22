function RTDsetGazeWindow(ui, name, isInverted, isActive)
% function RTDsetGazeWindow(ui, name, isInverted, isActive)
%
% RTD = Response-Time Dots
%
% Utility to update gaze window settings
%
% 5/11/18 written by jig

if isa(ui, 'dotsReadableEyePupilLabs')
   
   if ~iscell(name)
      name = {name};
   end
   
   for ii = 1:length(name)
      
      % Toggle the isInverted flag and set to active
      ui.addGazeWindow(name{ii}, ...
         'isInverted', isInverted(ii), ...
         'isActive', isActive(ii));
   end
end
