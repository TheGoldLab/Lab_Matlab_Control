classdef TestDotsReadableHID < TestDotsReadable
    
    methods
        function self = TestDotsReadableHID(name)
            self = self@TestDotsReadable(name);
        end
        
        function readable = newReadable(self)
            readable = dotsReadableDummy();
            readable.isAvailable = false;
        end
        
        function verifyCalibration(self, components, ...
                rawRange, deadRange, calibratedRange, granularity)
            
            rawMins = [components.CalibrationSaturationMin];
            rawMaxes = [components.CalibrationSaturationMax];
            assertTrue(all(rawMins == rawRange(1)), ...
                'not all raw mins agree')
            assertTrue(all(rawMaxes == rawRange(2)), ...
                'not all raw maxes agree')
            
            deadMins = [components.CalibrationDeadZoneMin];
            deadMaxes = [components.CalibrationDeadZoneMax];
            assertTrue(all(deadMins == deadRange(1)), ...
                'not all dead mins agree')
            assertTrue(all(deadMaxes == deadRange(2)), ...
                'not all dead maxes agree')
            
            calibrationMins = [components.CalibrationMin];
            calibrationMaxes = [components.CalibrationMax];
            assertTrue(all(calibrationMins == calibratedRange(1)), ...
                'not all calibration mins agree')
            assertTrue(all(calibrationMaxes == calibratedRange(2)), ...
                'not all calibration maxes agree')
            
            granularities = [components.CalibrationGranularity];
            assertTrue(all(granularities == granularity(1)), ...
                'not all granularities agree')
        end
        
        function testCalibration(self)
            readable = self.newReadable();
            
            if isobject(readable) && readable.isAvailable
                % set some silly calibration values
                rawRange = [-1 2];
                deadRange = [-3 4];
                calibratedRange = [-5 6];
                granularity = 100;
                IDs = readable.getComponentIDs();
                components = readable.setComponentCalibration(IDs, ...
                    rawRange, deadRange, calibratedRange, granularity);
                
                % check that new values were returned and applied
                self.verifyCalibration(components, ...
                    rawRange, deadRange, calibratedRange, granularity);
                self.verifyCalibration(readable.components, ...
                    rawRange, deadRange, calibratedRange, granularity);
                
                % omit any new calibration values
                IDs = readable.getComponentIDs();
                components = readable.setComponentCalibration(IDs);
                
                % check that calibration values are unchanged
                self.verifyCalibration(components, ...
                    rawRange, deadRange, calibratedRange, granularity);
                self.verifyCalibration(readable.components, ...
                    rawRange, deadRange, calibratedRange, granularity);

                readable.close();
            end
        end
    end
end