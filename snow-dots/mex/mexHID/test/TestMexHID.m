classdef TestMexHID < TestCase
    
    properties
        
    end
    
    methods
        function self = TestMexHID(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            mexHID('terminate');
            clear mexHID
        end
        
        function tearDown(self)
            mexHID('terminate');
            clear mexHID
        end
        
        function deviceIDs = openTestDevices(self)
            devices = mexHID('summarizeDevices');
            assertTrue(isstruct(devices), ...
                'should get struct array of device properties')
            
            n = length(devices);
            %n = 1;
            deviceIDs = [];
            for ii = 1:n
                % Ignore devices without a product ID--they're trouble.
                if ~isempty(devices(ii).ProductID)
                    matching = devices(ii);
                    deviceID = mexHID('openMatchingDevice', matching);
                    assertTrue(isnumeric(deviceID), ...
                        'should get numeric device ID for matched device')
                    assertFalse(deviceID < 0, ...
                        sprintf('device ID %d should be nonnegative', ...
                        deviceIDs))
                    deviceIDs(end+1) = deviceID;
                end
            end
        end
        
        function closeTestDevices(self, deviceIDs)
            for ii = 1:length(deviceIDs)
                s = mexHID('closeDevice', deviceIDs(ii));
                assertFalse(s < 0, ...
                    sprintf('closeDevice status %d should be nonnegative', s));
            end
        end
        
        function testInternalsInfo(self)
            reportStruct = mexHID('getReportStructTemplate');
            assertTrue(isstruct(reportStruct), ...
                'should get a report info struct template');
            
            fuzz = -10:10;
            for ff = fuzz
                reportName = mexHID('getNameForReportType', ff);
                reportType = mexHID('getReportTypeForName', reportName);
                reportNameAgain = mexHID('getNameForReportType', reportType);
                assertEqual(reportName, reportNameAgain, ...
                    'report names should converge');
                
                description = mexHID('getDescriptionOfReturnValue', ff);
                assertTrue(ischar(description), ...
                    'should get string description of numeric value');
                
                description = mexHID('getDescriptionOfReturnValue', reportName);
                assertTrue(ischar(description), ...
                    'should get string description of non-numeric value');
            end
            description = mexHID('getDescriptionOfReturnValue', []);
            assertTrue(ischar(description), ...
                'should get string description of nonempty value');
            
            description = mexHID('getDescriptionOfReturnValue');
            assertTrue(ischar(description), ...
                'should get string description of missing value');
        end
        
        function testExclusiveOpen(self)
            mexHID('initialize');
            
            matching.UsagePage = mexHIDUsage.numberForPageName( ...
                'GenericDesktop');
            matching.Usage = mexHIDUsage.numberForUsageNameOnPage( ...
                'Keyboard', matching.UsagePage);
            
            % open with various "yes" options should succeed once
            isExclusive = {true 1};
            for ii = 1:length(isExclusive)
                deviceIDFirst = mexHID('openMatchingDevice', ...
                    matching, isExclusive{ii});
                if deviceIDFirst >=0
                    sameDevice = mexHID('getDeviceProperties', deviceIDFirst);
                    deviceIDSecond = mexHID('openMatchingDevice', ...
                        sameDevice, isExclusive{ii});
                    assertTrue(deviceIDSecond < 0, ...
                        'should fail to re-seize seized device');
                    mexHID('closeDevice', deviceIDSecond);
                end
                mexHID('closeDevice', deviceIDFirst);
            end
            
            % open with no option should succeed
            deviceID = mexHID('openMatchingDevice', matching);
            assertFalse(deviceID < 0, ...
                'should open HID keyboard without isExclusive option');
            mexHID('closeDevice', deviceID);
            
            % open with various "no" options should succeed
            isExclusive = {false, 0, []};
            for ii = 1:length(isExclusive)
                deviceID = mexHID('openMatchingDevice', ...
                    matching, isExclusive{ii});
                assertFalse(deviceID < 0, ...
                    'should open HID keyboard with not-isExclusive');
                mexHID('closeDevice', deviceID);
            end
            
            mexHID('terminate');
        end
        
        function testQueueFunctions(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            % call without queues, should not crash
            status = mexHID('startQueue', deviceIDs);
            status = mexHID('stopQueue', deviceIDs);
            status = mexHID('flushQueue', deviceIDs);
            status = mexHID('closeQueue', deviceIDs);
            
            % create useless queues
            callback = {@queueCallback, self};
            depth = 10;
            inputMatching.Type = 1;
            for ii = 1:length(deviceIDs)
                inputsCookies = mexHID('findMatchingElements', ...
                    deviceIDs(ii), inputMatching);
                status = mexHID('openQueue', deviceIDs(ii), ...
                    inputsCookies, callback, depth);
            end
            
            % call with queues, should not crash
            status = mexHID('startQueue', deviceIDs);
            status = mexHID('stopQueue', deviceIDs);
            status = mexHID('flushQueue', deviceIDs);
            status = mexHID('closeQueue', deviceIDs);
            
            self.closeTestDevices(deviceIDs);
            mexHID('terminate');
        end
        
        function queueCallback(self, data)
        end
        
        % is there a naive but safe way to read and write reports?
        function testReadWriteReport(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            nReports = 10;
            [reportStruct(1:nReports).ID] = deal(-1*(1:nReports));
            [reportStruct(1:nReports).type] = deal(-1*(1:nReports));
            for ii = 1:length(deviceIDs)
                [readReports, timing] = mexHID('readDeviceReport', ...
                    deviceIDs(ii), reportStruct);
                assertEqual(numel(readReports), nReports, ...
                    'shold read as many reports as given')
                assertEqual(size(timing, 1), nReports, ...
                    'shold get timing for as many reports as given')
                
                [status, timing] = mexHID('writeDeviceReport', ...
                    deviceIDs(ii), readReports);
            end
            
            self.closeTestDevices(deviceIDs);
            mexHID('terminate');
        end
        
        % is it always safe to read and write a device's features?
        function testReadWriteWithTiming(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            for ii = 1:length(deviceIDs)
                deviceInfo = mexHID('getDeviceProperties', deviceIDs(ii));
                % disp(sprintf('%s by %s', ...
                %     deviceInfo.Product, deviceInfo.Manufacturer))
                
                % get all elements
                allElements = mexHID('summarizeElements', deviceIDs(ii));
                allCookies = [allElements.ElementCookie];
                featureType = mexHIDUsage.numberForElementTypeName('Feature');
                isFeature = [allElements.Type] == featureType;
                isReporting = [allElements.ReportID] > 0;
                features = allCookies(isFeature & isReporting);
                
                [valueData, readTiming] = mexHID('readElementValues', ...
                    deviceIDs(ii), features);
                
                if ~isscalar(valueData)
                    [status, writeTiming] = mexHID('writeElementValues', ...
                        deviceIDs(ii), valueData(:,1), valueData(:,2));
                end
            end
            
            self.closeTestDevices(deviceIDs);
            mexHID('terminate');
        end
        
        function testNoArgs(self)
            % should print usage examples
            mexName = 'mexHID';
            result = evalc(mexName);
            assertFalse(isempty(strfind(result, mexName)), ...
                sprintf('no-args should print usage string for %s', mexName));
        end
        
        function testClearAllNoCrash(self)
            % make sure "clear all" call when a device is open
            %   dones't crash Matlab
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            clear all
            %clear mex
            %clear classes
            mexHID('terminate');
        end
        
        function testElementsSetCalibration(self)
            
            calibrationProps = { ...
                'CalibrationMin', ...
                'CalibrationMax', ...
                'CalibrationSaturationMin', ...
                'CalibrationSaturationMax', ...
                'CalibrationDeadZoneMin', ...
                'CalibrationDeadZoneMax', ...
                'CalibrationGranularity'};
            calibrationZeros = cell2struct( ...
                num2cell(zeros(1, length(calibrationProps))), ...
                calibrationProps, 2);
            calibrationOnes = cell2struct( ...
                num2cell(ones(1, length(calibrationProps))), ...
                calibrationProps, 2);
            
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            for ii = 1:length(deviceIDs)
                allElements = mexHID('summarizeElements', deviceIDs(ii));
                allCookies = [allElements.ElementCookie];
                
                status = mexHID('setElementProperties', deviceIDs(ii), allCookies, calibrationZeros);
                getCalibration = mexHID('getElementProperties', deviceIDs(ii), allCookies, calibrationProps);
                for jj = 1:length(allCookies)
                    assertEqual(calibrationZeros, getCalibration(jj), ...
                        'should have set 0 for all calibration properties');
                end
                
                status = mexHID('setElementProperties', deviceIDs(ii), allCookies, calibrationOnes);
                getCalibration = mexHID('getElementProperties', deviceIDs(ii), allCookies, calibrationProps);
                for jj = 1:length(allCookies)
                    assertEqual(calibrationOnes, getCalibration(jj), ...
                        'should have set 1 for all calibration properties');
                end
            end
            
            self.closeTestDevices(deviceIDs)
            mexHID('terminate');
        end
        
        function testElementsSetProperties(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            for ii = 1:length(deviceIDs)
                % get all elements
                allElements = mexHID('summarizeElements', deviceIDs(ii));
                assertTrue(isstruct(allElements), 'should get struct of properties for all elements')
                allCookies = [allElements.ElementCookie];
                allProperties = fieldnames(allElements);
                
                % set all elements and properties in a big batch
                %   using the same values for all elements
                status = mexHID('setElementProperties', deviceIDs(ii), allCookies, allElements(1));
                assertFalse(status < 0, 'setElementProperties uniform batch should return positive status')
                
                
                % set all elements and properties in a big batch
                %   using separate values for each element
                status = mexHID('setElementProperties', deviceIDs(ii), allCookies, allElements);
                assertFalse(status < 0, 'setElementProperties batch should return positive status')
                
                % set each element and each non-empty property individually
                for jj = 1:length(allElements)
                    for kk = 1:length(allProperties)
                        value = allElements(jj).(allProperties{kk});
                        if ~isempty(value)
                            propStruct = struct;
                            propStruct.(allProperties{kk}) = value;
                            status = mexHID('setElementProperties', deviceIDs(ii), allCookies(jj), propStruct);
                            assertFalse(status < 0, 'setElementProperties individually should return positive status')
                        end
                    end
                end
            end
            
            self.closeTestDevices(deviceIDs)
            mexHID('terminate');
        end
        
        function testElementsGetProperties(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            for ii = 1:length(deviceIDs)
                % get all elements
                allElements = mexHID('summarizeElements', deviceIDs(ii));
                assertTrue(isstruct(allElements), 'should get struct of properties for all elements')
                allCookies = [allElements.ElementCookie];
                allProperties = fieldnames(allElements);
                
                % get all properties for each element
                %   verify that values match the summary
                for jj = 1:length(allElements)
                    values = mexHID('getElementProperties', ...
                        deviceIDs(ii), allCookies(jj), allProperties);
                    assertTrue(isstruct(values), 'should get element property values in a struct array')
                    assertEqual(allProperties, fieldnames(values), 'struct should have same number of field names as given properties')
                    assertEqual(values, allElements(jj), 'values for each element should match summary values')
                end
                
                
                % get each property for all elements at once
                %   verify that values match the summary
                for jj = 1:length(allProperties)
                    values = mexHID('getElementProperties', ...
                        deviceIDs(ii), allCookies, allProperties(jj));
                    assertTrue(isstruct(values), 'should get element property values in a struct array')
                    assertTrue(isfield(values, allProperties{jj}), ...
                        'property values struct should have field with propterty name')
                    assertEqual(numel(values), numel(allCookies), 'struct should have same number of elements as given cookies')
                    
                    gotValues = {values.(allProperties{jj})};;
                    summaryValues = {allElements.(allProperties{jj})};
                    assertEqual(gotValues, summaryValues, 'values for each property should match summary values')
                end
            end
            
            self.closeTestDevices(deviceIDs);
            mexHID('terminate');
        end
        
        function testElementMatching(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            for ii = 1:length(deviceIDs)
                % get all elements
                allElements = mexHID('summarizeElements', deviceIDs(ii));
                assertTrue(isstruct(allElements), 'should get struct of properties for all elements')
                
                % get each element by matching properties, without cookie,
                %   verify that original cookie is among the results
                noCookies = rmfield(allElements, 'ElementCookie');
                for jj = 1:length(allElements)
                    matchingCookies = mexHID('findMatchingElements', deviceIDs(ii), noCookies(jj));
                    assertTrue(all(matchingCookies > 0), 'should get positive cookie values for matching elements')
                    
                    cookie = allElements(jj).ElementCookie;
                    assertTrue(any(matchingCookies == cookie), ...
                        'original element cookie should be among matched element cookies');
                end
                
                % Could match on ElementCookie, as well
                %   This usually works.
                %   However, sometimes a very similar element with a
                %   different cookie is matched instead.  IOKit bug?
            end
            
            self.closeTestDevices(deviceIDs);
            mexHID('terminate');
        end
        
        function testElementSummary(self)
            mexHID('initialize');
            deviceIDs = self.openTestDevices;
            
            for ii = 1:length(deviceIDs)
                % get all elements
                allElements = mexHID('summarizeElements', deviceIDs(ii));
                assertTrue(isstruct(allElements), 'should get struct of properties for all elements')
                
                allCookies = [allElements.ElementCookie];
                sortedCookies = sort(allCookies);
                disp(sortedCookies(diff(sortedCookies)==0))
                assertEqual(sort(allCookies), unique(allCookies), 'cookies must be unique')
                
                % get each element by cookie,
                %   compare to "all" result with matching cookie
                for jj = 1:length(allElements)
                    oneElement = mexHID('summarizeElements', deviceIDs(ii), allCookies(jj));
                    assertTrue(isstruct(oneElement), 'should get struct of properties for each element')
                    assertTrue(isscalar(oneElement), 'should get scalar struct for each element')
                    
                    cookie = oneElement.ElementCookie;
                    sameElement = allElements(allCookies==cookie);
                    assertEqual(oneElement, sameElement, ...
                        'summarizeElements for one or all element should give same result');
                end
            end
            
            self.closeTestDevices(deviceIDs);
            mexHID('terminate');
        end
        
        function testAccountForOpened(self)
            opened = mexHID('getOpenedDevices');
            assertTrue(isempty(opened), 'pre-initialize, opened devices shoud be empty')
            
            mexHID('initialize');
            opened = mexHID('getOpenedDevices');
            assertTrue(isempty(opened), 'pre-openMatchingDevice, opened devices shoud be empty')
            
            deviceIDs = self.openTestDevices;
            opened = mexHID('getOpenedDevices');
            assertEqual(sort(deviceIDs), sort(opened), 'post-openMatchingDevice, opened devices should match deviceIDs returned from openMatchingDevice')
            assertEqual(sort(deviceIDs), unique(deviceIDs), 'post-openMatchingDevice, returned deviceIDs should be unique')
            assertEqual(sort(opened), unique(opened), 'post-openMatchingDevice, opened devices should have unique IDs')
            
            self.closeTestDevices(deviceIDs);
            opened = mexHID('getOpenedDevices');
            assertTrue(isempty(opened), 'post-closeDevice, opened devices shoud be empty')
            
            mexHID('terminate');
            opened = mexHID('getOpenedDevices');
            assertTrue(isempty(opened), 'post-terminate, opened devices shoud be empty')
        end
        
        function testMatchPropsOpenClose(self)
            mexHID('initialize');
            
            devices = mexHID('summarizeDevices');
            assertTrue(isstruct(devices), 'should get struct array of device properties')
            
            n = length(devices);
            for ii = 1:n
                matching = devices(ii);
                deviceIDs = mexHID('openAllMatchingDevices', matching);
                assertTrue(isnumeric(deviceIDs), ...
                    'should get numeric device ID for matched, oped device')
                assertTrue(all(deviceIDs >= 0), ...
                    'should device ID should be nonnegative')
                
                nMatched = length(deviceIDs);
                props = mexHID('getDeviceProperties', deviceIDs);
                assertTrue(isstruct(props), ...
                    'should get struct of device properties')
                assertEqual(numel(props), nMatched, ...
                    'property struct have an element for each matched decvice')
                
                isExactPropMatch = false(1,nMatched);
                for jj = 1:nMatched
                    isExactPropMatch(jj) = ...
                        isequalwithequalnans(matching, props(jj));
                end
                assertTrue(any(isExactPropMatch), ...
                    'should have found >=1 exact property match devices')
                
                s = mexHID('closeDevice', deviceIDs);
                assertFalse(s < 0, ...
                    sprintf('closeDevice device status %d should be nonnegative', s));
            end
            
            mexHID('terminate');
        end
        
        function testInitTerminate(self)
            isInit = logical(mexHID('isInitialized'));
            assertFalse(isInit, 'should not report initialized before initialize')
            
            s = mexHID('initialize');
            assertFalse(s < 0, ...
                sprintf('initialize status %d should be nonnegative', s));
            isInit = logical(mexHID('isInitialized'));
            assertTrue(isInit, 'should report initialized after initialize')
            
            s = mexHID('initialize');
            assertFalse(s < 0, ...
                sprintf('re-initialize status %d should be nonnegative', s));
            isInit = logical(mexHID('isInitialized'));
            assertTrue(isInit, 'should report initialized after re-initialize')
            
            s = mexHID('terminate');
            assertFalse(s < 0, ...
                sprintf('terminate status %d should be nonnegative', s));
            assertFalse(mislocked('mexHID'), ...
                'mexHID should not be locked after termiating')
            isInit = logical(mexHID('isInitialized'));
            assertFalse(isInit, 'should not report initialized after terminate')
            
            s = mexHID('terminate');
            assertFalse(s < 0, ...
                sprintf('re-terminate status %d should be nonnegative', s));
            isInit = logical(mexHID('isInitialized'));
            assertFalse(isInit, 'should not report initialized after re-terminate')
        end
        
        function testCheckTimestamps(self)
            n = 100;
            timstamps = zeros(1,n);
            for ii = 1:n
                timestamps(ii) = mexHID('check');
            end
            assertTrue(timestamps(1) < timestamps(n), ...
                'last timestamp should be greater than the first');
            assertTrue(all(diff(timestamps)) >= 0, ...
                'timestamps should be monotonic non-decreasing');
        end
    end
end