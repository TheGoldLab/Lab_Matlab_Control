classdef StateDiagramGrapher < handle
    % @class StateDiagramGrapher
    % Make topsStateMachine state diagrams with the Graphviz tool.
    % @details
    % StateDiagramGrapher summarizes states, actions, inputs, and
    % transitions for a topsStateMachine object.  It allows for input
    % "hints" that specify possible transitions without having to run the
    % state machine.  It configures a DataGrapher to graph which states may
    % transition to which.
    
    properties
        % a topsStateMachine object to summarize
        stateMachine;
        
        % struct of state data and input "hints" to graph
        stateInfo;
        
        % struct of state names and representative input values
        inputHints;
        
        % a DataGrapher object for graphing the profiler output
        dataGrapher;
    end
    
    methods
        % Constructor takes no arguments.
        function self = StateDiagramGrapher()
            self.dataGrapher = DataGrapher();
            self.dataGrapher.workingFileName = 'stateDiagram';
            self.dataGrapher.floatingEdgeNames = true;
            self.dataGrapher.listedEdgeNames = false;
            self.inputHints = struct( ...
                'stateName', {}, ...
                'inputValue', {});
            
            self.dataGrapher.nodeDescriptionFunction = ...
                @StateDiagramGrapher.statePropertySummary;
            
            self.dataGrapher.edgeFunction = ...
                @StateDiagramGrapher.edgesFromState;
        end
        
        % Add a transition not in the state list to the graph.
        % @param stateName the name of the state to transition from
        % @param inputValue the name of the state to transation to (also
        % the value returned from an input function which causes the
        % transation to that state)
        % @details
        % Adds a transition to the state diagram which was is not obvious
        % from parsing the state list alone.  Allows graphing of
        % representative conditional transitions.
        function addInputHint(self, stateName, inputValue)
            hint.stateName = stateName;
            hint.inputValue = inputValue;
            self.inputHints(end+1) = hint;
        end
        
        % Parse the state list of stateMachine to prepare for graphing.
        function parseStates(self)
            info = self.stateMachine.allStates;
            [info.inputHint] = deal({});
            stateNames = {info.name};
            
            for ii = 1:length(self.inputHints)
                whichState = ...
                    strcmp(stateNames, self.inputHints(ii).stateName);
                if any(whichState)
                    iv = self.inputHints(ii).inputValue;
                    if iscell(iv)
                        info(whichState).inputHint = cat(2, ...
                            info(whichState).inputHint, iv);
                    else
                        info(whichState).inputHint{end+1} = iv;
                    end
                end
            end
            
            n = length(info) + 1;
            info(n).name = '*START*';
            info(n).timeout = 0;
            info(n).next = info(1).name;
            
            self.stateInfo = info;
            self.dataGrapher.inputData = info;
        end
        
        % Write a GraphViz ".dot" file that specifies the state diagram.
        function writeDotFile(self)
            self.dataGrapher.writeDotFile;
        end
        
        % Generate an image with GraphVis, based on the ".dot" file.
        function generateGraph(self)
            self.dataGrapher.generateGraph;
        end
    end
    
    methods (Static)
        % Create a cell array of strings that summarizes some state data.
        function description = statePropertySummary(inputData, index)
            id = inputData(index);
            description = {};
            funs = {'entry', 'input', 'exit'};
            for ii = 1:length(funs)
                funName = funs{ii};
                fun = id.(funName);
                if ~isempty(fun)
                    func = evalc('disp(fun{1})');
                    func = func(~isspace(func));
                    description{end+1} = sprintf('%s: %s', ...
                        funName, func);
                end
            end
            
            if id.timeout > 0
                description{end+1} = sprintf('timeout: %f', id.timeout);
            end
            
            if isempty(id.next)
                description{end+1} = '*END*';
            end
        end
        
        % Find edges leading away from a given state.
        function [edgeIndexes, edgeNames] = edgesFromState( ...
                inputData, index)
            
            id = inputData(index);
            stateNames = {inputData.name};
            edgeIndexes = [];
            edgeNames = {};
            
            % check the state's "next" state
            if ~isempty(id.next)
                edgeIndexes(end+1) = find(strcmp(stateNames, id.next), 1);
                edgeNames{end+1} = 'next';
            end
            
            % check the state's classification object
            if ~isempty(id.classification)
                default = id.classification.defaultOutput
                defaultIndex = find(strcmp(stateNames, default), 1);
                if ~isempty(defaultIndex)
                    edgeIndexes(end+1) = defaultIndex;
                    edgeNames{end+1} = id.classification.defaultOutputName;
                end
                
                outputs = id.classification.outputs;
                for ii = 1:numel(outputs)
                    edgeIndexes(end+1) = ...
                        find(strcmp(stateNames, outputs(ii).value), 1);
                    edgeNames{end+1} = outputs(ii).name;
                end
            end
            
            % check arbitrary input hints
            for ii = 1:length(id.inputHint)
                hintName = id.inputHint{ii};
                if ~isempty(hintName)
                    edgeIndexes(end+1) = ...
                        find(strcmp(stateNames, hintName), 1);
                    edgeNames{end+1} = hintName;
                end
            end
        end
    end
end