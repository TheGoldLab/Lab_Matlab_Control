function pathname = DBSfilepath()
% function pathname = DBSfilepath()
%
% Define machine-specific pathnames to save/find data files
%  for DBS experiments
%
% Created 5/26/18 by jig

[~,machineName] = system('scutil --get ComputerName');
switch deblank(machineName)
   
   case 'GoldLabMacbookPro'
      pathname = '/Users/lab/ActiveFiles/Data/DBSStudy';
      
   case 'LabMacMini'
      pathname = '/Users/neurosurgery/ActiveFiles/Data/DBSStudy';
      
   case 'GoldLaptop'
      pathname = '/Users/jigold/GoldWorks/Local/Data/Projects/DBSStudy';
      
   otherwise
      % Default: use current directory
      pathname = '.';
end

