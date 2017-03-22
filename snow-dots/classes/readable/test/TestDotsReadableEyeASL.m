classdef TestDotsReadableEyeASL < TestDotsReadable
    
    methods
        function self = TestDotsReadableEyeASL(name)
            self = self@TestDotsReadable(name);
        end
        
        % make a readable (test subclasses should redefine)
        function readable = newReadable(self)
            readable = dotsReadableEyeASL();
        end
        
        function testFrameNumberRollover(self)
            readable = self.newReadable();
            
            maxInt = 63;
            readable.frameMaxInt = maxInt;
            readable.sampleFrequency = 100;
            readable.initialize();
            
            % make some frame numbers that overflow at maxInt
            frameNumbers = mod(1:100, maxInt+1);
            
            % try to correct the overflow
            corrected = dotsReadableEyeASL.correctOverflow( ...
                frameNumbers, readable.frameMaxInt);
            
            frameDiffs = diff(corrected);
            expectedDiffs = ones(size(frameDiffs));
            assertElementsAlmostEqual(frameDiffs, expectedDiffs, ...
                'frame numbers should have constant increment');
            
            % convert corrected numbers to times
            nowTime = 0;
            frameTimes = dotsReadableEyeASL.computeFrameTimes( ...
                corrected, nowTime, readable.sampleFrequency);
            
            frameDiffs = diff(frameTimes);
            expectedDiffs = ones(size(frameDiffs))./readable.sampleFrequency;
            assertElementsAlmostEqual(frameDiffs, expectedDiffs, ...
                'frame times should have uniform diff');
            
            % reconstruct frame numbers from times
            timedFrames = [corrected(end), nowTime];
            reconstructed = dotsReadableEyeASL.reconstructFrameNumbers( ...
                frameTimes, timedFrames, readable.sampleFrequency);
            assertElementsAlmostEqual(corrected, reconstructed, ...
                'reconstructed frame numbers do not match originals');
            
            readable.close();
        end
    end
end