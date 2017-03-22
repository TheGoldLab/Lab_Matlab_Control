classdef TestDotsTheScreen < dotsTestCase
    
    properties
        theScreen;
    end
    
    methods
        function self = TestDotsTheScreen(name)
            self = self@dotsTestCase(name);
        end
        
        function setUp(self)
            self.setUp@dotsTestCase;
            
            dotsTheScreen.reset;
            self.theScreen = dotsTheScreen.theObject;
        end
        
        function tearDown(self)
            self.tearDown@dotsTestCase;
            dotsTheScreen.reset;
        end
        
        function testBlankAccounting(self)
            self.theScreen.open();
            
            % swap buffers to get some info
            info = self.theScreen.blank();
            
            % swap buffers several times
            n = 10;
            info = repmat(info, 1, n);
            for ii = 1:n
                info(ii) = self.theScreen.blank();
            end
            
            % this is a weak test, to be revisited
            assertTrue(info(1).onsetTime < info(n).onsetTime, ...
                'blank onset times should be later and later')
            assertTrue(info(1).onsetFrame < info(n).onsetFrame, ...
                'blank numbers should be increasing')
            assertTrue(info(1).swapTime < info(n).swapTime, ...
                'blank swaps should be later and later')
            
            self.theScreen.close();
        end
        
        function testFrameAccounting(self)
            self.theScreen.open();
            
            % swap buffers to get some info
            info = self.theScreen.nextFrame();
            
            % swap buffers several times
            n = 10;
            info = repmat(info, 1, n);
            for ii = 1:n
                info(ii) = self.theScreen.nextFrame();
            end
            
            % this is a weak test, to be revisited
            assertTrue(info(1).onsetTime < info(n).onsetTime, ...
                'frame onset times should be later and later')
            assertTrue(info(1).onsetFrame < info(n).onsetFrame, ...
                'frame numbers should be increasing')
            assertTrue(info(1).swapTime < info(n).swapTime, ...
                'flush swaps should be later and later')
            
            self.theScreen.close();
        end
        
        function testRedundantOpenClose(self)
            self.theScreen.open();
            self.theScreen.open();
            self.theScreen.close();
            self.theScreen.open();
            self.theScreen.close();
            self.theScreen.close();
        end
        
        function testResetShouldCloseWindow(self)
            self.theScreen.open();
            dotsTheScreen.reset;
            assertTrue(self.theScreen.getDisplayNumber() < 0, ...
                'the screen should know its window has closed')
        end
    end
end