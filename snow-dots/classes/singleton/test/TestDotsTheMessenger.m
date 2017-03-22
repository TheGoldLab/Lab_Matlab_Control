classdef TestDotsTheMessenger < dotsTestCase
    
    properties
        numerics;
        nonNumerics;
        
        theMessenger;
        clientSock;
        serverSock;
        receiveTimeout;
        ackTimeout;
        
        freePort;
    end
    
    methods
        function self = TestDotsTheMessenger(name)
            self = self@dotsTestCase(name);
        end
        
        function setUp(self)
            self.setUp@dotsTestCase;
            
            clear mex
            dotsTheMessenger.reset();
            
            self.numerics = {uint8(3), 44.65, pi, ...
                nan, inf, -inf, ...
                1:10, (-100:10)*exp(1), int16(0:5), ...
                eye(10), [1 2 3;4 5 6], single(eps*ones(50,4))};
            
            self.nonNumerics = {true, false, ...
                logical([0 1 1 0; 1 1 0 1]), ...
                @size, @cheese, ...
                @TestDotsTheMessenger.aStaticMethod, ...
                @TestDotsTheMessenger.nonexistantStaticMethod, ...
                '@function', 'a', char(42:126), ...
                ['aaaaaaa';'zzzzzzz';'ggggggg']};
            
            self.theMessenger = dotsTheMessenger.theObject();
            
            % locate two ports that are not usually used by Snow Dots
            self.freePort = 1 + max( ...
                self.theMessenger.defaultClientPort, ...
                self.theMessenger.defaultServerPort);
            self.theMessenger.defaultClientPort = self.freePort;
            self.theMessenger.defaultServerPort = self.freePort + 1;
            
            self.clientSock = self.theMessenger.openDefaultClientSocket();
            self.serverSock = self.theMessenger.openDefaultServerSocket();
            self.receiveTimeout = 0.1;
            self.ackTimeout = -1;
        end
        
        function tearDown(self)
            self.tearDown@dotsTestCase;
        end
        
        function testUniqueSockets(self)
            IP = self.theMessenger.defaultClientIP;
            remotePort = self.freePort;
            localPorts = remotePort + (1:5);
            sockets = zeros(size(localPorts));
            for ii = 1:length(localPorts)
                sockets(ii) = self.theMessenger.openSocket( ...
                    IP, localPorts(ii), IP, remotePort);
            end
            assertEqual(sort(sockets), sort(unique(sockets)), ...
                'each socket ID should be unique')
        end
        
        function testToServer(self)
            absoluteTolerance = 1e-6;
            for ii = 1:length(self.numerics)
                status = self.theMessenger.sendMessageFromSocket( ...
                    double(self.numerics{ii}), ...
                    self.clientSock, ...
                    self.ackTimeout);
                assertTrue(status > 0, 'send message error');
            end
            
            for ii = 1:length(self.numerics)
                [received, status] = ...
                    self.theMessenger.receiveMessageAtSocket( ...
                    self.serverSock, ...
                    self.receiveTimeout);
                assertTrue(status > 0, 'receive message error');
                assertFalse(isempty(received), ...
                    'should have got message from client')
                
                assertElementsAlmostEqual( ...
                    double(self.numerics{ii}), received, ...
                    'absolute', absoluteTolerance, ...
                    sprintf('received %f should almost sent %f', ...
                    received, double(self.numerics{ii})))
            end
        end
        
        function testToClient(self)
            for ii = 1:length(self.nonNumerics)
                status = self.theMessenger.sendMessageFromSocket( ...
                    self.nonNumerics{ii}, ...
                    self.serverSock, ...
                    self.ackTimeout);
                assertTrue(status > 0, 'send message error');
            end
            
            for ii = 1:length(self.nonNumerics)
                [received, status] = ...
                    self.theMessenger.receiveMessageAtSocket( ...
                    self.clientSock, ...
                    self.receiveTimeout);
                assertTrue(status > 0, 'receive message error');
                assertFalse(isempty(received), ...
                    'should have got message from server')
                
                assertEqual(self.nonNumerics{ii}, received, ...
                    'received value should equal sent value');
            end
        end
        
        function testUnreasonable(self)
            unreasonable = char('a'*ones(1,1e7));
            status = self.theMessenger.sendMessageFromSocket( ...
                unreasonable, ...
                self.clientSock, ...
                self.ackTimeout);
            assertTrue(status < 0, ...
                'should not even try to send a gigantic message')
            
            status = self.theMessenger.sendMessageFromSocket( ...
                unreasonable, ...
                self.serverSock, ...
                self.ackTimeout);
            assertTrue(status < 0, ...
                'should not even try to send a gigantic message')
        end
    end
    
    methods(Static)
        function aStaticMethod
        end
    end
end