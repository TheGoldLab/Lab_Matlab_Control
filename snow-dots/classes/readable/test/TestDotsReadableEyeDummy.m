classdef TestDotsReadableEyeDummy < TestDotsReadable
    
    methods
        function self = TestDotsReadableEyeDummy(name)
            self = self@TestDotsReadable(name);
        end
        
        % make a readable (test subclasses should redefine)
        function readable = newReadable(self)
            readable = dotsReadableEyeDummy();
        end
        
        function testUnitConversion(self)
            readable = self.newReadable();
            
            % test x and y, coordinate conversions using Farenheit and
            % Celsius degrees instead of eye coordinates
            fFreeze = 32;
            fBoil = 212;
            fWidth = fBoil - fFreeze;
            
            cFreeze = 0;
            cBoil = 100;
            cWidth = cBoil - cFreeze;
            
            % assume x goes in as Farenheit y as Celsius
            readable.inputRect = [fFreeze, cFreeze, fWidth, cWidth];
            
            % assume x comes out as Celsius y as Farenheit
            readable.xyRect = [cFreeze, fFreeze, cWidth, fWidth];
            
            readable.initialize();
            
            % make up some input temperature values
            n = 100;
            fInput = linspace(fFreeze, fBoil, n);
            cInput = linspace(cFreeze, cBoil, n);
            readable.inputX = fInput;
            readable.inputY = cInput;
            
            % consume the inputX and -Y and do unit conversions
            readable.read();
            
            % read out the results
            isX = readable.history(:,1) == readable.xID;
            cOutput = readable.history(isX,2);
            
            isY = readable.history(:,1) == readable.yID;
            fOutput = readable.history(isY,2);
            
            % check that conversions were correct
            assertElementsAlmostEqual(fInput(:), fOutput(:), ...
                'Celsius to Farenheit conversion failed (y)');
            assertElementsAlmostEqual(cInput(:), cOutput(:), ...
                'Farenheit to Celsius conversion failed (x)');
        end
    end
end