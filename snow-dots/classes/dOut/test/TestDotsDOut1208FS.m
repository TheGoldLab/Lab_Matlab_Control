classdef TestDotsDOut1208FS < TestDotsAllDOutObjects
    % @class TestDotsDOut1208FS
    % Include TestDotsDOut1208FS in Snow Dots digital output tests
    methods
        function self = TestDotsDOut1208FS(name)
            self = self@TestDotsAllDOutObjects(name);
            self.classname = 'dotsDOut1208FS';
        end
    end
end