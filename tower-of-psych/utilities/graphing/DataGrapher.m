classdef DataGrapher < handle
    % @class DataGrapher
    % A Matlab interface for the GraphViz graphing tool.
    % @details
    % DataGrapher uses the GraphViz graphing tool to generate nice-looking
    % graphs of arbitrary data.  The input data are a Matlab struct array,
    % each element of which defines a node to be plotted.  User-supplied
    % functions generate a name for each node as well as "edges" that
    % connect nodes.  Properties of DataGrapher control the general
    % behavior of GraphViz.
    
    properties
        % file path to the GraphViz executables, like "dot" and "neato"
        graphVizPath = '/usr/local/bin';
        
        % GraphViz algorithm name, "dot", "neato", "twopi", "circo", or
        % "fdp"
        graphVisAlgorithm = 'dot';
        
        % file path to put GraphViz data and image files
        workingPath = '~/Desktop/datagraph';
        
        % file name base for GraphViz output files
        workingFileName = 'dataGraph';
        
        % file extension for GraphViz output image files
        imageType = 'png';
        
        % struct array containing node data
        % The graph will contain one node per element of inputData.
        inputData;
        
        % string name for the graph
        graphName = 'dataGraph';
        
        % function to generate graph node names
        % Should take inputData and an index into inputData and return a
        % string name for the indexth node.
        nodeNameFunction = @DataGrapher.nodeNameFromField;
        
        % function to generate graph node descriptions (optional)
        % Should take inputData and an index into inputData and return a
        % cell array of strings describing the indexth node.
        nodeDescriptionFunction;
        
        % function to generate graph edges
        % Should take inputData and an index into inputData and return an
        % array of other indexes.  These specify edges from the given
        % indexth node to the returned indexth nodes.  Should also return
        % as a second output a cell array with a string name for each edge.
        edgeFunction = @DataGrapher.edgeFromField;
        
        % Matlab colormap for coloring in each node its edges
        colors = spacedColors(10);
        
        % true or false, whether the graph should be a directed "digraph"
        % or an undirected "graph"
        graphIsDirected = true;
        
        % true or false whether to write edge names on the edges
        % themselves.
        floatingEdgeNames = true;
        
        % true or false whether to list edge names inside their originating
        % nodes.
        listedEdgeNames = true;
        
        % arbitrary struct of GraphViz properties to apply to the graph
        % itself
        graphProperties;
        
        % arbitrary struct of GraphViz properties to apply to all nodes
        nodeProperties;
        
        % arbitrary struct of GraphViz properties to apply to all edges
        edgeProperties;
        
        % 0-255 opacity for nodes
        nodeAlpha = 1;
        
        % 0-255 opacity for edges
        edgeAlpha = .5;
        
        % internal accounting of node and edge data
        nodes;
    end
    
    methods
        % Constructor takes no arguments.
        function self = DataGrapher()
            self.graphProperties = struct( ...
                'splines', true, ...
                'overlap', 'scale');
            
            self.nodeProperties = struct( ...
                'shape', 'record', ...
                'fontname', 'FreeSans', ...
                'fontsize', 12);
            
            self.edgeProperties = struct( ...
                'fontsize', 10, ...
                'fontname', 'FreeSans');
        end
        
        % Apply nodeNameFunction and edgeFunction to the inputData.
        function nodes = parseNodes(self)
            nodeNameFun = self.nodeNameFunction;
            descriptFun = self.nodeDescriptionFunction;
            edgeFun = self.edgeFunction;
            
            data = self.inputData;
            
            for ii = 1:length(self.inputData)
                nodeName = feval(nodeNameFun, data, ii);
                nodes(ii).name = nodeName;
                nodes(ii).var = nodeName(isstrprop(nodeName, 'alpha'));
                
                if isempty(descriptFun)
                    nodes(ii).description = {};
                else
                    nodes(ii).description = feval(descriptFun, data, ii);
                end
                
                [edgeTargets, edgeNames] = feval(edgeFun, data, ii);
                for jj = 1:length(edgeTargets)
                    nodes(ii).edges(jj).target = edgeTargets(jj);
                    nodes(ii).edges(jj).name = edgeNames{jj};
                end
            end
            self.nodes = nodes;
        end
        
        % Write a string that contains a whole GraphVis specification.
        function string = composeGraph(self)
            self.parseNodes;
            
            if self.graphIsDirected
                graphType = 'digraph';
            else
                graphType = 'graph';
            end
            graphHead = self.composeGraphHeader;
            nodeHead = self.composeNodeHeader;
            edgeHead = self.composeEdgeHeader;
            nodesWriteout = self.composeNodes;
            edgesWriteout = self.composeEdges;
            
            string = ...
                sprintf('%s %s {\n%s\n%s\n\n%s\n\n\n%s\n\n%s\n}\n', ...
                graphType, self.graphName, ...
                graphHead, nodeHead, edgeHead, ...
                nodesWriteout, edgesWriteout);
        end
        
        % Write a string that contains graph properties.
        function string = composeGraphHeader(self)
            string = self.composeProperties(self.graphProperties, ...
                sprintf('\n'));
        end
        
        % Write a string that contains default node properties.
        function string = composeNodeHeader(self)
            propsString = self.composeProperties(self.nodeProperties, ' ');
            string = sprintf('node [%s]', propsString);
        end
        
        % Write a string that contains default edge properties.
        function string = composeEdgeHeader(self)
            propsString = self.composeProperties(self.edgeProperties, ' ');
            string = sprintf('edge [%s]', propsString);
        end
        
        % Write a string that specifies nodes.
        function string = composeNodes(self)
            nColors = size(self.colors, 1);
            for ii = 1:length(self.nodes)
                node = self.nodes(ii);
                
                % skip nameless nodes
                if isempty(node.name)
                    continue
                end
                
                cc = 1 + mod(ii, nColors);
                nodeColor = self.composeRGB( ...
                    self.colors(cc,:), self.nodeAlpha);
                
                list = node.description;
                if self.listedEdgeNames
                    for jj = 1:length(node.edges)
                        edge = node.edges(jj);
                        targetNode = self.nodes(edge.target);
                        if isempty(targetNode.name)
                            continue
                        end
                        list{end+1} = sprintf('<%d>%s', ...
                            jj, edge.name);
                    end
                end
                
                if isempty(list)
                    nodeList = '';
                else
                    nodeList = sprintf('|%s', list{:});
                end
                nodeLabel = sprintf('{{<top>|<name>%s}%s}', ...
                    node.name, nodeList);
                
                nodeString{ii} = sprintf('%s [label="%s" color="%s"]', ...
                    node.var, nodeLabel, nodeColor);
            end
            string = sprintf('%s\n', nodeString{:});
        end
        
        % Write a string that specifies edges.
        function string = composeEdges(self)
            nColors = size(self.colors, 1);
            if self.graphIsDirected
                edgeType = '->';
            else
                edgeType = '--';
            end
            
            edgeString = {};
            for ii = 1:length(self.nodes)
                node = self.nodes(ii);
                
                cc = 1 + mod(ii, nColors);
                edgeColor = self.composeRGB( ...
                    self.colors(cc,:), self.edgeAlpha);
                edgeFontColor = self.composeRGB( ...
                    self.colors(cc,:), 1);
                
                for jj = 1:length(node.edges)
                    edge = node.edges(jj);
                    targetNode = self.nodes(edge.target);
                    
                    % skip nameless target nodes
                    if isempty(node.name) || isempty(targetNode.name)
                        continue
                    end
                    
                    if self.floatingEdgeNames
                        edgeLabel = edge.name;
                    else
                        edgeLabel = '';
                    end
                    
                    if self.listedEdgeNames
                        source = sprintf('%s:%d', node.var, jj);
                    else
                        source = sprintf('%s:name', node.var);
                    end
                    edgeString{end+1} = ...
                        sprintf('%s%s%s:%s [label="%s" color="%s" fontcolor="%s"]', ...
                        source, edgeType, targetNode.var, 'top', ...
                        edgeLabel, edgeColor, edgeFontColor);
                end
            end
            string = sprintf('%s\n', edgeString{:});
        end
        
        % Write a GraphViz specification to file.
        function writeDotFile(self)
            disp('Writing .dot file...')
            dotString = self.composeGraph;
            originalDir = pwd;
            try
                if ~exist(self.workingPath)
                    mkdir(self.workingPath);
                end
                cd(self.workingPath);
                
                fileName = sprintf('%s.dot', self.workingFileName);
                fid = fopen(fileName, 'w');
                if fid >= 0
                    fwrite(fid, dotString);
                    fclose(fid);
                end
            catch err
                cd(originalDir);
                rethrow(err);
            end
            cd(originalDir);
            disp('...done.')
        end
        
        % Feed the GraphViz specification to GraphViz and get a graph.
        function generateGraph(self)
            disp('Generating graph...')
            originalDir = pwd;
            try
                if ~exist(self.workingPath)
                    mkdir(self.workingPath);
                end
                cd(self.workingPath);
                
                dotFile = sprintf('%s.dot', self.workingFileName);
                imageFile = sprintf('%s.%s', self.workingFileName, self.imageType);
                binary = fullfile(self.graphVizPath, self.graphVisAlgorithm);
                command = sprintf('%s -T%s -o %s %s', ...
                    binary, self.imageType, imageFile, dotFile);
                system(command);
                
            catch err
                cd(originalDir);
                rethrow(err);
            end
            cd(originalDir);
            disp('...done.')
        end
        
        % Write out property-value pairs from a struct.
        function string = composeProperties(self, propStruct, delimiter)
            string = '';
            props = fieldnames(propStruct);
            for ii = 1:length(props)
                value = propStruct.(props{ii});
                if isnumeric(value)
                    value = num2str(value);
                elseif islogical(value)
                    if value
                        value = 'true';
                    else
                        value = 'false';
                    end
                end
                string = cat(2, string, sprintf('%s="%s"%s', ...
                    props{ii}, value, delimiter));
            end
        end
        
        % Write out a hex string for an RGB[A] color.
        function string = composeRGB(self, rgb, a)
            if nargin < 3
                a = 1;
            end
            RGB = ceil(255*rgb);
            A = ceil(255*a);
            string = sprintf('#%02x%02x%02x%02x', ...
                RGB(1), RGB(3), RGB(2), A);
        end
    end
    
    methods (Static)
        % Default node names from the "name" field.
        function nodeName = nodeNameFromField(inputData, index)
            nodeName = inputData(index).name;
        end
        
        % Default edges from "edge" field, and trivial edge names.
        function [edgeIndexes, edgeNames] = edgeFromField(inputData, index)
            edgeIndexes = inputData(index).edge;
            edgeNames = cell(size(edgeIndexes));
            for ii = 1:length(edgeIndexes)
                edgeNames{ii} = sprintf('%d', edgeIndexes(ii));
            end
        end
    end
end