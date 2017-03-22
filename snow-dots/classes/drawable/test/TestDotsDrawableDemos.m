classdef TestDotsDrawableDemos < dotsTestCase
    % Locate "demoDrawable*" functions and run through them.
    
    methods
        function self = TestDotsDrawableDemos(name)
            self = self@dotsTestCase(name);
        end
        
        function testInvokeDrawableDemos(self)
            delay = dotsTestCase.getGlobalValue('lookSee');
            if isempty(delay)
                delay = 0;
            end
            
            demoFilter = 'demo.*Draw';
            demoFiles = findFiles(dotsRoot(), demoFilter);
            nDemos = numel(demoFiles);
            for ii = 1:nDemos
                [demoPath, demoName, demoExt] = fileparts(demoFiles{ii});
                demoFunc = str2func(demoName);
                feval(demoFunc, delay);
            end
        end
    end
end