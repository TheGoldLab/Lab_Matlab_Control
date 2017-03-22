classdef TestTopsSpace < TestCase
    
    properties
        nDims = 10;
    end
    
    methods
        function self = TestTopsSpace(name)
            self = self@TestCase(name);
        end
        
        function space = randomSpace(self)
            % make several dimensions
            dims = topsDimension.empty(0, self.nDims);
            for ii = 1:self.nDims
                name = sprintf('dim %d', ii);
                min = (rand(1,1) - 0.5) * 1e6;
                max = (rand(1,1) - 0.5) * 1e6;
                nPoints = ii;
                dims(ii) = topsDimension(name, min, max, nPoints);
            end
            
            % aggregate dimensions into a space
            space = topsSpace('abc', dims);
        end
        
        function testMinMaxSubs(self)
            space = self.randomSpace();
            
            % get the min value from each dimension
            mins = [space.dimensions.minimum];
            subs = space.subscriptsForValues(mins);
            subValues = space.valuesForSubscripts(subs);
            assertElementsAlmostEqual(mins, subValues, ...
                'inaccurate min subscripts')
            
            % get the max value from each dimension
            maxs = [space.dimensions.maximum];
            subs = space.subscriptsForValues(maxs);
            subValues = space.valuesForSubscripts(subs);
            assertElementsAlmostEqual(maxs, subValues, ...
                'inaccurate max subscripts')
        end
        
        function testSillySubs(self)
            space = self.randomSpace();
            
            % make some silly values
            mins = [space.dimensions.minimum];
            maxs = [space.dimensions.maximum];
            sillys = mins + ...
                rand(1,numel(space.dimensions)) .* (maxs - mins);
            
            
            % get subscripts nearest the silly values
            sillySubs = space.subscriptsForValues(sillys);
            values = space.valuesForSubscripts(sillySubs);
            valueSubs = space.subscriptsForValues(values);
            assertEqual(sillySubs, valueSubs, ...
                'inaccurate subscripts for values')
        end
        
        function testGrandIndexes(self)
            space = self.randomSpace();
            
            % convert grand indexes to subscripts and back
            indexes = round(linspace(1, space.nPoints, 1000));
            for ii = indexes
                subscripts = space.subscriptsForIndex(ii);
                grandIndex = space.indexForSubscripts(subscripts);
                assertEqual(ii, grandIndex, ...
                    'inaccurate grand indexing')
            end
        end
    end
end