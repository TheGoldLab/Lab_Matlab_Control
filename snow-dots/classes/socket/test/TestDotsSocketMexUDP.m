classdef TestDotsSocketMexUDP < TestDotsAllSocketObjects
    % @class TestDotsSocketMexUDP
    % Include dotsSocketMexUDP in Snow Dots socket tests
    methods
        function self = TestDotsSocketMexUDP(name)
            self = self@TestDotsAllSocketObjects(name);
            self.classname = 'dotsSocketMexUDP';
        end
    end
end