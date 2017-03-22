classdef TestTopsFoundation < TestCase
    % Core tests for all topsFoundation classes.
    
    methods
        function self = TestTopsFoundation(name)
            self = self@TestCase(name);
        end
        
        % Make a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = topsFoundation(varargin{:});
        end
        
        function testGUI(self)
            object = self.newObject('gui test');
            fig = object.gui();
            drawnow();
            close('all');
        end
    end
end