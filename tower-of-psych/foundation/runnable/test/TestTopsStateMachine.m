classdef TestTopsStateMachine < TestTopsFoundation
    
    properties
        eventCount;
        stateMachine;
        branchState;
    end
    
    methods
        function self = TestTopsStateMachine(name)
            self = self@TestTopsFoundation(name);
        end
        
        % Get a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = topsStateMachine(varargin{:});
        end
        
        function hearEvent(self, varargin)
            self.eventCount = self.eventCount + 1;
        end
        
        function setUp(self)
            self.stateMachine = self.newObject();
            self.stateMachine.name = 'test machine';
            topsDataLog.flushAllData;
        end
        
        function tearDown(self)
            delete(self.stateMachine);
            self.stateMachine = [];
        end
        
        function stateName = getNextState(self)
            stateName = self.branchState;
        end
        
        function testCallMachineFcns(self)
            self.eventCount = 0;
            machineFcn = @(stateInfo) self.hearEvent;
            self.stateMachine.startFevalable = {machineFcn};
            self.stateMachine.transitionFevalable = {machineFcn};
            self.stateMachine.finishFevalable = {machineFcn};
            
            statesInfo = { ...
                'name',     'next'; ...
                'beginning','middle'; ...
                'middle',   'end'; ...
                'end',      ''; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            self.stateMachine.run;
            
            % expect n+1 function calls for
            %   n-1 transitions, plus beginning, plus end
            expectedCount = length(self.stateMachine.allStates) + 1;
            assertEqual(expectedCount, self.eventCount, ...
                'state machine called wrong number of functions');
        end
        
        function testCallStateFcns(self)
            self.eventCount = 0;
            stateFcn = {@() self.hearEvent};
            
            statesInfo = { ...
                'name',     'next',     'entry',    'exit'; ...
                'beginning','middle',   stateFcn,   stateFcn; ...
                'middle',	'end',      stateFcn,   stateFcn; ...
                'end',      '',         stateFcn,   stateFcn; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            self.stateMachine.run;
            
            % expect 2n function calls for
            %   n entry plus n exit functions
            expectedCount = 2*length(self.stateMachine.allStates);
            assertEqual(expectedCount, self.eventCount, ...
                'state machine called wrong number of state functions');
        end
        
        function testEditState(self)
            stateName = 'middle';
            timeout = 0;
            statesInfo = { ...
                'name',     'next',     'timeout'; ...
                'beginning',stateName,   timeout; ...
                stateName,	'end',      timeout; ...
                'end',      '',         timeout; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            
            info = self.stateMachine.getStateInfoByName(stateName);
            assertEqual(info.timeout, timeout, ...
                'state should have the original timeout value')
            
            newTimeout = 200;
            self.stateMachine.editStateByName(stateName, ...
                'timeout', newTimeout);
            newInfo = self.stateMachine.getStateInfoByName(stateName);
            assertEqual(newInfo.timeout, newTimeout, ...
                'state should have a new timeout value')
            
            index = self.stateMachine.editStateByName('bogus', ...
                'timeout', newTimeout);
            assertTrue(isempty(index), ...
                'editing a nonexisting state should return empty')
        end
        
        function testInputBranching(self)
            % a batch of boring states
            defaultEnd = 'end';
            altEnd1 = 'alt1';
            altEnd2 = 'alt2';
            statesInfo = { ...
                'name',     'next'; ...
                'beginning','middle'; ...
                defaultEnd, ''; ...
                altEnd1,    ''; ...
                altEnd2,	''; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            
            % a special middle state which checks for input
            %   and the alternate way of specifying
            m.name = 'middle';
            m.timeout = .005;
            m.next = defaultEnd;
            m.input = {@getNextState, self};
            self.stateMachine.addState(m);
            
            self.branchState = '';
            self.stateMachine.run;
            endName = self.stateMachine.finishState.name;
            assertEqual(endName, defaultEnd, ...
                'empty input should lead to default end')
            
            self.branchState = altEnd1;
            self.stateMachine.run;
            endName = self.stateMachine.finishState.name;
            assertEqual(endName, altEnd1, ...
                'name input should cause branching to named state')
            
            self.branchState = altEnd2;
            self.stateMachine.run;
            endName = self.stateMachine.finishState.name;
            assertEqual(endName, altEnd2, ...
                'name input should cause branching to named state')
        end
        
        function testStateSharedFunctions(self)
            % add some shared functions that will get arguments from the
            % from each state
            sharedFcn = {@countSharedFunctionCall, self};
            self.stateMachine.addSharedFevalableWithName( ...
                sharedFcn, 'enterWith', 'entry');
            self.stateMachine.addSharedFevalableWithName( ...
                sharedFcn, 'exitWith', 'exit');
            
            % add states that "know about" the shared functions
            enterNum = 1;
            exitNum = 10;
            statesInfo = { ...
                'name',     'next',     'enterWith',	'exitWith'; ...
                'beginning','middle',   {enterNum},     {exitNum}; ...
                'middle',	'end',      {enterNum},     {exitNum}; ...
                'end',      '',         {enterNum},     {exitNum}; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            
            % add a new shared function after the fact
            %   the states wont know to add arguments to this one
            extraNum = 100;
            sharedFcn = {@countSharedFunctionCall, self, extraNum};
            self.stateMachine.addSharedFevalableWithName( ...
                sharedFcn, 'extra', 'entry');
            
            self.eventCount = 0;
            self.stateMachine.run;
            expectedCount = length(self.stateMachine.allStates) ...
                * (enterNum + exitNum + extraNum);
            assertEqual(expectedCount, self.eventCount, ...
                'wrong count of state common function calls');
        end
        
        function countSharedFunctionCall(self, number)
            self.eventCount = self.eventCount + number;
        end
        
        function testClassificationBranching(self)
            % a batch of boring states
            defaultEnd = 'end';
            altEnd = 'alt';
            statesInfo = { ...
                'name',     'next'; ...
                'beginning','middle'; ...
                defaultEnd, ''; ...
                altEnd,    ''; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            
            % a special middle state which checks a classification
            m.name = 'middle';
            m.timeout = .005;
            m.next = defaultEnd;
            classn = topsClassification();
            classn.defaultOutput = altEnd;
            m.classification = classn;
            self.stateMachine.addState(m);
            
            self.stateMachine.run;
            endName = self.stateMachine.finishState.name;
            assertEqual(endName, altEnd, ...
                'classification should cause alternate ending')
        end
    end
end