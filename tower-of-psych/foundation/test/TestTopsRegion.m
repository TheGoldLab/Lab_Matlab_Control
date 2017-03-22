classdef TestTopsRegion < TestCase
    
    methods
        function self = TestTopsRegion(name)
            self = self@TestCase(name);
        end
        
        function space = newCubeSpace(self, nDims, nSide)
            % make several dimensions
            dims = topsDimension.empty(0, nDims);
            for ii = 1:nDims
                name = sprintf('dim %d', ii);
                min = 1;
                max = nSide;
                nPoints = nSide;
                dims(ii) = topsDimension(name, min, max, nPoints);
            end
            
            % aggregate dimensions into a sweet, sweet hypercubic space
            space = topsSpace('cube', dims);
        end
        
        function testPartitionSizes(self)
            % for several hypercube sizes
            %   test partition operators for intuitive fractioning
            
            for cubeSize = 1:5
                space = self.newCubeSpace(cubeSize, cubeSize);
                value = floor(cubeSize/2);
                dim = space.dimensions(1);
                region = topsRegion('partition sizes', space);
                
                fraction = sum(dim.points < value)/dim.nPoints;
                region = region.setPartition(dim.name, value, '<');
                nPointsExpected = fraction*space.nPoints;
                assertEqual(nPointsExpected, region.nPoints, ...
                    'incorrect nPoints for partition');
                
                fraction = sum(dim.points > value)/dim.nPoints;
                region = region.setPartition(dim.name, value, '>');
                nPointsExpected = fraction*space.nPoints;
                assertEqual(nPointsExpected, region.nPoints, ...
                    'incorrect nPoints for partition');
                
                fraction = sum(dim.points <= value)/dim.nPoints;
                region = region.setPartition(dim.name, value, '<=');
                nPointsExpected = fraction*space.nPoints;
                assertEqual(nPointsExpected, region.nPoints, ...
                    'incorrect nPoints for partition');
                
                fraction = sum(dim.points >= value)/dim.nPoints;
                region = region.setPartition(dim.name, value, '>=');
                nPointsExpected = fraction*space.nPoints;
                assertEqual(nPointsExpected, region.nPoints, ...
                    'incorrect nPoints for partition');
                
                fraction = sum(dim.points == value)/dim.nPoints;
                region = region.setPartition(dim.name, value, '==');
                nPointsExpected = fraction*space.nPoints;
                assertEqual(nPointsExpected, region.nPoints, ...
                    'incorrect nPoints for partition');
                
                fraction = sum(dim.points ~= value)/dim.nPoints;
                region = region.setPartition(dim.name, value, '!=');
                nPointsExpected = fraction*space.nPoints;
                assertEqual(nPointsExpected, region.nPoints, ...
                    'incorrect nPoints for partition');
            end
        end
        
        function testCombinationSizes(self)
            % make an x-y space
            nSide = 1000;
            nWidth = floor(0.4*nSide);
            nLeft = 1;
            nRight = floor(0.6*nSide);
            nBig = floor(0.8*nSide);
            dims(1) = topsDimension('x', 1, nSide, nSide);
            dims(2) = topsDimension('y', 1, nSide, nSide);
            space = topsSpace('xy', dims);
            
            % left and right rectangles are disjoint
            left = topsRegion('left', space);
            left = left.setRectangle('x', 'y', ...
                [nLeft 1 nWidth nSide], 'in');
            right = topsRegion('right', space);
            right = right.setRectangle('x', 'y', ...
                [nRight 1 nWidth nSide], 'in');
            
            regions = [left right];
            both = regions.combine('intersection');
            assertEqual(0, both.nPoints, ...
                'disjoint intersection should be zero')
            either = regions.combine('union');
            assertEqual(right.nPoints + left.nPoints, either.nPoints, ...
                'disjoint union should be sum of regions')
            
            % big rectangle is a superset of the left rectangle
            big = topsRegion('big', space);
            big = big.setRectangle('x', 'y', [nLeft 1 nBig nSide], 'in');
            
            regions = [left big];
            both = regions.combine('intersection');
            assertEqual(left.nPoints, both.nPoints, ...
                'superset should not steal points from intersection')
            either = regions.combine('union');
            assertEqual(big.nPoints, either.nPoints, ...
                'subset should not contribute points to union')
            
            % big rectangle partially overlaps the right rectangle
            regions = [right big];
            either = regions.combine('union');
            assertEqual(nSide*nSide, either.nPoints, ...
                'overlap region should cover entire space')
            
            % rectangles include edges, so add 2
            nPointsExpected = nSide * (nBig-nRight+2);
            both = regions.combine('intersection');
            assertEqual(nPointsExpected, both.nPoints, ...
                'overlap region should have intuitive size')
        end
    end
end