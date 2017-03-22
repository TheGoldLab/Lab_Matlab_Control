classdef dotsDrawableVertices < dotsDrawable
    % @class dotsDrawableVertices
    % Draw OpenGL vertices as arbitrary shapes, using buffer objects.
    % @details
    % dotsDrawableVertices creates and maintains OpenGL buffer objects
    % which can store vertex data.  The vertex data can be used to draw
    % OpenGL graphics primitives including points, lines, and polygons.
    % Each vertex may have its own color.  Primitives can be scaled,
    % rotated, and translated using OpenGL functionality.
    properties
        % vertex x-positions (x, y, and z must be scalar or match sizes)
        x = 0;
        
        % vertex y-positions (x, y, and z must be scalar or match sizes)
        y = 0;
        
        % vertex z-positions (x, y, and z must be scalar or match sizes)
        z = 0;
        
        % color map to use for vertices [r g b a; r g b a; etc.]
        % @details
        % Each vertex takes its color from one of the rows of colors.
        % The number of vertices and the number of rows may differ: if
        % there are more vertices than rows, rows are reused in wrapping
        % fashion.  If there are more rows than vertices, only the first
        % rows are used.
        colors = [1 1 1];
        
        % whether to color vertices in groups(true) or individually(false)
        isColorByVertexGroup = false;
        
        % array of indices for selecting, reusing, and reordering vertices
        % @details
        % If indices is empty, vertices are drawn sequentially from
        % elements of x, y, and z.  If supplied, vertices are drawn from
        % indexed elements of x, y, and z.  This allows arbitrary
        % selection, reuse, and reordering of vertices without changing the
        % underlying buffer objects.
        % @details
        % The indices are interpreted as 1-based.  The number of indices
        % and the number of vertices may differ.  The largest index may not
        % exceed the number of vertices.
        indices = [];
        
        % width in pixels for points or lines
        pixelSize = 1;
        
        % whether to use anti-aliasing for primitives
        isSmooth = false;
        
        % index to choose OpenGL vertex drawing mode
        % @details
        % primitive must be one of the following:
        %   0   GL_POINTS
        %   1   GL_LINE_STRIP
        %   2   GL_LINE_LOOP
        %   3   GL_LINES
        %   4   GL_TRIANGLE_STRIP
        %   5   GL_TRIANGLE_FAN
        %   6   GL_TRIANGLES
        %   7   GL_QUAD_STRIP
        %   8   GL_QUADS
        %   9   GL_POLYGON
        primitive = 0;
        
        % index to choose usage "hint" for OpenGL buffers
        % @details
        % usageHint must be one of the following:
        %   0   GL_STREAM_DRAW
        %   1   GL_STREAM_READ
        %   2   GL_STREAM_COPY
        %   3   GL_STATIC_DRAW
        %   4   GL_STATIC_READ
        %   5   GL_STATIC_COPY
        %   6   GL_DYNAMIC_DRAW
        %   7   GL_DYNAMIC_READ
        %   8   GL_DYNAMIC_COPY
        usageHint = 3;
        
        % optional translation to apply to vertex positions [tX tY tZ]
        % @details
        % If supplied, vertex x, y, and z positions will be shifted by
        % offsets tX, tY, and tZ.  Translation will be applied before
        % rotation and scaling.
        translation = [];
        
        % optional rotation of vertices about coordinate axes [rX rY rZ]
        % @details
        % If supplied, vertices will be rotated through rX, rY, and rZ
        % degrees (right-handed/counterclockwise) about each coordinate
        % axis, in that order.  Rotation will be applied after translation
        % and before scaling.
        rotation = [];
        
        % optional scaling to apply to vertex positions [sX sY sZ]
        % @details
        % If supplied, vertex x, y, and z positions will be scaled by
        % factors sX, sY, and sZ.  Scaling will be applied after
        % translation and rotation.
        scaling = [];
    end
    
    
    properties (SetAccess = protected)
        % identifier and other info for the OpenGL vertex attribute buffer
        attribBufferInfo = [];
        
        % whether or not the attribute buffer is out of date
        isAttribBufferStale = true;
        
        % identifier and other info for the OpenGL vertex index buffer
        indexBufferInfo = [];
        
        % whether or not the index buffer is out of date
        isIndexBufferStale = true;
        
        % identifier and other info for the OpenGL vertex color buffer
        colorBufferInfo = [];
        
        % whether or not the color buffer is out of date
        isColorBufferStale = true;
        
        % map primitive integers to dotsMglSmoothness() switches
        smoothMap;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableVertices
            self = self@dotsDrawable;
            
            keys = 0:9;
            values = cell(size(keys));
            [values{1}] = deal('points');
            [values{2:4}] = deal('lines');
            [values{5:end}] = deal('polygons');
            self.smoothMap = containers.Map(num2cell(keys), values);
        end
        
        % Release OpenGL resources.
        % @details
        % Matlab calls delete() automatically when it's done using the
        % object.
        function delete(self)
            self.deleteBuffers();
        end
        
        % Keep track of required buffer updates.
        function set.x(self, x)
            if ~isequal(self.x, x);
                % nVertices changed
                self.flagAllBuffersAsStale();
            end
            self.x = x;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.y(self, y)
            if ~isequal(self.y, y);
                % nVertices changed
                self.flagAllBuffersAsStale();
            end
            self.y = y;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.z(self, z)
            if ~isequal(self.z, z);
                % nVertices changed
                self.flagAllBuffersAsStale();
            end
            self.z = z;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.indices(self, indices)
            self.indices = indices;
            self.isIndexBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.colors(self, colors)
            self.colors = colors;
            self.isColorBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.isColorByVertexGroup(self, isColorByVertexGroup)
            self.isColorByVertexGroup = isColorByVertexGroup;
            self.isColorBufferStale = true;
        end
        
        % Calculate number of vertices from x, y, and z.
        function nVertices = getNVertices(self)
            nVertices = max([numel(self.x), numel(self.y) numel(self.z)]);
        end
        
        % Create fresh OpenGL buffer objects.
        function prepareToDrawInWindow(self)
            self.deleteBuffers();
            self.updateBuffers();
        end
        
        % Draw vertices from OpenGL buffer objects.
        function draw(self)
            % toggle antialiasing
            dotsMglSmoothness( ...
                self.smoothMap(self.primitive), double(self.isSmooth));
            dotsMglSmoothness('scene', 1);
            
            % make sure buffers are not stale, and bind them for drawing
            self.updateBuffers();
            self.selectBuffers();
            
            % push into scaling, rotating, and translating transformations
            t = self.translation;
            r = self.rotation;
            s = self.scaling;
            isTransformed = ~isempty(t) || ~isempty(r) || ~isempty(s);
            if isTransformed
                matrix = 'GL_MODELVIEW';
                mglTransform(matrix, 'glPushMatrix');
                
                if ~isempty(t)
                    mglTransform(matrix, 'glTranslate', t(1), t(2), t(3));
                end
                
                if ~isempty(r)
                    mglTransform(matrix, 'glRotate', r(1), 1, 0, 0);
                    mglTransform(matrix, 'glRotate', r(2), 0, 1, 0);
                    mglTransform(matrix, 'glRotate', r(3), 0, 0, 1);
                end
                
                if ~isempty(s)
                    mglTransform(matrix, 'glScale', s(1), s(2), s(3));
                end
            end
            
            % draw indexed vertices
            dotsMglDrawVertices( ...
                self.primitive, self.indexBufferInfo.nElements, ...
                [], self.pixelSize, self.indexBufferInfo);
            
            % pop out of view transformations
            if isTransformed
                mglTransform(matrix, 'glPopMatrix');
            end
            
            % unbind buffers
            self.deselectBuffers();
        end
    end
    
    methods (Access = protected)
        % Release OpenGL buffer handles and memory.
        function deleteBuffers(self)
            self.deleteAttribBuffer();
            self.deleteIndexBuffer();
            self.deleteColorBuffer();
        end
        
        % Write attribute, color, and index data to buffers, as needed.
        function updateBuffers(self)
            if self.isAttribBufferStale
                self.updateAttribBuffer();
            end
            
            if self.isIndexBufferStale
                self.updateIndexBuffer();
            end
            
            if self.isColorBufferStale
                self.updateColorBuffer();
            end
        end
        
        % Release OpenGL vertex attribute resources.
        function deleteAttribBuffer(self)
            if ~isempty(self.attribBufferInfo)
                dotsMglDeleteVertexBufferObject(self.attribBufferInfo);
            end
            self.attribBufferInfo = [];
            self.isAttribBufferStale = true;
        end
        
        % Write new vertex attributes to OpenGL buffer(s).
        function updateAttribBuffer(self)
            % pack x, y, and z into a float matrix
            nVertices = self.getNVertices();
            xyz = zeros(3, nVertices, 'single');
            xyz(1,:) = self.x;
            xyz(2,:) = self.y;
            xyz(3,:) = self.z;
            
            target = 0;
            elementsPerVertex = 3;
            self.attribBufferInfo = self.overwriteOrReplaceBuffer( ...
                self.attribBufferInfo, xyz, target, elementsPerVertex);
            
            self.isAttribBufferStale = false;
        end
        
        % Release OpenGL vertex index resources.
        function deleteIndexBuffer(self)
            if ~isempty(self.indexBufferInfo)
                dotsMglDeleteVertexBufferObject(self.indexBufferInfo);
            end
            self.indexBufferInfo = [];
            self.isIndexBufferStale = true;
        end
        
        % Write new vertex indices to OpenGL buffer(s).
        function updateIndexBuffer(self)
            % use assigned indices, or default to sequential
            if isempty(self.indices)
                nVertices = self.getNVertices();
                inds = 0:(nVertices-1);
            else
                inds = self.indices;
            end
            
            % pack indices into int data type
            if max(inds) <= intmax('uint16')
                inds = uint16(inds);
            else
                inds = uint32(inds);
            end
            
            target = 1;
            elementsPerVertex = 1;
            self.indexBufferInfo = self.overwriteOrReplaceBuffer( ...
                self.indexBufferInfo, inds, target, elementsPerVertex);
            
            self.isIndexBufferStale = false;
        end
        
        % Release OpenGL vertex color resources.
        function deleteColorBuffer(self)
            if ~isempty(self.colorBufferInfo)
                dotsMglDeleteVertexBufferObject(self.colorBufferInfo);
            end
            self.colorBufferInfo = [];
            self.isColorBufferStale = true;
        end
        
        % Write new vertex colors to OpenGL buffer(s).
        function updateColorBuffer(self)
            % pack color rows into a float matrix
            nComponents = size(self.colors, 2);
            nRows = size(self.colors, 1);
            nVertices = self.getNVertices();
            if self.isColorByVertexGroup
                grouping = self.getVertexGroupIndices();
            else
                grouping = 1:nVertices;
            end
            rows = 1 + mod(grouping-1, nRows);
            cols = zeros(nComponents, nVertices, 'single');
            cols(1:nComponents,:) = self.colors(rows, :)';
            
            target = 0;
            self.colorBufferInfo = self.overwriteOrReplaceBuffer( ...
                self.colorBufferInfo, cols, target, nComponents);
            
            self.isColorBufferStale = false;
        end
        
        % Get an arbitrary 1-based group index for each vertex.
        function groupIndices = getVertexGroupIndices(self)
            nVertices = self.getNVertices();
            groupIndices = ones(1, nVertices);
        end
        
        % Modify or replace a buffer with new data.
        function buffer = overwriteOrReplaceBuffer( ...
                self, oldBuffer, data, target, elementsPerVertex)
            
            if isempty(oldBuffer) || numel(data) ~= oldBuffer.nElements
                % need to create a new buffer
                if isstruct(oldBuffer)
                    dotsMglDeleteVertexBufferObject(oldBuffer);
                end
                buffer = dotsMglCreateVertexBufferObject( ...
                    data, target, self.usageHint, elementsPerVertex);
                
            else
                % only need to replace data in the buffer
                %   use doReallocate to encourage parallelism
                doReallocate = true;
                dotsMglWriteToVertexBufferObject( ...
                    oldBuffer, data, [], doReallocate);
                buffer = oldBuffer;
            end
        end
        
        % Bind buffers for drawing.
        function selectBuffers(self)
            dotsMglSelectVertexData( ...
                [self.attribBufferInfo, self.colorBufferInfo], ...
                {'vertex', 'color'});
        end
        
        % Unbind buffers for drawing.
        function deselectBuffers(self)
            dotsMglSelectVertexData();
        end
        
        % Mark all OpenGL buffers as stale.
        function flagAllBuffersAsStale(self)
            self.isAttribBufferStale = true;
            self.isIndexBufferStale = true;
            self.isColorBufferStale = true;
        end
    end
end