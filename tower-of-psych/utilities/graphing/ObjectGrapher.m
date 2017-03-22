classdef ObjectGrapher < handle
    % @class ObjectGrapher
    % Graphs references among objects with the Graphviz tool.
    % @ details
    % ObjectGrapher follows refrences among objects and keeps track of
    % unique objects and how they refer to one another.  It confugures a
    % DataGrapher to graph which objects refer to which.
    
    properties
        % containers.Map of objects, where to start looking for object
        % references
        seedObjects;
        
        % containers.Map of unique objects found while following
        % references
        uniqueObjects;
        
        % maximum number of references to follow from before stopping (to
        % avoid recursion among non-handle objects)
        maxElementDepth = 20;
        
        % cell array of strings of class names of objects to ignore
        ignoredClasses = {};
        
        % a DataGrapher object for graphing the objects
        dataGrapher;
        
        % struct of object and reference data to graph
        objectInfo;
        
        % index into uniqueObjects of the last object found
        currentIndex;
    end
    
    methods
        % Constructor takes no arguments.
        function self = ObjectGrapher
            self.initializeUniques;
            
            self.seedObjects = containers.Map(-1, -1, 'uniformValues', false);
            self.seedObjects.remove(self.seedObjects.keys);
            
            self.dataGrapher = DataGrapher;
            self.dataGrapher.workingFileName = 'objectGraph';
            self.dataGrapher.floatingEdgeNames = false;
            
            self.dataGrapher.nodeNameFunction = ...
                @ObjectGrapher.classNameWithLetter;
            
            self.dataGrapher.edgeFunction = ...
                @ObjectGrapher.edgeFromReferences;
        end
        
        % Clear the list of unique objects.
        function initializeUniques(self)
            self.uniqueObjects = containers.Map(-1, -1, 'uniformValues', false);
            self.uniqueObjects.remove(self.uniqueObjects.keys);
        end
        
        % Use the given object to start looking for object references.
        function addSeedObject(self, object)
            n = self.seedObjects.length + 1;
            self.seedObjects(n) = object;
        end
        
        % Append a new object to the list of unique objects.
        function n = addUniqueObject(self, object)
            n = self.uniqueObjects.length + 1;
            self.uniqueObjects(n) = object;
        end
        
        % Determine whether the given object has already been encountered.
        function [contains, index] = containsUniqueObject(self, object)
            contains = false;
            index = [];
            if ~isempty(object)
                objects = self.uniqueObjects.values;
                for ii = 1:length(objects)
                    if isa(object, 'handle')
                        contains = object==objects{ii};
                    else
                        contains = isequal(object, objects{ii});
                    end
                    
                    if contains
                        if nargout > 1
                            keys = self.uniqueObjects.keys;
                            index = keys{ii};
                        end
                        return
                    end
                end
            end
        end
        
        % Look for unique objects, starting with seedObjects.
        function crawlForUniqueObjects(self)
            self.initializeUniques;
            scanFun = @(object, depth, refPath, objFcn)self.scanObject(object, depth, refPath, objFcn);
            seeds = self.seedObjects.values;
            for ii = 1:length(seeds)
                self.iterateElements(seeds{ii}, self.maxElementDepth, {}, scanFun);
            end
        end
        
        % Determine whether the given object is unique.
        function scanObject(self, object, depth, refPath, objFcn)
            % detect objectness and uniqueness
            %   drill through objects like they're structs
            if ~any(strcmp(class(object), self.ignoredClasses))
                if isa(object, 'handle')
                    
                    if self.containsUniqueObject(object)
                        % base case: already scanned this oject
                        return
                        
                    else
                        % recur: iterate arbitrary handle object's elements
                        self.addUniqueObject(object);
                        structObj = ObjectGrapher.objectToStruct(object);
                        self.iterateElements(structObj, self.maxElementDepth, refPath, objFcn);
                        
                    end
                else
                    % recur: iterate arbitrary value object's elements
                    %   "value" objects are unique by definition
                    %   but limit recursion on them
                    self.addUniqueObject(object);
                    structObj = ObjectGrapher.objectToStruct(object);
                    self.iterateElements(structObj, depth-1, refPath, objFcn);
                end
            end
        end
        
        % Locate graph edges based on object references.
        function traceLinksForEdges(self)
            self.crawlForUniqueObjects;
            
            traceFun = @(object, depth, refPath, objFcn)self.recordEdge(object, depth, refPath, objFcn);
            k = self.uniqueObjects.keys;
            indexes = [k{:}];
            uniques = self.uniqueObjects.values;
            
            self.objectInfo = struct('class', {}, 'references', {});
            for ii = indexes
                self.currentIndex = ii;
                self.objectInfo(ii).class = class(uniques{ii});
                self.objectInfo(ii).references = struct('path', {}, 'target', {});
                structObj = ObjectGrapher.objectToStruct(uniques{ii});
                self.iterateElements(structObj, self.maxElementDepth, {}, traceFun);
            end
            
            self.dataGrapher.inputData = self.objectInfo;
        end
        
        % Store a graph edge between two objects.
        function recordEdge(self, object, depth, refPath, objFcn)
            % record edge from current object to this object
            if isobject(object)
                [contains, index] = self.containsUniqueObject(object);
                if contains
                    ref.path = refPath;
                    ref.target = index;
                    self.objectInfo(self.currentIndex).references(end+1) = ref;
                end
            end
        end
        
        % Folow references from one object to other objects.
        function iterateElements(self, object, depth, refPath, objFcn)
            % Iterate elements of complex types to find objects.
            % Keep track of path through nested types to reach object
            % Execute some function upon reaching object:
            %   - feval(objFcn, object, depth, refPath, objFcn)
            %   - e.g. add to unique object list
            %   - e.g. follow references from each unique object
            if depth <= 0
                % base case: maxed out on recursion of non-handles
                return
            end
            
            if iscell(object)
                % will recur through cell elements
                elements = object;
                paths = num2cell(1:numel(elements));
                format = '\\{%d\\}';
                
            elseif isa(object, 'containers.Map')
                % will recur through map contents
                %   treating map like its not an object
                elements = object.values;
                paths = object.keys;
                if strcmp(object.KeyType, 'char')
                    format = '(''%s'')';
                else
                    format = '(%f)';
                end
                
            elseif numel(object) > 1
                
                if isstruct(object) || isobject(object)
                    % will recur through array elements
                    elements = cell(1, numel(object));
                    paths = num2cell(1:numel(elements));
                    for ii = 1:numel(elements)
                        elements{ii} = object(ii);
                    end
                    format = '(%d)';
                    
                else
                    % base case: primitive array, don't care about it
                    return
                end
                
            elseif isscalar(object)
                
                if isstruct(object)
                    % will recur through struct fields
                    elements = struct2cell(object);
                    paths = fieldnames(object);
                    format = '.%s';
                    
                elseif isobject(object)
                    % base case: found a real object
                    feval(objFcn, object, depth, refPath, objFcn);
                    return
                    
                else
                    % base case: primitive scalar, don't care about it
                    return
                end
                
            else
                % base case: something unexpected, don't care about it
                return
            end
            
            % recur: iterate elements with formatted refPath
            for jj = 1:numel(elements)
                elementPath = cell(1, length(refPath)+1);
                elementPath(1:end-1) = refPath;
                elementPath{end} = sprintf(format, paths{jj});
                self.iterateElements(elements{jj}, depth-1, elementPath, objFcn);
            end
        end
        
        % Write a GraphViz ".dot" file which represents object references.
        function writeDotFile(self)
            self.dataGrapher.writeDotFile;
        end
        
        % Generate an image based on the GraphViz ".dot" file.
        function generateGraph(self)
            self.dataGrapher.generateGraph;
        end
    end
    
    methods (Static)
        % Make a name for an object based on its class name an a "serial
        % letter".
        function nodeName = classNameWithLetter(inputData, index)
            id = inputData(index);
            letters = char(sprintf('%d', index) - '0' + 'a');
            nodeName = sprintf('%s (%s)', id.class, letters);
        end
        
        % Get graph edges based on an object and its references to other
        % obects.
        function [edgeIndexes, edgeNames] = edgeFromReferences(inputData, index)
            id = inputData(index);
            edgeIndexes = [];
            edgeNames = {};
            for ii = 1:length(id.references)
                edgeIndexes(ii) = id.references(ii).target;
                edgeNames{ii} = sprintf('%s', id.references(ii).path{:});
            end
        end
        
        % Put the public properties of the given object into a struct.
        function structObj = objectToStruct(object)
            props = properties(object);
            vals = cell(size(props));
            for ii = 1:numel(props)
                vals{ii} = object.(props{ii});
            end
            structObj = cell2struct(vals, props);
        end
    end
end