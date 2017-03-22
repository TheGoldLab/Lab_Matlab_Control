classdef TestTopsConditions < TestTopsFoundation
    
    properties
        conditions;
        assignmentTarget;
    end
    
    methods
        function self = TestTopsConditions(name)
            self = self@TestTopsFoundation(name);
        end
        
        % Make a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = topsConditions(varargin{:});
        end
        
        function setUp(self)
            self.conditions = self.newObject();
            self.assignmentTarget = '';
        end
        
        function tearDown(self)
            delete(self.conditions);
            self.conditions = [];
        end
        
        function testSingleton(self)
            newConditions = topsConditions;
            assertFalse(self.conditions==newConditions, ...
                'topsConditions should not be a singleton');
        end
        
        function testAssignmentAndCounting(self)
            % get the conditions to count in binary by assigning values to
            % differnt elements of assignmentTarget
            self.conditions.addParameter('ones', {'1', '0'});
            self.conditions.addParameter('twos', {'1', '0'});
            self.conditions.addParameter('fours', {'1', '0'});
            
            self.conditions.addAssignment('ones', ...
                self, '.', 'assignmentTarget', '()', {1});
            self.conditions.addAssignment('twos', ...
                self, '.', 'assignmentTarget', '()', {2});
            self.conditions.addAssignment('fours', ...
                self, '.', 'assignmentTarget', '()', {3});
            
            % run through all the conditions and keep track of the
            % binary numbers assigned
            self.conditions.setPickingMethod('sequential');
            assignedNumbers = [];
            self.conditions.reset;
            while ~self.conditions.isDone
                self.conditions.run;
                assignedNumbers(end+1) = bin2dec(self.assignmentTarget);
            end
            
            % verify that every combination of binary digits was assigned
            expectedNumbers = 0:(self.conditions.nConditions - 1);
            assertEqual(sort(assignedNumbers), expectedNumbers, ...
                'should have traversed a unique integer per condition')
        end
    end
end