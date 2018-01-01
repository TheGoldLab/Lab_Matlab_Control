classdef dotsDrawableVerticesType < handle
    % @class dotsDrawableVerticesType
    %
    % Class for defining the interface of the screen object
    %   helper functions in dotsThScreen

    properties
        % keep track of parent
        parent = [];        
    end
    
    methods (Abstract)        
        draw(self);
        deleteAttribBuffer(self, bufferInfo);
        buffer = createAttribBuffer(self, data, target, usageHint, elementsPerVertex);
        writeToAttribBuffer(self, buffer, data, offsetElements, doReallocate);
        selectVertexData(self, bufferInfo,  dataNames);
    end
end