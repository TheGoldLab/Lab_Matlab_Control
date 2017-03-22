classdef TestTopsTreeNode < TestTopsFoundation
    
    properties
        treeNode;
    end
    
    methods
        function self = TestTopsTreeNode(name)
            self = self@TestTopsFoundation(name);
        end
        
        % Get a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = topsTreeNode(varargin{:});
        end
        
        function setUp(self)
            self.treeNode = self.newObject();
            self.treeNode.name = 'parent';
            topsDataLog.flushAllData();
        end
        
        function tearDown(self)
            delete(self.treeNode);
            self.treeNode = [];
        end
        
        function testSingleton(self)
            newTreeNode = self.newObject();
            assertFalse(self.treeNode==newTreeNode, ...
                'topsTreeNode should not be a singleton');
        end
        
        function testDepthFirstActionLogging(self)
            child = self.newObject();
            child.name = 'child';
            
            grandchild = self.newObject();
            grandchild.name = 'grandchild';
            
            self.treeNode.addChild(child);
            child.addChild(grandchild);
            
            self.treeNode.run;
            logInfo = topsDataLog.getSortedDataStruct;
            actionInfo = [logInfo.item];
            
            expectedNames = { ...
                self.treeNode.name, ...
                child.name, ...
                grandchild.name, ...
                grandchild.name, ...
                child.name, ...
                self.treeNode.name};
            runnableNames = {actionInfo.runnableName};
            assertEqual(expectedNames, runnableNames, ...
                'wrong node order for tree run()');
            
            start = self.treeNode.startString;
            finish = self.treeNode.finishString;
            expectedActions = {start, start, start, ...
                finish, finish finish};
            actions = {actionInfo.actionName};
            assertEqual(expectedActions, actions, ...
                'wrong action order for tree run()');
        end
        
        function testCatchRecursionException(self)
            errorCauser = {@stupidDoesNotExistasfewqv3fas};
            try
                feval(errorCauser{:})
            catch expectedException
                warning('off', expectedException.identifier)
            end
            
            child = self.treeNode.newChildNode;
            child.startFevalable = errorCauser;
            runner = @()self.treeNode.run;
            assertExceptionThrown(runner, expectedException.identifier, ...
                'treeNode should catch errors during runnung and rethrow')
            
        end        
    end
end