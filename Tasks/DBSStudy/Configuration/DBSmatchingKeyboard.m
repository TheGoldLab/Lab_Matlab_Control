function kb = DBSmatchingKeyboard()
% function kb = DBSmatchingKeyboard()
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
      
      if any([infoStruct.ProductID]==610)
         
         % OR macBook pro built-in keboard
         matching.ProductID = 610;
         matching.PrimaryUsage = 6;
      end
      
   case 'LabMacMini'
      
      if any([infoStruct.ProductID]==50475)
         
         % OR mac mini wireless keyboard
         matching.ProductID = 50475;
         matching.PrimaryUsage = 6;
      end
      
   case 'GoldLaptop'
      
      if any([infoStruct.VendorID]==1008)
         
         % HP keyboard
         matching.VendorID = 1008;
         matching.ProductID = 36;
         
      else % if any([infoStruct.ProductID]==632)
         
         % built-in keboard
         matching.ProductID = 632;
         matching.PrimaryUsage = 6;
      end            
end

% get the keyboard
kb = dotsReadableHIDKeyboard(matching);