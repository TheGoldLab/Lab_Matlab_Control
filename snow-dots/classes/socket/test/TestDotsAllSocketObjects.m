classdef TestDotsAllSocketObjects < TestCase
    
    properties
        classname;
        socketObject;
        
        address;
        ports;
        shortBytes;
        longBytes;
        
        many;
    end
    
    methods (Static)
        function waitSeveralMiliseconds(self)
            pause(.005)
        end
    end
    
    methods
        function self = TestDotsAllSocketObjects(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            clear mex
            
            self.address = '127.0.0.1';
            self.ports = 49300 + (1:20);
            self.shortBytes = ones(1,10, 'uint8');
            self.longBytes = ones(1,1e3, 'uint8');
            self.many = 1e2;
            
            % expect subclass constructor to supply a class name
            if ischar(self.classname) && exist(self.classname, 'file')
                self.socketObject = feval(self.classname);
            end
        end
        
        function tearDown(self)
            if isobject(self.socketObject)
                self.socketObject.closeAll;
            end
        end
        
        function testOpenCloseManyTimes(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            for ii = 1:self.many
                id = self.socketObject.open( ...
                    self.address, self.ports(1), ...
                    self.address, self.ports(2));
                assertTrue(id >= 0 , ...
                    'Should get nonnegative socket id');
                
                status = self.socketObject.close(id);
                assertTrue(status >= 0 , ...
                    'Should get nonnegative close status');
            end
        end
        
        function testCheckManyTimes(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            id = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(2));
            
            for ii = 1:self.many
                hasData = self.socketObject.check(id);
            end
        end
        
        function testReadManyTimes(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            id = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(2));
            
            for ii = 1:self.many
                data = self.socketObject.readBytes(id);
            end
        end
        
        function testWriteManyTimes(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            id(1) = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(2));
            
            id(2) = self.socketObject.open( ...
                self.address, self.ports(2), ...
                self.address, self.ports(1));
            
            data = self.shortBytes;
            for ii = 1:self.many
                status = self.socketObject.writeBytes(id(1), data);
            end
        end
        
        function testSendToSelf(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            id = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(1));
            
            assertFalse(self.socketObject.check(id), ...
                'socket should have nothing yet')
            
            % send self the short message
            data = self.shortBytes;
            self.socketObject.writeBytes(id, data);
            TestDotsAllSocketObjects.waitSeveralMiliseconds;
            assertTrue(self.socketObject.check(id), ...
                'socket should have data')
            readData = self.socketObject.readBytes(id);
            assertEqual(data, readData, 'should read data sent to self')
            
            % send self the short message
            data = self.longBytes;
            self.socketObject.writeBytes(id, data);
            TestDotsAllSocketObjects.waitSeveralMiliseconds;
            hasData = self.socketObject.check(id);
            assertTrue(self.socketObject.check(id), ...
                'socket should have data')
            readData = self.socketObject.readBytes(id);
            assertEqual(data, readData, 'should read data sent to self')
        end
        
        function testReadWriteReciprocally(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            id(1) = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(2));
            
            id(2) = self.socketObject.open( ...
                self.address, self.ports(2), ...
                self.address, self.ports(1));
            
            data{1} = self.shortBytes;
            data{2} = self.longBytes;
            
            assertFalse(self.socketObject.check(id(1)), ...
                'socket 1 should have nothing yet')
            assertFalse(self.socketObject.check(id(2)), ...
                'socket 2 should have nothing yet')
            
            self.socketObject.writeBytes(id(1), data{1});
            TestDotsAllSocketObjects.waitSeveralMiliseconds;
            assertFalse(self.socketObject.check(id(1)), ...
                'socket 1 should have nothing still')
            assertTrue(self.socketObject.check(id(2)), ...
                'socket 2 should have data now')
            
            self.socketObject.writeBytes(id(2), data{2});
            TestDotsAllSocketObjects.waitSeveralMiliseconds;
            assertTrue(self.socketObject.check(id(1)), ...
                'socket 1 should have data now')
            assertTrue(self.socketObject.check(id(2)), ...
                'socket 2 should have data still')
            
            readData{1} = self.socketObject.readBytes(id(2));
            assertEqual(data{1}, readData{1}, ...
                'socket 2 should have read data sent from socket 1')
            
            assertTrue(self.socketObject.check(id(1)), ...
                'socket 1 should have data still')
            assertFalse(self.socketObject.check(id(2)), ...
                'socket 2 should have nothing now')
            
            readData{2} = self.socketObject.readBytes(id(1));
            assertEqual(data{2}, readData{2}, ...
                'socket 1 should have read data sent from socket 2')
            
            assertFalse(self.socketObject.check(id(1)), ...
                'socket 1 should have nothing again')
            assertFalse(self.socketObject.check(id(2)), ...
                'socket 2 should have nothing again')
        end
        
        function testOpenSeveralSockets(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            n = length(self.ports);
            for ii = 1:n
                id(ii) = self.socketObject.open( ...
                    self.address, self.ports(ii), ...
                    self.address, self.ports(ii));
                
                assertEqual(ii, length(unique(id)), ...
                    'each socket should have its own id');
            end
        end
        
        function testQueuedData(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            id(1) = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(2));
            
            id(2) = self.socketObject.open( ...
                self.address, self.ports(2), ...
                self.address, self.ports(1));
            
            data = self.shortBytes;
            
            for ii = 1:self.many
                self.socketObject.writeBytes(id(1), data);
                TestDotsAllSocketObjects.waitSeveralMiliseconds;
            end
            
            for ii = 1:self.many
                TestDotsAllSocketObjects.waitSeveralMiliseconds;
                readData = self.socketObject.readBytes(id(2));
                assertEqual(data, readData, ...
                    sprintf('should have read queued data %d of %d', ...
                    ii, self.many))
            end
            
            assertFalse(self.socketObject.check(id(2)), ...
                'should have no more queued data')
        end
        
        function testBlockingCheck(self)
            if ~isobject(self.socketObject)
                return;
            end
            
            % open a self-socket
            id = self.socketObject.open( ...
                self.address, self.ports(1), ...
                self.address, self.ports(1));
            
            timeoutSecs = 0.1;
            hasMessage = self.socketObject.check(id, timeoutSecs);
            assertFalse(hasMessage > 0, ...
                'should block and return with no message');
            
            status = self.socketObject.writeBytes(id, self.shortBytes);
            assertTrue(status >= 0, ...
                'should get nonnegative send status')
            
            hasMessage = self.socketObject.check(id, timeoutSecs);
            assertTrue(hasMessage > 0, ...
                'should block and return with message')
        end
    end
end