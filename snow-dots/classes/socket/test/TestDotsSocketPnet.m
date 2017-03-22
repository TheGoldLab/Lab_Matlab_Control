classdef TestDotsSocketPnet < TestDotsAllSocketObjects
    % @class TestDotsSocketPnet
    % Include dotsSocketPnet in Snow Dots socket tests
    methods
        function self = TestDotsSocketPnet(name)
            self = self@TestDotsAllSocketObjects(name);
            self.classname = 'dotsSocketPnet';
        end
    end
end