classdef TestDotsMglVertexBufferObject < TestCase
    % Test behavior of Snow Dots Vertex Buffer Object extensions to MGL
    %   info = dotsMglCreateVertexBufferObject(data, ...
    %       [targetIndex, usageIndex, elementsPerVertex, elementStride])
    %   data = dotsMglReadFromVertexBufferObject(info, [offset, nElements])
    %   nElements = dotsMglWriteToVertexBufferObject(info, data, [offset, doReallocate])
    %   nVertices = dotsMglDrawVertexBufferObject(info, ...
    %       [primitive, color, pointSize, offset, nElements])
    %   dotsMglDeleteVertexBufferObject(info)
    
    properties
        megaData;
        tinyData;
        types;
    end
    
    methods
        function self = TestDotsMglVertexBufferObject(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            clear mex
            
            % about 1MB of data
            mega = 1e6;
            doubleSize = 8;
            n = mega/doubleSize;
            self.megaData = rand(1, n);
            
            % one double
            self.tinyData = rand(1, 1);
            
            % several mxArray types to read and write
            self.types = {'double', 'single', ...
                'int8', 'int16', 'int32', 'int64', ...
                'uint8', 'uint16', 'uint32', 'uint64'};
            
            mglOpen(0);
        end
        
        function tearDown(self)
            mglClose();
            clear mex
        end
        
        function testEmpty(self)
            % safe to try to make empty VBO
            data = [];
            info = dotsMglCreateVertexBufferObject(data);
            
            % safe to read and write bogus VBO
            data = dotsMglReadFromVertexBufferObject(info);
            assertTrue(isempty(data), ...
                'should not read data from empty VBO');
            nElements = dotsMglWriteToVertexBufferObject(info, data);
            assertTrue(nElements <=0, 'should not write to empty VBO');
            
            % safe to delete bogus VBO
            dotsMglDeleteVertexBufferObject(info);
        end
        
        function testTinyVBO(self)
            % try to make tiny VBO with default target and usage
            info = dotsMglCreateVertexBufferObject(self.tinyData);
            
            data = dotsMglReadFromVertexBufferObject(info);
            assertEqual(data, self.tinyData, ...
                'should read original VBO data');
            
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, self.tinyData);
            assertEqual(nElements, numel(self.tinyData), ...
                'should write tiny elements to tiny VBO');
            
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, self.megaData);
            assertTrue(nElements <= 0, ...
                'should not write mega elements to tiny VBO');
            
            dotsMglDeleteVertexBufferObject(info);
        end
        
        function testMegaVBO(self)
            % try to make mega-sized VBO with custom target, usage,
            % elementsPerVertex, and elementStride
            custom.targetIndex = 1;
            custom.usageIndex = 1;
            custom.elementsPerVertex = 3;
            custom.elementStride = 3;
            info = dotsMglCreateVertexBufferObject(self.megaData, ...
                custom.targetIndex, custom.usageIndex, ...
                custom.elementsPerVertex, custom.elementStride);
            assertTrue(isstruct(info), 'should get VBO info struct');
            fn = fieldnames(custom);
            for ii = 1:numel(fn)
                name = fn{ii};
                assertTrue(isfield(info, name), ...
                    sprintf('VBO info struct should have %s', name));
                assertEqual(custom.(name), info.(name), ...
                    sprintf('VBO info has incorrect %s', name));
            end
            
            data = dotsMglReadFromVertexBufferObject(info);
            assertEqual(data, self.megaData, ...
                'should read original VBO data');
            
            newData = rand(size(self.megaData));
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, newData);
            assertEqual(nElements, numel(newData), ...
                'should write new elements to mega VBO');
            
            dotsMglDeleteVertexBufferObject(info);
        end
        
        function testConcurrentObects(self)
            % try to use two VBOs concurrently
            mega = dotsMglCreateVertexBufferObject(self.megaData);
            tiny = dotsMglCreateVertexBufferObject(self.tinyData, 1, 1);
            
            megaRead = dotsMglReadFromVertexBufferObject(mega);
            assertEqual(megaRead, self.megaData, ...
                'should read original mega-sized VBO data');
            
            dotsMglDeleteVertexBufferObject(mega);
            
            tinyRead = dotsMglReadFromVertexBufferObject(tiny);
            assertEqual(tinyRead, self.tinyData, ...
                'should read original tiny VBO data');
            
            dotsMglDeleteVertexBufferObject(tiny);
        end
        
        function testReadWriteRange(self)
            nDataElements = numel(self.megaData);
            info = dotsMglCreateVertexBufferObject(self.megaData);
            
            % safe to try to read and write with bogus offset and elements
            rangeOffset = nDataElements + 10;
            nRangeElements = 10;
            rangeData = dotsMglReadFromVertexBufferObject( ...
                info, rangeOffset, nRangeElements);
            assertTrue(isempty(rangeData), ...
                'should not read data with out of bounds offset');
            
            newRangeData = rand(1, 10);
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, newRangeData, rangeOffset);
            assertTrue(nElements <= 0, ...
                'should not write data with out of bounds offset');
            
            rangeOffset = nDataElements - 5;
            rangeData = dotsMglReadFromVertexBufferObject( ...
                info, rangeOffset, nRangeElements);
            assertTrue(isempty(rangeData), ...
                'should not read data with out of bounds nElements');
            
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, newRangeData, rangeOffset);
            assertTrue(nElements <= 0, ...
                'should not write data with out of bounds nElements');
            
            % read and write data with 0-based range offset
            %   Matlab index range will be 1-based
            rangeOffset = 10;
            nRangeElements = 100;
            rangeRead = dotsMglReadFromVertexBufferObject( ...
                info, rangeOffset, nRangeElements);
            rangeIndex = rangeOffset + (1:nRangeElements);
            assertEqual(rangeRead, self.megaData(rangeIndex), ...
                'should read data from range');
            
            newRangeData = rand(1, nRangeElements);
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, newRangeData, rangeOffset);
            assertEqual(nElements, numel(newRangeData), ...
                'should write new range of elements to VBO');
            
            rangeRead = dotsMglReadFromVertexBufferObject( ...
                info, rangeOffset, nRangeElements);
            assertEqual(rangeRead, newRangeData, ...
                'should read new data from range');
            
            mixedRead = dotsMglReadFromVertexBufferObject(info);
            mixedData = self.megaData;
            mixedData(rangeIndex) = newRangeData;
            assertEqual(mixedRead, mixedData, ...
                'should read data with new elements in range');
            
            dotsMglDeleteVertexBufferObject(info);
        end
        
        function testOrphaning(self)
            info = dotsMglCreateVertexBufferObject(self.megaData);
            
            newData = rand(size(self.megaData));
            doReallocate = 1;
            nElements = dotsMglWriteToVertexBufferObject( ...
                info, newData, [], doReallocate);
            assertEqual(nElements, numel(newData), ...
                'should write new elements to reallocated mega VBO');
            
            data = dotsMglReadFromVertexBufferObject(info);
            assertEqual(data, newData, ...
                'should read new data from reallocated VBO');
            
            dotsMglDeleteVertexBufferObject(info);
        end
        
        function testDrawing(self)
            
            mglVisualAngleCoordinates(57, [16 12]);
            
            targetIndex = 0;
            usageIndex = 0;
            elementsPerVertex = 2;
            elementStride = 0;
            info = dotsMglCreateVertexBufferObject(5*(self.megaData-0.5), ...
                targetIndex, usageIndex, elementsPerVertex, elementStride);
            
            % select the new object as an array of positions
            nSelected = dotsMglSelectVertexData(info, {'vertex'});
            assertEqual(1, nSelected, ...
                'should select one array of vertex data')
            
            mglClearScreen();
            
            % draw all elements of the selected VBO as points
            pointPrimitive = 0;
            nVertices = info.nElements / info.elementsPerVertex;
            pointSize = 3;
            nVerticesDrawn = dotsMglDrawVertices( ...
                pointPrimitive, nVertices, [], pointSize);
            assertEqual(nVertices, nVerticesDrawn, ...
                'should draw all vertices in selected VBO');
            
            mglFlush();
            % pause();
            mglClearScreen();
            
            % draw a few elements of the selected VBO as triangles
            trianglePrimitive = 6;
            offset = 10;
            nVertices = 9;
            nVerticesDrawn = dotsMglDrawVertices( ...
                trianglePrimitive, nVertices, offset);
            assertEqual(nVertices, nVerticesDrawn, ...
                'should draw range of vertices in selected VBO');
            
            mglFlush();
            %pause();
            
            % disable vertex data selections
            nSelected = dotsMglSelectVertexData();
            assertEqual(0, nSelected, ...
                'should select no more vertex data')
            
            dotsMglDeleteVertexBufferObject(info);
        end
        
        function testInterleavedVertexData(self)
            
            mglVisualAngleCoordinates(57, [16 12]);
            
            % choose float-single data for each vertex data type
            nVertices = 100;
            elementsPerVertex = 3;
            position = 3*rand(elementsPerVertex, nVertices, 'single');
            position(elementsPerVertex:elementsPerVertex:end) = 0;
            color = .1 + .9*rand(elementsPerVertex, nVertices, 'single');
            secondaryColor = color;
            textureCoordinates = zeros(elementsPerVertex, nVertices, 'single');
            normal = ones(elementsPerVertex, nVertices, 'single');
            fogCoordinates = ones(elementsPerVertex, nVertices, 'single');
            
            % create one giant VBO with interleaved vertex data
            interleavedData = [ ...
                position; ...
                color; ...
                secondaryColor; ...
                textureCoordinates; ...
                normal; ...
                fogCoordinates];
            targetIndex = 0;
            usageIndex = 0;
            elementStride = numel(interleavedData)/nVertices;
            interleavedInfo = dotsMglCreateVertexBufferObject( ...
                interleavedData(:), targetIndex, usageIndex, ...
                elementsPerVertex, elementStride);
            assertTrue(isstruct(interleavedInfo), ...
                'should get VBO info struct');
            
            % select the same VBO multiple times
            %   with offsets for each data type
            vertexData = repmat(interleavedInfo, 1, 6);
            dataNames = {'vertex', 'color', 'secondaryColor', ...
                'texCoord', 'normal', 'fogCoord'};
            dataOffsets = elementsPerVertex*(0:(numel(vertexData)-1));
            nSelected = dotsMglSelectVertexData( ...
                vertexData, dataNames, dataOffsets);
            assertEqual(numel(vertexData), nSelected, ...
                'should select multiple vertex data types')
            
            mglClearScreen();
            
            % draw all vertices from the interleaved VBO as points
            pointPrimitive = 0;
            nVerticesDrawn = dotsMglDrawVertices( ...
                pointPrimitive, nVertices);
            assertEqual(nVertices, nVerticesDrawn, ...
                'should draw all vertices in interleaved VBO');
            
            mglFlush();
            %pause();
            
            % disable vertex data selections
            nSelected = dotsMglSelectVertexData();
            assertEqual(0, nSelected, ...
                'should select no more vertex data')
            
            % repeat, but leave out secondary color and fog coordinates
            vertexData = repmat(interleavedInfo, 1, 4);
            dataNames = {'vertex', 'color', 'texCoord', 'normal'};
            dataOffsets = elementsPerVertex*(0:(numel(vertexData)-1));
            nSelected = dotsMglSelectVertexData( ...
                vertexData, dataNames, dataOffsets);
            assertEqual(numel(vertexData), nSelected, ...
                'should select multiple vertex data types')
            
            mglClearScreen();
            
            % draw all vertices from the interleaved VBO as points
            pointPrimitive = 0;
            nVerticesDrawn = dotsMglDrawVertices( ...
                pointPrimitive, nVertices);
            assertEqual(nVertices, nVerticesDrawn, ...
                'should draw all vertices in interleaved VBO');
            
            mglFlush();
            %pause();
            
            % disable vertex data selections
            nSelected = dotsMglSelectVertexData();
            assertEqual(0, nSelected, ...
                'should select no more vertex data')
            
            dotsMglDeleteVertexBufferObject(interleavedInfo);
        end
        
        function testSeparateVertexData(self)
            
            mglVisualAngleCoordinates(57, [16 12]);
            
            % choose float-single data for each vertex data type
            nVertices = 100;
            elementsPerVertex = 3;
            position = 3*rand(elementsPerVertex, nVertices, 'single');
            position(elementsPerVertex:elementsPerVertex:end) = 0;
            color = .1 + .9*rand(elementsPerVertex, nVertices, 'single');
            secondaryColor = color;
            textureCoordinates = zeros(elementsPerVertex, nVertices, 'single');
            normal = ones(elementsPerVertex, nVertices, 'single');
            fogCoordinates = ones(elementsPerVertex, nVertices, 'single');
            
            % create a VBO for each vertex data type
            targetIndex = 0;
            usageIndex = 0;
            positionInfo = dotsMglCreateVertexBufferObject( ...
                position, targetIndex, usageIndex, elementsPerVertex);
            colorInfo = dotsMglCreateVertexBufferObject( ...
                color, targetIndex, usageIndex, elementsPerVertex);
            secondaryColorInfo = dotsMglCreateVertexBufferObject( ...
                secondaryColor, targetIndex, usageIndex, elementsPerVertex);
            textureCoordinatesInfo = dotsMglCreateVertexBufferObject( ...
                textureCoordinates, targetIndex, usageIndex, elementsPerVertex);
            normalInfo = dotsMglCreateVertexBufferObject( ...
                normal, targetIndex, usageIndex, elementsPerVertex);
            fogCoordinatesInfo = dotsMglCreateVertexBufferObject( ...
                fogCoordinates, targetIndex, usageIndex, elementsPerVertex);
            
            % select a different VBO for each data type
            vertexData = [positionInfo, ...
                colorInfo, ...
                secondaryColorInfo, ...
                textureCoordinatesInfo, ...
                normalInfo, ...
                fogCoordinatesInfo];
            dataNames = {'vertex', 'color', 'secondaryColor', ...
                'texCoord', 'normal', 'fogCoord'};
            nSelected = dotsMglSelectVertexData(vertexData, dataNames);
            assertEqual(numel(vertexData), nSelected, ...
                'should select multiple vertex data types')
            
            mglClearScreen();
            
            % draw all vertices from the interleaved VBO as points
            pointPrimitive = 0;
            nVerticesDrawn = dotsMglDrawVertices( ...
                pointPrimitive, nVertices);
            assertEqual(nVertices, nVerticesDrawn, ...
                'should draw all vertices in interleaved VBO');
            
            mglFlush();
            %pause();
            
            % disable vertex data selections
            nSelected = dotsMglSelectVertexData();
            assertEqual(0, nSelected, ...
                'should select no more vertex data')
            
            dotsMglDeleteVertexBufferObject(positionInfo);
            dotsMglDeleteVertexBufferObject(colorInfo);
            dotsMglDeleteVertexBufferObject(secondaryColorInfo);
            dotsMglDeleteVertexBufferObject(textureCoordinatesInfo);
            dotsMglDeleteVertexBufferObject(normalInfo);
            dotsMglDeleteVertexBufferObject(fogCoordinatesInfo);
        end
        
        function testDataTypes(self)
            nTypes = numel(self.types);
            for ii = 1:nTypes
                type = self.types{ii};
                data = rand(1,1)*ones(size(self.megaData), type);
                
                info = dotsMglCreateVertexBufferObject(data);
                readData = dotsMglReadFromVertexBufferObject(info);
                dotsMglDeleteVertexBufferObject(info);
                
                assertEqual(type, class(readData), ...
                    'should read data of original type');
                assertElementsAlmostEqual(double(data), double(readData), ...
                    'should read original data values')
            end
        end
    end
end