function pathname = getDataFilepath(studyName)
% function pathname = getDataFilepath(studyName)
%
% Define machine-specific pathnames to save/find data files
%
% Created 5/26/18 by jig

[~,machineName] = system('scutil --get ComputerName');
switch deblank(machineName)
   
   case 'GoldLabMacbookPro'
      pathname = '/Users/lab/ActiveFiles/Data';
      
   case 'LabMacMini'
      pathname = '/Users/neurosurgery/ActiveFiles/Data';
      
   case 'GoldLaptop'
      pathname = '/Users/jigold/GoldWorks/Local/Data/Projects';
      
    case 'PsychophysicsMacMini'
        pathname = '/Users/joshuagold/Psychophysics/Data';
        
   otherwise
      % Default: use current directory
      pathname = '.';
end

% add the study name
if nargin >= 1 && ~isempty(studyName)
   pathname = fullfile(pathname, studyName);
end
