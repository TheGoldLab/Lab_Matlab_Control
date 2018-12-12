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
            'fevalable',  {@dotsTheScreen.makeEnsemble, remoteDrawing, displayIndex}, ...
            varargin{:});
         
         % Bind to the treeNode
         if nargin >= 3 && ~isempty(topsTreeNode)
            topsTreeNode.addCall('start',  {@callObjectMethod, @open},  'start',  self.theObject);
            topsTreeNode.addCall('finish', {@callObjectMethod, @close}, 'finish', self.theObject);
         end
         
         % Add synchronization
         self.sync.clockFevalable = {@callObjectMethod, self.theObject, @getCurrentTime};
      end
      
      % Overloaded synchronize function to save offset in dotsTheScreen
      %      
      function synchronize(self)
        
         % Call superclass method
         self.synchronize@topsTaskHelper();
         
         % Save offset in the screen singleton object
         dotsTheScreen.setOffsetTime(self.sync.results.offset);
      end
   end
end
