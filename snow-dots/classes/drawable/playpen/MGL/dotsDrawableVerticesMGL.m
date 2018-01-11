classdef dotsDrawableVerticesMGL < dotsDrawableVerticesType
    % @class dotsDrawableVerticesMGL
    % Draw OpenGL vertices as arbitrary shapes, using buffer objects via
    % MGL
    %
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableVerticesMGL
            self = self@dotsDrawableVerticesType;            
        end        
        
        % Draw vertices from OpenGL buffer objects.
        function draw(self)
            
            % toggle antialiasing
            dotsMglSmoothness( ...
                self.parent.smoothMap(self.parent.primitive), ...
                double(self.parent.isSmooth));
            dotsMglSmoothness('scene', 1);
            
            % make sure buffers are not stale, and bind them for drawing
            self.parent.updateBuffers();
            self.parent.selectBuffers();
            
            % push into scaling, rotating, and translating transformations
            t = self.parent.translation;
            r = self.parent.rotation;
            s = self.parent.scaling;
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
                self.parent.primitive, self.parent.indexBufferInfo.nElements, ...
                [], self.parent.pixelSize, self.parent.indexBufferInfo);
            
            % pop out of view transformations
            if isTransformed
                mglTransform(matrix, 'glPopMatrix');
            end
            
            % unbind buffers
            self.parent.deselectBuffers();
        end
        
        function deleteAttribBuffer(self, bufferInfo)
            dotsMglDeleteVertexBufferObject(bufferInfo);
        end
        
        function buffer = createAttribBuffer(self, data, target, usageHint, elementsPerVertex)
            buffer = dotsMglCreateVertexBufferObject( ...
                    data, target, usageHint, elementsPerVertex);
        end
            
        function writeToAttribBuffer(self, buffer, data, offsetElements, doReallocate)
            dotsMglWriteToVertexBufferObject( ...
                buffer, data, offsetElements, doReallocate);
        end
        
        function selectVertexData(self, bufferInfo,  dataNames)
            dotsMglSelectVertexData(bufferInfo, dataNames);
        end
    end
end