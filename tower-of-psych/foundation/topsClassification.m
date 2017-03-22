classdef topsClassification < topsFoundation
    % @class topsClassification
    % Represents data as points in space, for classification.
    % @details
    % topsClassification takes in data samples from multiple sources and
    % outputs arbitrary values.  It maps samples to outputs by way of
    % a spatial model: each data source maps to a spatial dimension,
    % each sample maps to a value along one dimension, and a set of
    % samples maps to a point in space.  Regions in the space map to
    % arbitrary outputs, so the region in which a point falls determines
    % the output for a sample set.
    % @details
    % The spatial model is backed up by a high-dimensional matrix.  Picking
    % a point in space boils down to indexing into the matrix.  The key is
    % to convert arbitrary data samples into matrix indices.

    properties
        % default output when no other output is defined
        defaultOutput = [];
        
        % name to give to the default output
        defaultOutputName = 'default';
    end
    
    properties (SetAccess = protected)
        % struct array of data sources and descriptions
        sources = struct( ...
            'name', {}, ...
            'dimension', {}, ...
            'sampleFunction', {}, ...
            'sample', {});
        
        % topsSpace with spatial modeling utilities
        space;
        
        % struct array of spatial regions and outputs
        outputs = struct( ...
            'name', {}, ...
            'region', {}, ...
            'value', {});
        
        % high-dimensional matrix for looking up output
        outputTable;
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsClassification(varargin)
            self = self@topsFoundation(varargin{:});
        end
        
        % Open a GUI to view object details.
        % @details
        % Opens a new GUI with components suitable for viewing objects of
        % this class.  Returns a topsFigure object which contains the GUI.
        function fig = gui(self)
            fig = topsFigure(self.name);
            sourcesPan = topsTablePanel(fig);
            outputsPan = topsTablePanel(fig);
            infoPan = topsInfoPanel(fig);
            selfInfoPan = topsInfoPanel(fig);
            fig.usePanels({outputsPan selfInfoPan; sourcesPan infoPan});
            
            fig.setCurrentItem(self.sources, 'sources');
            sourcesPan.isBaseItemTitle = true;
            sourcesPan.setBaseItem(self.sources, 'sources');
            outputsPan.isBaseItemTitle = true;
            outputsPan.setBaseItem(self.outputs, 'outputs');
            
            selfInfoPan.setCurrentItem(self, self.name);
            selfInfoPan.refresh();
            selfInfoPan.isLocked = true;
        end
        
        % Add a data source.
        % @param name unique name for the data source
        % @param sampleFunction function_handle that returns a sample
        % @param minimum minimum sample value to expect
        % @param maximum maximum sample value to expect
        % @param nPoints points to use between @a minumum and @a maximum
        % @details
        % Adds a data source to be included in classification.  @a name
        % must be unique so that the source can be referred to later by
        % name.  Any existing source with the same name will be replaced.
        % This will invalidate existing outputs, because it changes the
        % spatial model.
        % @details
        % @a sampleFunction must be function handle, and the function
        % should return a scalar, numeric sample value for the named
        % source.
        % @details
        % @a minimum and @a maximum must be the minumum and maximum
        % expected sample values from the named source.  @a nPoints must be
        % the number of points to space evenly between @a minimum and @a
        % maximum.  @a minimum, @a maximum, and @a nPoints are used to
        % convert raw sample values into high-dimensional matrix indices.
        % @details
        % Returns the intex into sources where the source was inserted or
        % appended.
        function index = addSource(self, ...
                name, sampleFunction, minimum, maximum, nPoints)
            
            % represent this data source as a spatial dimension
            dimension = topsDimension(name, minimum, maximum, nPoints);
            
            % new or replacement source name?
            index = topsFoundation.findStructName(self.sources, name);
            self.sources(index).name = name;
            self.sources(index).dimension = dimension;
            self.sources(index).sampleFunction = sampleFunction;
            self.sources(index).sample = [];
            
            % rebuild the data space
            self.buildSpace();
        end
        
        % Remove a data source by name.
        % @param name unique name of a data source
        % @details
        % Removes the named data source.  This will invalidate existing
        % outputs, because it changes the spatial model.
        % @details
        % Returns the index into sources where the named source was
        % removed, or [] if no source was found.
        function index = removeSource(self, name)
            % remove all instances of name
            [index, selector] = ...
                topsFoundation.findStructName(self.sources, name);
            self.sources = self.sources(~selector);
            index = find(selector, 1, 'first');
            
            % rebuild the data space
            self.buildSpace();
        end
        
        % Add a classification output.
        % @param name unique name for the output
        % @param region topsRegion spatial region that maps to the output
        % @param value output value mapped from @a region
        % @details
        % Adds an output @a value that can be returned as a classification
        % result.  @a region must be a topsRegion object specifying the
        % region of the spatial model that should map to @a value.  @a name
        % must be a unique name for this @a region-@a value pair.
        % @details
        % If multiple output regions overlap, those that were added later
        % take presidence.
        % @details
        % Returns the index into outputs where the named output was
        % inserted or appended.
        function index = addOutput(self, name, region, value)
            % new or replacement source name?
            index = topsFoundation.findStructName(self.outputs, name);
            self.outputs(index).name = name;
            self.outputs(index).region = region;
            self.outputs(index).value = value;
            
            % rebuild the data space
            self.buildOutputTable();
        end
        
        % Remove a classification output by name.
        % @param name unique name of a classification output
        % @details
        % Removes the named output from classification.  Returns the index
        % into outputs where the named output was removed, or [] if no
        % output was found.
        function index = removeOutput(self, name)
            % remove all instances of name
            [index, selector] = ...
                topsFoundation.findStructName(self.outputs, name);
            self.outputs = self.outputs(~selector);
            index = find(selector, 1, 'first');
            
            % rebuild the data space
            self.buildOutputTable();
        end

        % Change the value mapped from an existing output.
        % @param name unique name of a classification output
        % @param value new value for the named output
        % @details
        % Change the output value associated with the given @a name.  The
        % spatial region associated with @a name remians the same, but the
        % value, as returned from getOutput() is replaced with the new @a
        % value.
        % @details
        % Returns the index into outputs where the named value was
        % changed, or [] if no output was found.
        function index = editOutputValue(self, name, value)
            % find the named output
            [index, selector] = ...
                topsFoundation.findStructName(self.outputs, name);
            if any(selector)
                self.outputs(index).value = value;
            else
                index = [];
            end
        end
        
        % Update source samples.
        % @details
        % Retrieves new samples for each data source, using the
        % sampleFunction provided for each source in addSource().
        function updateSamples(self)
            nSources = numel(self.sources);
            for ii = 1:nSources
                self.sources(ii).sample = ...
                    feval(self.sources(ii).sampleFunction);
            end
        end
        
        % Get the current classification output.
        % @param doUpdate optional, whether invoke updateSamples() first
        % @details
        % Uses the current sample value of all sources to locate a point in
        % the spatial model and return the associated output value.
        % Returns as a second output the name of the output.  By default,
        % invokes updateSamples() to refresh source sample values. if @a
        % doUpdate is provided and false, leaves source samples as they
        % are.
        function [value, name] = getOutput(self, doUpdate)
            value = self.defaultOutput;
            name = self.defaultOutputName;
            
            if nargin < 2
                doUpdate = true;
            end
            
            % get fresh data
            if doUpdate
                self.updateSamples();
            end
            
            if ~isempty(self.sources)
                % convert source samples to a grand spatial table index
                samples = [self.sources.sample];
                subscripts = self.space.subscriptsForValues(samples);
                tableIndex = self.space.indexForSubscripts(subscripts);
                
                % retrieve the output mapped from the indexed region
                outputIndex = self.outputTable(tableIndex);
                if outputIndex > 0
                    value = self.outputs(outputIndex).value;
                    name = self.outputs(outputIndex).name;
                end
            end
        end
    end
    
    methods (Access = protected)
        % Rebuild the data space.
        % @details
        % Invalidate now-stale outputs and reallocate the outputTable.
        function buildSpace(self)
            dimensions = [self.sources.dimension];
            self.space = topsSpace(self.name, dimensions);
            self.clearOutputs;
        end
        
        % Clear out the outputTable lookuptable.
        function clearOutputs(self)
            % clear elements but preserve field names
            selector = true(size(self.outputs));
            self.outputs = self.outputs(~selector);
            self.outputTable = [];
        end
        
        % Rebuild the outputTable lookuptable.
        function buildOutputTable(self)
            nOutputs = numel(self.outputs);
            
            % try to conserver space for this large lookup table
            if nOutputs <= intmax('uint8')
                intClass = 'uint8';
            else
                intClass = 'uint32';
            end
            self.outputTable = zeros(self.space.nDimPoints, intClass);
            
            % fill in output indexes throughout the table
            for ii = 1:nOutputs
                selector = self.outputs(ii).region.selector;
                self.outputTable(selector) = ii;
            end
        end
    end
end