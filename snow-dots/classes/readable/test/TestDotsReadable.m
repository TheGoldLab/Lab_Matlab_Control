classdef TestDotsReadable < dotsTestCase
    
    methods
        function self = TestDotsReadable(name)
            self = self@dotsTestCase(name);
        end
        
        % make a readable (test subclasses should redefine)
        function readable = newReadable(self)
            readable = dotsReadableDummy();
        end
        
        function testStateAtTime(self)
            readable = self.newReadable();
            
            % read in a bunch of data
            nReads = 10;
            for ii = 1:nReads
                readable.read();
            end
            oldState = readable.getState();
            oldTime = max(oldState(:,3));
            
            % read in a bunch of extra data
            nReads = 10;
            for ii = 1:nReads
                readable.read();
            end
            
            % get the state of the readable as though no extra data had
            % been read
            stateAsOfOld = readable.getState(oldTime);
            assertEqual(oldState, stateAsOfOld, ...
                'old state should match state "as of" old time')
            
            readable.close();
        end
        
        function testValueByID(self)
            readable = self.newReadable();

            readable.read();
            state = readable.getState();
            for ID = readable.getComponentIDs();
                stateValue = state(ID,2);
                gotValue = readable.getValue(ID);
                assertEqual(stateValue, gotValue, sprintf( ...
                    'inconsistent values reported for component ID %d', ...
                    ID))
            end
            
            readable.close();
        end
    end
end