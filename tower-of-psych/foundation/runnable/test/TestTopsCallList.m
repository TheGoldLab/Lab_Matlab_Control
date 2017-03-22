classdef TestTopsCallList < TestCase
    
    properties
        callList;
        nFunctions;
        orderedFunctions;
        order;
    end
    
    methods
        function self = TestTopsCallList(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.callList = topsCallList;
            
            self.nFunctions = 10;
            self.orderedFunctions = cell(1, self.nFunctions);
            for ii = 1:self.nFunctions
                self.orderedFunctions{ii} = ...
                    {@countValue, self, ii};
            end
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.callList);
            self.callList = [];
        end
        
        function countValue(self, value)
            self.order(end+1) = value;
        end
        
        function stopListFromRunning(self, callList)
            callList.isRunning = false;
        end
        
        function testSingleton(self)
            newList = topsCallList;
            assertFalse(self.callList==newList, ...
                'topsCallList should not be a singleton');
        end
        
        function testRunThroughCalls(self)
            for ii = 1:self.nFunctions
                name = sprintf('%d', ii);
                self.callList.addCall(self.orderedFunctions{ii}, name);
            end
            
            self.callList.alwaysRunning = false;
            self.callList.run;
            
            for ii = 1:self.nFunctions
                fun = self.orderedFunctions{ii};
                value = fun{end};
                assertEqual(self.order(ii), value, ...
                    'should have called functions in the order added')
            end
        end
        
        function testRunUntilStopped(self)
            self.callList.alwaysRunning = true;
            self.callList.addCall({@stopListFromRunning, ...
                self, self.callList}, 'stop');
            self.callList.runBriefly;
            assertFalse(self.callList.isRunning, ...
                'call list should have been stopped from running')
        end
        
        function testToggleIsActive(self)
            self.callList.addCall(self.orderedFunctions{1}, 'one');
            self.callList.addCall(self.orderedFunctions{2}, 'two');
            
            % toggle active directly
            self.callList.setActiveByName(true, 'one');
            self.callList.setActiveByName(false, 'two');
            self.callList.runBriefly;
            assertEqual(length(self.order), 1, ...
                'should have called only one function')
            
            % toggle active while calling by name
            self.order = [];
            self.callList.callByName('one', true);
            self.callList.callByName('two', false);
            self.callList.runBriefly;
            assertEqual(length(self.order), 3, ...
                'should have called three functions')
        end
    end
end