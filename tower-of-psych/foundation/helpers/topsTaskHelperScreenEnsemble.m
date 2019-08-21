classdef topsTaskHelperScreenEnsemble < topsTaskHelper
   % Class topsTaskHelperScreenEnsemble
   %
   % Add topsTaskHelperScreenEnsemble, a subclass of topsTaskHelper
   
   properties (SetObservable)
      
   end
   
   methods
      
      % Constuct the helper
      %
      % Optional parameters:
      %  displayIndex         ... used by dotsTheScreen
      %  remoteDrawing        ... flag
      %  topsTreeNode         ... typically the top node, to bind
      function self = topsTaskHelperScreenEnsemble(varargin)
         
         % Parse the arguments
         [parsedArgs, passedArgs] = parseHelperArgs('screenEnsemble', varargin, ...
            'displayIndex',     0,     ...
            'remoteDrawing',    false, ...
            'topNode',          []);
         
         % Create it
         self = self@topsTaskHelper(passedArgs{:}, ...
            'fevalable',  {@dotsTheScreen.theEnsemble, ...
            parsedArgs.remoteDrawing, parsedArgs.displayIndex});
         
         % Bind to the treeNode
         if ~isempty(parsedArgs.topNode)
            parsedArgs.topNode.addCall('start',  {@callObjectMethod, @open},  'start',  self.theObject);
            parsedArgs.topNode.addCall('finish', {@callObjectMethod, @close}, 'finish', self.theObject);
         end
         
         % Add synchronization
         self.sync.clockFevalable = {@callObjectMethod, self.theObject, @getCurrentTime};
      end
      
      % Overloaded startTrial function to save sync data in dotsTheScreen
      %      
      function startTrial(self, varargin)
        
         % Call superclass method
         self.startTrial@topsTaskHelper(varargin{:});
         
         % Save offset in the screen singleton object
         dotsTheScreen.setSyncTimes(self.sync.results.offset, ...
             self.sync.results.referenceTime);
      end
   end
end
