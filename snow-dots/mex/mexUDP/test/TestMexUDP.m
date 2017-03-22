classdef TestMexUDP < TestCase
    
    properties
        address;
        port;
        
        shortMessage;
        longMessage;
    end
    
    methods (Static)
        function waitSeveralMiliseconds(self)
            pause(.005)
        end
    end
    
    methods
        function self = TestMexUDP(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            clear mex
            
            self.address = '127.0.0.1';
            self.port = 49300;
            
            self.shortMessage = ones(1, 10, 'uint8');
        end
        
        function tearDown(self)
            mexUDP('closeAll');
        end
        
        function testNoArgs(self)
            % should print usage examples
            mexName = 'mexUDP';
            result = evalc(mexName);
            assertFalse(isempty(strfind(result, mexName)), ...
                sprintf('no-args should print usage string for %s', mexName));
        end
        
        function testOpenThreeArgs(self)
            s = mexUDP('open', self.address, self.address, self.port);
            assertTrue(s >= 0, ...
                'should get nonnegative socket id')
        end
        
        function testOpenFourArgs(self)
            s = mexUDP('open', self.address, self.address, ...
                self.port, self.port);
            assertTrue(s >= 0, ...
                'should get nonnegative socket id')
        end
        
        function testBasicInterface(self)
            s = mexUDP('open', self.address, self.address, ...
                self.port, self.port);
            assertTrue(s >= 0, ...
                'should get nonnegative socket id')
            
            status = mexUDP('sendBytes', s, self.shortMessage);
            assertTrue(status >= 0, ...
                'should get nonnegative send status')
            
            hasMessage = mexUDP('check', s);
            assertTrue(hasMessage > 0, ...
                'should have message sent to self')
            
            readMessage = mexUDP('receiveBytes', s);
            assertEqual(readMessage, self.shortMessage, ...
                'should receive same message send to self');
            
            status = mexUDP('close', s);
            assertTrue(status >= 0, ...
                'should get nonnegative close status')
        end
        
        function testBlockingCheck(self)
            s = mexUDP('open', self.address, self.address, ...
                self.port, self.port);
            assertTrue(s >= 0, ...
                'should get nonnegative socket id')
            
            timeoutSecs = 0.1;
            hasMessage = mexUDP('check', s, timeoutSecs);
            assertFalse(hasMessage > 0, ...
                'should block and return with no message');
            
            status = mexUDP('sendBytes', s, self.shortMessage);
            assertTrue(status >= 0, ...
                'should get nonnegative send status')
            
            hasMessage = mexUDP('check', s, timeoutSecs);
            assertTrue(hasMessage > 0, ...
                'should block and return with message')
        end
    end
end