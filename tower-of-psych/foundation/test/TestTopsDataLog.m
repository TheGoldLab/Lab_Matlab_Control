classdef TestTopsDataLog < TestTopsFoundation
    
    properties
        groups;
        data;
        filename;
    end
    
    methods
        function self = TestTopsDataLog(name)
            self = self@TestTopsFoundation(name);
        end
        
        % Make a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = topsDataLog.theDataLog();
        end
        
        function setUp(self)
            self.groups = {'animals', 'pizzas', 'phone books'};
            self.data = {1, {'elephant', 'sauce'}, []};
            [p,f] = fileparts(mfilename('fullpath'));
            self.filename = fullfile(p, 'dataLogTest.mat');
            topsDataLog.flushAllData();
        end
        
        function tearDown(self)
            topsDataLog.flushAllData();
            if exist(self.filename)
                delete(self.filename)
            end
        end
        
        function logSomeData(self)
            % add data, redundant under each group
            for g = self.groups
                for d = self.data
                    topsDataLog.logDataInGroup(d{1}, g{1});
                end
            end
        end
        
        function testSingleton(self)
            log1 = topsDataLog.theDataLog;
            log2 = topsDataLog.theDataLog;
            assertTrue(log1==log2, 'topsDataLog should be a singleton');
        end
        
        function testDataRetrievalSortedStruct(self)
            self.logSomeData;
            
            % should get data, sorted by time
            logStruct = topsDataLog.getSortedDataStruct;
            logGroups = {logStruct.group};
            for g = self.groups
                assertEqual( ...
                    sum(strcmp(g{1}, logGroups)), length(self.data), ...
                    'wrong number log entries per group')
            end
            
            logTimes = [logStruct.mnemonic];
            assertTrue(all(diff(logTimes) >= 0), ...
                'log entries should be sorted by time')
        end
        
        function testDataFlush(self)
            % log should arrive flushed, from setUp()
            theLog = topsDataLog.theDataLog;
            assertEqual(theLog.length, 0, ...
                'data log should start with 0 entries')
            assertTrue(isempty(theLog.groups), ...
                'data log should start with no groups')
            
            self.logSomeData;
            topsDataLog.flushAllData;
            assertEqual(theLog.length, 0, ...
                'failed to clear log entries after adding')
            assertTrue(isempty(theLog.groups), ...
                'failed to clear log groups after adding')
        end
        
        function testToFromFile(self)
            theLog = topsDataLog.theDataLog;
            
            % should be safe to write a file before logging data
            topsDataLog.writeDataFile(self.filename);
            assertTrue(exist(self.filename) > 0, ...
                'should have created data file')
            
            % add data to log in memory
            self.logSomeData();
            expectedLength = theLog.length;
            
            % write data to disk and clear data in memory
            topsDataLog.writeDataFile(self.filename);
            topsDataLog.flushAllData();
            assertEqual(theLog.length, 0, ...
                'failed to clear log after saving file')
            
            % recover data from disk
            topsDataLog.readDataFile(self.filename);
            assertEqual(theLog.length, expectedLength, ...
                'read wrong number of data from file')
            
            delete(self.filename);
        end
        
        function testGetNewData(self)
            log = topsDataLog.theDataLog();
            
            newData = topsDataLog.getNewData();
            assertTrue(isempty(newData), ...
                'new log should not have any new data')
            
            self.logSomeData();
            newData = topsDataLog.getNewData();
            assertFalse(isempty(newData), ...
                'log should have some new data')
            
            isNew = topsDataLog.logNewData(newData);
            assertFalse(any(isNew), ...
                'log should not re-add data it already has')
            
            newData = topsDataLog.getNewData();
            assertTrue(isempty(newData), ...
                'log should not report new data twice')
            
            self.logSomeData();
            newData = topsDataLog.getNewData();
            assertFalse(isempty(newData), ...
                'log should have some more new data')
            
            self.logSomeData();
            topsDataLog.flushAllData();
            newData = topsDataLog.getNewData();
            assertTrue(isempty(newData), ...
                'flushed log should have no new data')
        end
    end
end
