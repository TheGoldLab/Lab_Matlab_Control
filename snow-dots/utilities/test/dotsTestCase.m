classdef dotsTestCase < TestCase
    methods
        function self = dotsTestCase(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            testSetUp = dotsTestCase.getGlobalValue('testSetUp');
            if ~isempty(testSetUp)
                feval(testSetUp);
            end
        end
        
        function tearDown(self)
            testTearDown = dotsTestCase.getGlobalValue('testTearDown');
            if ~isempty(testTearDown)
                feval(testTearDown);
            end
        end
    end
    
    methods (Static)
        function value = getGlobalValue(valueName)
            global DOTS_TEST_DATA
            value = [];
            if ~isempty(DOTS_TEST_DATA) && ...
                    isfield(DOTS_TEST_DATA, valueName)
                value = DOTS_TEST_DATA.(valueName);
            end
        end
    end
end