classdef TestDotsReadableDummy < TestDotsReadable
    
    methods
        function self = TestDotsReadableDummy(name)
            self = self@TestDotsReadable(name);
        end
        
        function readable = newReadable(self)
            readable = dotsReadableDummy();
        end
        
        function testWaitForEvent(self)
            % use an array of predictable dummies
            readables(1) = dotsReadableDummy();
            readables(2) = dotsReadableDummy();
            
            % define one simple event for each
            v = 5;
            for ii = 1:numel(readables)
                readable = readables(ii);
                IDs = readable.getComponentIDs();
                readable.defineEvent(IDs(1), 'first', 5, 5);
            end
            
            % wait for one of the readables to report the event
            maxWait = 10;
            [didHappen, waitTime, data, readable] = ...
                dotsReadable.waitForEvent(readables, 'first', maxWait);
            
            % check the event accounting
            assertTrue(didHappen, 'dummy should report event');
            assertTrue(waitTime < maxWait, ...
                'should not run out of waiting time')
            assertEqual(data(3), v, ...
                'waited event data should match defined event data')
            assertEqual(1, sum(readable == readables), ...
                'exactly one readable should report waited event')
        end
        
        function testEventHappening(self)
            % use dummy with predictable behavior
            readable = dotsReadableDummy();
            
            % define two simple events
            IDs = readable.getComponentIDs();
            readable.defineEvent(IDs(1), 'first', 1, 1);
            readable.defineEvent(IDs(2), 'second', 1, 1);
            
            % before any read(), no event should be happening
            [eventName, eventID, names, IDs] = ...
                readable.getHappeningEvent();
            assertTrue(isempty(eventName), ...
                'no event name should happen before read()');
            assertTrue(isempty(IDs), ...
                'no event IDs should happen before read()');
            
            % after one read, both events should be happening
            readable.read();
            [eventName, eventID, names, IDs] = ...
                readable.getHappeningEvent();
            assertFalse(isempty(eventName), ...
                'an event name should happen after one read()');
            assertEqual(sort(IDs(1:2)), sort(IDs), ...
                'both event IDs should happen after one read()');
            
            % static methods should report the same happening result
            [isHappening, data, readable] = ...
                dotsReadable.isEventHappening(readable, 'first');
            assertTrue(isHappening, ...
                'static method should report first event');
            [isHappening, data, readable] = ...
                dotsReadable.isEventHappening(readable, 'second');
            assertTrue(isHappening, ...
                'static method should report second event');
            
            % after two reads, neither event should still be happening
            readable.read();
            [eventName, eventID, names, IDs] = ...
                readable.getHappeningEvent();
            assertTrue(isempty(eventName), ...
                'no event name should happen after two read()s');
            assertTrue(isempty(IDs), ...
                'no event IDs should happen after two read()s');
            
            % static methods should report the same not-happening result
            [isHappening, data, readable] = ...
                dotsReadable.isEventHappening(readable, 'first');
            assertFalse(isHappening, ...
                'static method should not report first event');
            [isHappening, data, readable] = ...
                dotsReadable.isEventHappening(readable, 'second');
            assertFalse(isHappening, ...
                'static method should not report second event');
        end
        
        function testEventQueue(self)
            % use dummy with predictable behavior
            readable = dotsReadableDummy();
            
            % make sure the queue will need be resized
            readable.initialEventQueueSize = 1;
            readable.initialize();
            
            % define the event of interest for each component
            %   first component at least v/2
            %   second component exactly equals v
            %   third component equals anything but v
            v = 500;
            IDs = readable.getComponentIDs();
            readable.defineEvent(IDs(1), 'first', -inf, v/2);
            readable.defineEvent(IDs(2), 'second', v, v);
            readable.defineEvent(IDs(3), 'third', v, v, true);
            
            %readable.plotData();
            % %%
            
            % read in enough data to trigger each event
            nReads = v;
            
            for ii = 1:nReads
                readable.read();
            end
            
            nEvents = readable.getNumberOfEvents();
            assertTrue(nEvents > 0, ...
                'should have detected events of interest');
            
            % peek at the first event
            isPeek = true;
            [name, data] = readable.getNextEvent(isPeek);
            assertFalse(isempty(name), 'should get a peek at event name');
            assertFalse(isempty(data), 'should get a peek at event data');
            nEventsAfterPeek = readable.getNumberOfEvents();
            assertEqual(nEvents, nEventsAfterPeek, ...
                'peeking should not change number of events');
            
            % how many of each event do we expect?
            %   assume each read() incremented each component value
            expectedEventCount(IDs(1)) = floor(v/2);
            expectedEventCount(IDs(2)) = 1;
            expectedEventCount(IDs(3)) = v-1;
            
            % how many of each event was detected?
            eventCount = zeros(1, max(IDs));
            while readable.getNumberOfEvents() > 0
                [name, data] = readable.getNextEvent();
                ID = data(1);
                eventCount(ID) = eventCount(ID) + 1;
            end
            assertEqual(expectedEventCount, eventCount, ...
                'expected and detected events disagree');
        end
    end
end