function mouse = getMatchingMouse()
% function kb = getMatchingMouse()
%
% Utility for selecting particular keyboards associated with particular
% machines
%
% Created 5/28/18 by jig

% Select appropriate keyboard by checking what is available
mexHID('initialize');
infoStruct = mexHID('summarizeDevices');
matching = [];

[~,machineName] = system('scutil --get ComputerName');
switch deblank(machineName)
   
   case 'GoldLabMacbookPro'
            
   case 'LabMacMini'
      
   case 'GoldLaptop'
      
      if any([infoStruct.ProductID]==772)
         
         % optical mouse
         matching.VendorID = 772;
         matching.PrimaryUsage = 2;
         
      else % if any([infoStruct.ProductID]==632)
         
         % built-in keboard
         matching.ProductID = 632;
         matching.PrimaryUsage = 2;
      end            
end

% get the keyboard
mouse = dotsReadableHIDMouse(matching);