classdef topsTaskHelperEnsemble < topsTaskHelper
   % Class topsTaskHelper
   %
   % Standard interface for adding snow-dots "helper" objects to a
   % topsTreeNode
   
   properties (SetObservable)
      
   end
   
   properties (SetAccess = private)
      
   end
  
   methods
      
      % Constuct with the ensemble object
      function self = topsTaskHelperEnsemble(theObject)
         
         % Create it
         self = self@topsTaskHelper(class(theObject));
      end      
      

   end
end