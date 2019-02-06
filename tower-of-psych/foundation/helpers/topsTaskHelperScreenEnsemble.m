classdef topsTaskHelperScreenEnsemble < topsTaskHelper
   % Class topsTaskHelperScreenEnsemble
   %
   % Add topsTaskHelperScreenEnsemble, a subclass of topsTaskHelper
   
   properties (SetObservable)
      
   end
   
   methods
      
      % Constuct the helper
      %
      % Arguments:
      %  displayIndex         ... used by dotsTheScreen
      %  remoteDrawing        ... flag
      %  topsTreeNode         ... typically the top node, to bind
      function self = topsTaskHelperScreenEnsemble(displayIndex, ...
            remoteDrawing, topsTreeNode, varargin)
         
         % Check args
         if nargin < 1 || isempty(displayIndex)
            displayIndex = 0;
         end
         
         if nargin < 2 || isempty(remoteDrawing)
            remoteDrawing = false;
         end
         
         % Create it
         self = self@topsTaskHelper('screenEnsemble', [], ...
            'fevalable',  {@dotsTheScreen.theEnsemble, remoteDrawing, displayIndex}, ...
            varargin{:});
         
         % Bind to the treeNode
         if nargin >= 3 && ~isempty(topsTreeNode)
            topsTreeNode.addCall('start',  {@callObjectMethod, @open},  'start',  self.theObject);
            topsTreeNode.addCall('finish', {@callObjectMethod, @close}, 'finish', self.theObject);
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
          
          disp(self.sync.results.offset)
      end
   end
end
