classdef TestDotsAllDOutObjects < TestCase
    
    properties
        classname;
        dOutObject;
        
        ports;
        channels;
        words;
        shortSignal;
        longSignal;
        frequencies;
        
        integer;
        several;
    end
    
    methods
        function self = TestDotsAllDOutObjects(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.integer = 2^32-1;
            self.several = 100;
            
            self.ports = 0:2;
            self.channels = 0:2;
            self.words = floor(linspace(0, 2^15-1, self.several));
            self.shortSignal = [false, false, true, true, false];
            self.longSignal = [[1:self.several > self.several/2], false];
            self.frequencies = [100 1000 5000];
            
            % expect subclass constructor to supply a class name
            if ischar(self.classname) && exist(self.classname, 'file')
                self.dOutObject = feval(self.classname);
            end
        end
        
        function tearDown(self)
            if isobject(self.dOutObject)
                self.dOutObject.close;
            end
        end
        
        function testSendSeveralWords(self)
            if ~isobject(self.dOutObject) || ~self.dOutObject.isAvailable
                return;
            end
            
            for ww = self.words
                for pp = self.ports
                    timestamp = self.dOutObject.sendStrobedWord(ww,pp);
                end
            end
        end
        
        function testSendSeveralTTLPulses(self)
            if ~isobject(self.dOutObject) || ~self.dOutObject.isAvailable
                return;
            end
            
            for ii = 1:self.several
                for cc = self.channels
                    timestamp = self.dOutObject.sendTTLPulse(cc);
                end
            end
        end
        
        function testSendTTLSignals(self)
            if ~isobject(self.dOutObject) || ~self.dOutObject.isAvailable
                return;
            end
            
            for ff = self.frequencies
                for cc = self.channels
                    timestamp = self.dOutObject.sendTTLSignal( ...
                        cc, self.shortSignal, ff);
                    
                    timestamp = self.dOutObject.sendTTLSignal( ...
                        cc, self.longSignal, ff);
                end
            end
        end
    end
end