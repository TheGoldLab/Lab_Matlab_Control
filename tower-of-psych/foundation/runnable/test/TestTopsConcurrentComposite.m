classdef TestTopsConcurrentComposite < TestTopsFoundation
    
    properties
        concurrents;
        nComponents;
        components;
        order;
    end
    
    methods
        function self = TestTopsConcurrentComposite(name)
            self = self@TestTopsFoundation(name);
        end
        
        % Make a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = topsConcurrentComposite(varargin{:});
        end
        
        function setUp(self)
            self.concurrents = self.newObject();
            
            self.nComponents = 10;
            self.components = cell(1, self.nComponents);
            for ii = 1:self.nComponents
                comp = topsConcurrent;
                comp.startFevalable = {@countValue, self, ii};
                self.components{ii} = comp;
            end
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.concurrents);
            self.concurrents = [];
        end
        
        function countValue(self, value)
            self.order(end+1) = value;
        end
        
        function stopRunningComponent(self, component)
            component.isRunning = false;
        end
        
        function testSingleton(self)
            newList = self.newObject();
            assertFalse(self.concurrents==newList, ...
                'topsConcurrentComposite should not be a singleton');
        end
        
        function testRunComponentsEqually(self)
            for ii = 1:self.nComponents
                self.concurrents.addChild(self.components{ii});
            end
            
            self.concurrents.run;
            
            for ii = 1:self.nComponents
                fun = self.components{ii}.startFevalable;
                value = fun{end};
                assertEqual(self.order(ii), value, ...
                    'should have called components in the order added')
            end
        end
    end
end