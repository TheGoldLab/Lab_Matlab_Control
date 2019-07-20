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
         p = inputParser;
         p.StructExpand = false;
         p.KeepUnmatched = true;
         p.addParameter('displayIndex',     0);
         p.addParameter('remoteDrawing',    false);
         p.addParameter('topNode',          []);
         p.parse(varargin{:});

         % Get the remaining optional args
         args = orderParams(p.Unmatched, varargin, true);
         
         % Create it
         self = self@topsTaskHelper('screenEnsemble', [], ...
            'fevalable',  {@dotsTheScreen.theEnsemble, ...
            p.Results.remoteDrawing, p.Results.displayIndex}, args{:});
         
         % Bind to the treeNode
         if ~isempty(p.Results.topNode)
            p.Results.topNode.addCall('start',  {@callObjectMethod, @open},  'start',  self.theObject);
            p.Results.topNode.addCall('finish', {@callObjectMethod, @close}, 'finish', self.theObject);
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
