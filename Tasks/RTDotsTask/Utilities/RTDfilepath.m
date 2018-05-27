function pathname = RTDfilepath()
% function pathname = RTDfilepath()
%
% RTD = Response-Time Dots
%
% Define machine-specific pathnames to save/find data files
%
% Created 5/26/18 by jig

[~,machineName] = system('scutil --get ComputerName');
switch deblank(machineName)
   
   case 'GoldLabMacbookPro'
      pathname = '/Users/lab/ActiveFiles/Data/RTDdata';
      
   case 'LabMacMini'
      pathname = '/Users/neurosurgery/ActiveFiles/Data/RTDdata';
      
   case 'GoldLaptop'
      pathname = '/Users/jigold/GoldWorks/Local/Data/Projects/RTDots';
      
   otherwise
      % Default: use current directory
      pathname = '.';
end

