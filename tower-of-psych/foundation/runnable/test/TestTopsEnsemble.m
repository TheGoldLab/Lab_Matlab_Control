classdef TestTopsEnsemble < TestTopsFoundation
    % Ensemble tests should always access objects through ensemble methods.
    % Otherwise it's unfair to expect consistency.
    
    methods
        function self = TestTopsEnsemble(name)
            self = self@TestTopsFoundation(name);
        end
        
        % Get a suitable topsFoundation object
        function object = newObject(self, varargin)
            object = self.getEnsemble(varargin{:});
        end
        
        % test subclass may override to produce subclass
        function ensemble = getEnsemble(self, name)
            ensemble = topsEnsemble(name);
        end
        
        function testAddContainsRemoveObject(self)
            nObjects = 5;
            ensemble = self.getEnsemble('test');
            
            % add several objects, specify ordering
            objects = cell(1, nObjects);
            for ii = 1:nObjects
                objects{ii} = topsFoundation(num2str(ii));
                index = ensemble.addObject(objects{ii}, ii);
                
                assertEqual(ii, index, 'should add with given index')
            end
            
            % verify addition
            for ii = 1:nObjects
                [isContained, index] = ...
                    ensemble.containsObject(objects{ii});
                
                assertTrue(isContained, 'should contain object')
                assertEqual(ii, index, 'should contain at given index')
            end
            
            % remove all at once
            removed = ensemble.removeObject(1:nObjects);
            assertEqual(objects, removed, ...
                'should return all removed objects')
            
            % verify removal
            for ii = 1:nObjects
                [isContained, index] = ...
                    ensemble.containsObject(objects{ii});
                
                assertFalse(isContained, 'should contain object')
            end
        end
        
        function testSetGetObjectProperty(self)
            % ensemble of two objects
            a = topsFoundation('dumb name');
            b = topsFoundation('dumb name');
            ensemble = self.getEnsemble('test');
            aIndex = ensemble.addObject(a);
            bIndex = ensemble.addObject(b);
            
            % set and get indexed object names
            ensemble.setObjectProperty('name', 'a', aIndex);
            ensemble.setObjectProperty('name', 'b', bIndex);
            aName = ensemble.getObjectProperty('name', aIndex);
            assertEqual('a', aName, 'should name "a" object by index')
            bName = ensemble.getObjectProperty('name', bIndex);
            assertEqual('b', bName, 'should name "b" object by index')
            
            % get all object names
            names = ensemble.getObjectProperty('name');
            isA = strcmp(names, a.name);
            assertEqual(1, sum(isA), 'should find one "a" object');
            isB = strcmp(names, b.name);
            assertEqual(1, sum(isB), 'should find one "b" object');
            
            % set and get all object names
            ensemble.setObjectProperty('name', 'dumb name');
            names = ensemble.getObjectProperty('name');
            assertTrue(all(strcmp('dumb name', names)), ...
                'should set all names')
        end
        
        function testCallObjectMethod(self)
            % ensemble of two objects
            a = topsFoundation('dumb name');
            b = topsFoundation('dumb name');
            ensemble = self.getEnsemble('test');
            aIndex = ensemble.addObject(a);
            bIndex = ensemble.addObject(b);
            
            % ask each object if Matlab considers it "valid"
            isValid = ensemble.callObjectMethod(@isvalid);
            assertTrue(isValid{aIndex}, '"a" object should report valid');
            assertTrue(isValid{bIndex}, '"b" object should report valid');
            
            % ask again but ignore the answers
            ensemble.callObjectMethod(@isvalid);
            
            % ask just one object and get a scalar result
            aIsValid = ensemble.callObjectMethod(@isvalid, [], aIndex);
            assertFalse(iscell(aIsValid), ...
                'single object should return scalar result, not cell');
            assertTrue(aIsValid, '"a" single object should report valid');
        end
        
        function testAutomateObjectMethod(self)
            % ensemble of two objects
            a = topsFoundation('dumb name');
            b = topsFoundation('dumb name');
            ensemble = self.getEnsemble('test');
            aIndex = ensemble.addObject(a);
            bIndex = ensemble.addObject(b);
            
            % use static setName() as a phoney object method
            ensemble.automateObjectMethod( ...
                'autoName', @TestTopsEnsemble.setName, {'great name'});
            ensemble.callByName('autoName');
            duration = 1;
            ensemble.run(duration);
            names = ensemble.getObjectProperty('name');
            assertTrue(all(strcmp('great name', names)), ...
                'should set all names via method call')
        end
        
        function testAssignObject(self)
            % ensemble of two objects
            outer = topsFoundation();
            inner = topsFoundation('inner');
            ensemble = self.getEnsemble('test');
            outerIndex = ensemble.addObject(outer);
            innerIndex = ensemble.addObject(inner);
            
            % test assignment by abusing the name property
            %   assign inner to outer.name, plus some deviousPath
            %   dig out deviousPath.name, which should equal inner.name
            %   use the static getDeepValue() instead of direct access
            %   in order to exercise ensemble accessor methods
            
            % test cell element assignment
            subsPath = {'.', 'name', '{}', {7}, '.', 'name'};
            ensemble.assignObject(innerIndex, outerIndex, subsPath{1:4});
            innerName = ensemble.callObjectMethod( ...
                @TestTopsEnsemble.getDeepValue, {subsPath}, outerIndex);
            assertEqual(inner.name, innerName, ...
                'should dig out name of assigned object in a cell')
            
            % clear the assignment
            ensemble.assignObject([], outerIndex, subsPath{1:2});
            
            % test struct assignment
            subsPath = {'.', 'name', '.', 'testField', '.', 'name'};
            ensemble.assignObject(innerIndex, outerIndex, subsPath{1:4});
            innerName = ensemble.callObjectMethod( ...
                @TestTopsEnsemble.getDeepValue, {subsPath}, outerIndex);
            assertEqual(inner.name, innerName, ...
                'should dig out name of assigned object in a cell')
        end
        
        function testPasObject(self)
            % ensemble of two objects
            outer = topsFoundation();
            inner = topsFoundation('inner');
            ensemble = self.getEnsemble('test');
            outerIndex = ensemble.addObject(outer);
            innerIndex = ensemble.addObject(inner);
            
            % use static copyName() as a phoney object method
            ensemble.passObject(innerIndex, outerIndex, ...
                @TestTopsEnsemble.copyName);
            outerName = ensemble.getObjectProperty('name', outerIndex);
            assertEqual(outerName, 'inner', ...
                'outer object should copied inner object name');
            
            % use static mimicName() as a phoney object method
            args = {'before', [], 'after'};
            argIndex = 2;
            ensemble.passObject(innerIndex, outerIndex, ...
                @TestTopsEnsemble.mimicName, args, argIndex);
            outerName = ensemble.getObjectProperty('name', outerIndex);
            expectedName = [args{1} 'inner' args{3}];
            assertEqual(outerName, expectedName, ...
                'outer object should mimiced inner object name');
        end
    end
    
    methods (Static)
        % Set the name of the given object, like a method.
        function setName(object, name)
            object.name = name;
        end
        
        % Drill down into an object property, like a method.
        function value = getDeepValue(object, subsInfo)
            subs = substruct(subsInfo{:});
            value = subsref(object, subs);
        end
        
        % Copy the name of another object, like a method.
        function copyName(object, otherObject)
            object.name = otherObject.name;
        end
        
        % Copy and modify the name of another object, like a method.
        function mimicName(object, prefix, otherObject, suffix)
            object.name = [prefix otherObject.name suffix];
        end
    end
end