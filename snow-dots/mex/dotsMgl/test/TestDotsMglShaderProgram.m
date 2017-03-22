classdef TestDotsMglShaderProgram < TestCase
    % Test behavior of Snow Dots shader programs and transform feedback.
    % @details
    % Testing shader behavior isolation would be a little tricky.  The
    % behavior of a shader is hard to test without doing image processing
    % on the pixels that end up in the frame buffer (or a texture).  The
    % results might depend on the specific hardware.  I'm not sure how to
    % do that.  Transform feedback should help because it gives access to
    % vertex shader results before they're rasterized.
    % @details
    % Likewise, testing transform feedback in isolation would be impossible
    % because shader programs are part of the transform feedback setup
    % process.
    % @details
    % So I think we're stuck testing shaders and transform feedback
    % together, as an integration test.  The integration also relies on
    % vertex buffer objects.
    % @details
    % My approach will be to keep the components simple.  A vertex buffer
    % object will contain some vertices with arbitrary x and y data, to be
    % fed to a vertex shader.  The vertex shader will use one scalar
    % uniform variable and copy the scalar to the x and y elements of each
    % vertex.  The shader will be defined in simpleTestShader.vert
    % @details
    % Transform feedback will capture the "transformed" vertices
    % in another vertex buffer object, to be read back to Matlab.  A
    % successful test will show that all the x any y values changed from
    % their original values to the value of the uniform variable.  The test
    % should be repeatable for several uniform variable values.
    % @details
    %
    
    properties
        vertexSource;
        xyzwElements;
        nVertices;
        transformVariableName;
        valueSpan;
    end
    
    methods
        function self = TestDotsMglShaderProgram(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            clear mex
            
            % about 1kB of data
            kilo = 1e3;
            doubleSize = 8;
            nDoubles = kilo/doubleSize;
            self.xyzwElements = 4;
            self.nVertices = ceil(nDoubles/self.xyzwElements);
            
            % the vertex shader lives in a file but its used as a string
            sourceFile = 'simpleTestShader.vert';
            fid = fopen(sourceFile);
            self.vertexSource = fread(fid, '*char')';
            fclose(fid);
            
            % choose a uniform variable name out of simpleTestShader.vert
            self.transformVariableName = 'xyOverwrite';
            
            self.valueSpan = 1000;
            
            mglOpen(0);
        end
        
        function tearDown(self)
            mglClose();
            clear mex
        end
        
        function testUniformTransformFeedback(self)
            % create a shader program with the simple test shader
            programInfo = dotsMglCreateShaderProgram( ...
                self.vertexSource, []);
            assertTrue(isstruct(programInfo), ...
                'should get program info struct');
            assertTrue(programInfo.programID > 0, ...
                'should get positive nonzero program programID');
            
            % activate the shader program
            %   in place of default OpenGL behaviors
            status = dotsMglUseShaderProgram(programInfo);
            assertTrue(status >= 0, 'can not use shader program');
            
            % create buffers for input and output vertex data
            %   gl_Position has x, y, z, and w float elements
            %   so buffers must make room for 4 float elements per vertex
            nElements = self.xyzwElements * self.nVertices;
            blankData = zeros(1, nElements, 'single');
            arrayTargetIndex = 0;
            STREAM_COPY = 2;
            STREAM_READ = 1;
            elementsPerVertex = self.xyzwElements;
            elementStride = 0;
            drawVBOInfo = dotsMglCreateVertexBufferObject(blankData, ...
                arrayTargetIndex, STREAM_COPY, ...
                elementsPerVertex, elementStride);
            assertTrue(isstruct(drawVBOInfo), ...
                'should get info struct for drawing VBO');
            readVBOInfo = dotsMglCreateVertexBufferObject(blankData, ...
                arrayTargetIndex, STREAM_READ, ...
                elementsPerVertex, elementStride);
            assertTrue(isstruct(readVBOInfo), ...
                'should get info struct for reading VBO');
            
            % locate the program variable which will influence transform
            % feedback by overwriting x and y vertex positions
            variableInfo = dotsMglLocateProgramVariable(programInfo, ...
                self.transformVariableName);
            assertTrue(isstruct(variableInfo), ...
                'should get variable info struct');
            
            % enable transform feedback for the 'gl_Position' vertex
            % variable
            nSelected = dotsMglSelectTransformFeedback( ...
                programInfo, readVBOInfo, {'gl_Position'});
            assertEqual(1, nSelected, ...
                'failed to select transform feedback');
            
            % enable drawing of the "draw" buffer
            nSelected = dotsMglSelectVertexData(drawVBOInfo, {'vertex'});
            assertEqual(1, nSelected, ...
                'failed to select vetex data');
            
            % tell the shader to overwrite x and y position with value
            xyOverwrite = rand(1,1);
            nElements = dotsMglSetProgramVariable( ...
                variableInfo, xyOverwrite);
            assertEqual(numel(xyOverwrite), nElements, ...
                'should set program variable');
            
            % draw the "draw" buffer as points and capture
            %   discard rasterization (no graphics will show up)
            points = 0;
            doDiscard = 1;
            status = dotsMglBeginTransformFeedback(points, doDiscard);
            assertTrue(status >= 0, ...
                'error beginning transform feedback');
            nVerticesDrawn = dotsMglDrawVertices(points, self.nVertices);
            assertEqual(self.nVertices, nVerticesDrawn, ...
                'should draw all vertices in VBO');
            
            % let the program finish running
            dotsMglFinish();
            
            % finish with transform feedback
            status = dotsMglEndTransformFeedback();
            assertTrue(status >= 0, ...
                'error ending transform feedback');
            
            % check that the "read" buffer captured overwritten x and y
            % positions
            readData = dotsMglReadFromVertexBufferObject(readVBOInfo);
            assertEqual(size(blankData), size(readData), ...
                'read transform feedback data of wrong size');
            readX = readData(1:elementsPerVertex:end);
            expectedX = xyOverwrite*ones(size(readX), class(readData));
            assertEqual(expectedX, readX, ...
                'shader did not overwrite x position')
            readY = readData(2:elementsPerVertex:end);
            expectedY = xyOverwrite*ones(size(readY), class(readData));
            assertEqual(expectedY, readY, ...
                'shader did not overwrite y position')
            originalZ = blankData(3:elementsPerVertex:end);
            readZ = readData(3:elementsPerVertex:end);
            assertEqual(originalZ, readZ, ...
                'shader did not preserve z position')
            originalW = blankData(4:elementsPerVertex:end);
            readW = readData(4:elementsPerVertex:end);
            assertEqual(originalW, readW, ...
                'shader did not preserve w position')
            
            % stop using the shader program and delete opjects
            status = dotsMglUseShaderProgram();
            assertTrue(status >= 0, 'can not unuse shader program');
            dotsMglDeleteVertexBufferObject(drawVBOInfo);
            dotsMglDeleteVertexBufferObject(readVBOInfo);
            dotsMglDeleteShaderProgram(programInfo);
        end
        
        function testAttributeTransformFeedback(self)
            % create a shader program with the simple test shader
            programInfo = dotsMglCreateShaderProgram( ...
                self.vertexSource, []);
            assertTrue(isstruct(programInfo), ...
                'should get program info struct');
            assertTrue(programInfo.programID > 0, ...
                'should get positive nonzero program programID');
            
            % activate the shader program
            %   in place of default OpenGL behaviors
            status = dotsMglUseShaderProgram(programInfo);
            assertTrue(status >= 0, 'can not use shader program');
            
            % create a buffer of boring vertex positions
            %   assign it as position vertex data
            elementsPerVertex = 4;
            positionData = zeros(elementsPerVertex, self.nVertices, 'single');
            positionVBOInfo = dotsMglCreateVertexBufferObject( ...
                positionData, [], [], elementsPerVertex);
            nBuffers = dotsMglSelectVertexData( ...
                positionVBOInfo, {'vertex'});
            assertEqual(1, nBuffers, 'should assign one position VBO');
            
            % create a buffer of arbitrary input attribute data
            %   assign it to the named "inputAttribute" variable
            %   which requires insider knowledge of the vertex shader
            attribData = rand(elementsPerVertex, self.nVertices, 'single');
            attribVBOInfo = dotsMglCreateVertexBufferObject( ...
                attribData, [], [], elementsPerVertex);
            nBuffers = dotsMglSelectVertexAttributes(programInfo, ...
                attribVBOInfo, {'inputAttribute'});
            assertEqual(1, nBuffers, 'should assign one attribute VBO');
            
            % create a buffer which will receive transform feedback data
            %   assign it to capture the named "outputVarying" variable
            %   which requires insider knowledge of the vertex shader
            varyingData = zeros(elementsPerVertex, self.nVertices, 'single');
            varyingVBOInfo = dotsMglCreateVertexBufferObject( ...
                varyingData, [], [], elementsPerVertex);
            nSelected = dotsMglSelectTransformFeedback( ...
                programInfo, varyingVBOInfo, {'outputVarying'});
            assertEqual(1, nSelected, ...
                'failed to select transform feedback');
            
            % draw the position buffer as points and capture output
            points = 0;
            status = dotsMglBeginTransformFeedback(points);
            assertTrue(status >= 0, ...
                'could not begin transform feedback');
            dotsMglFinish();
            nVerticesDrawn = dotsMglDrawVertices(points, self.nVertices);
            dotsMglFinish();
            assertEqual(self.nVertices, nVerticesDrawn, ...
                'should draw all vertices in position VBO');
            dotsMglEndTransformFeedback();
            dotsMglFinish();
            
            % the "varying" VBO should have received the contents of the
            % original attribute data, via the "attribute" VBO
            readAttrib = dotsMglReadFromVertexBufferObject(attribVBOInfo);
            assertEqual(attribData(:)', readAttrib, ...
                'read incorrect attribute data');
            readVarying = dotsMglReadFromVertexBufferObject(varyingVBOInfo);
            assertEqual(readAttrib, readVarying, ...
                'varying VBO did not receive attribute data');
            
            % clean up this mess
            dotsMglUseShaderProgram();
            dotsMglSelectVertexData();
            dotsMglSelectVertexAttributes();
            dotsMglDeleteVertexBufferObject(positionVBOInfo);
            dotsMglDeleteVertexBufferObject(attribVBOInfo);
            dotsMglDeleteVertexBufferObject(varyingVBOInfo);
            dotsMglDeleteShaderProgram(programInfo);
        end
        
        function testGetSetVariable(self)
            % create a shader program with the simple test shader
            programInfo = dotsMglCreateShaderProgram( ...
                self.vertexSource, []);
            assertTrue(isstruct(programInfo), ...
                'should get program info struct');
            assertTrue(programInfo.programID > 0, ...
                'should get positive nonzero program programID');
            
            % activate the shader program
            %   in place of default OpenGL behaviors
            status = dotsMglUseShaderProgram(programInfo);
            assertTrue(status >= 0, 'can not use shader program');
            
            % locate all variables
            %   locate each one again individually, by name
            %   set and get the value of each one
            variableInfo = dotsMglLocateProgramVariable(programInfo);
            assertTrue(isstruct(variableInfo), ...
                'should get variable info struct');
            assertTrue(numel(variableInfo) > 1, ...
                'should get variable info struct array');
            n = numel(variableInfo);
            for ii = 1:n
                var = variableInfo(ii);
                
                % locate one variable by name
                singleVar = dotsMglLocateProgramVariable( ...
                    programInfo, var.name);
                assertTrue(isstruct(singleVar), ...
                    'should locate single-variable by name');
                assertEqual(numel(singleVar), 1, ...
                    'should locate single-variable scalar info struct');
                assertEqual(var.name, singleVar.name, ...
                    'should locate varible with given name');
                assertTrue(singleVar.location >= 0, ...
                    'single-variable should have nonnegative location');
                
                % make a variable value to set and get
                %   match size from variableInfo meta-data
                %   try to match precision by naming convention
                inValue = self.valueSpan ...
                    *(rand(var.elementRows, var.elementCols)-0.5);
                if strncmp('b', var.name, 1)
                    inValue = double(inValue > 0);
                else
                    inValue = double(single(inValue));
                end
                
                % check that correct number of elements were set
                nElements = dotsMglSetProgramVariable(var, inValue);
                assertEqual(nElements, numel(inValue), ...
                    sprintf('could not set value for %s', var.name));
                
                outValue = dotsMglGetProgramVariable(var);
                assertElementsAlmostEqual(inValue, outValue, ...
                    sprintf('set-get value mismatch for %s', var.name))
            end
            
            % stop using the shader program and delete it
            status = dotsMglUseShaderProgram([]);
            assertTrue(status >= 0, 'can not unuse shader program');
            dotsMglDeleteShaderProgram(programInfo);
        end
    end
end