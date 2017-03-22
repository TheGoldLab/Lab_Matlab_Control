classdef topsConditions < topsRunnable
    % @class topsConditions
    % Traverses combinations of conditions and assigns them to objects.
    % @details
    % topsConditions organizes sets of values for various parameters and
    % computes all the combinations of parameter values.  It can traverse
    % conditions by number, and apply parameter values to various objects
    % automatically.  Since topsConditions is a topsRunnable subclass, it
    % can control the flow of an experiment based on the traversal of
    % conditions.
    % @details
    % Each time a topsConditions object run()s, it will pick a new
    % condition, which is a unique combination of parameter values.  Each
    % parameter may have some associated "assignments" which allow
    % parameter values to be applied automatically to properties of other
    % objects.  The object may call its startFevalable and finishFevalable
    % just before and after applying property assignments.
    % @details
    % A topsConditions object has a state (i.e. the condition number) that
    % trancends multiple calls to run().  Thus, it must be reset() to begin
    % picking conditions from scratch.  When pickingMethod runs out of
    % conditions to pick, or when maxPicks is reached (whichever is first),
    % an object sets isDone to true and invokes donePickingFevalable.  If
    % its caller is set to a topsRunnable object, it also sets isRunning to
    % false for that object.

    properties
        % struct array of parameter names, values and assignment targets
        % @details
        % Each field name of allParameters is the name of an arbitrary
        % parameter. Each field contains another struct with the fields:
        %   - @b values cell array of possible values for the parameter
        %   - @b assignments struct array of objects and substruct()-style
        %   references used to assign parameter values to each object.
        %   .
        % @details
        % Users should call addParameter() and addAssignment() instead of
        % manipulating allParameters directly.
        allParameters = struct([]);
        
        % possible number of values combinations from allParameters
        nConditions;
        
        % number of the currently picked condition, from 1 to nConditions
        currentCondition = 0;
        
        % array of previously picked condition numbers
        % @details
        % Keeps track of the history of conditions that were picked,
        % including currentCondition.  reset() empties out
        % previousConditions.
        previousConditions = [];
        
        % struct of all parameters and their current values
        % @details
        % Each field name of currentValues is one of the parameter names
        % from allParameters.  Each field contains the value of that
        % parameter that corresponds to the condition number in
        % currentCOndition.
        currentValues = struct;
        
        % maximum number of conditions to pick, regardless of
        % pickingMethod.
        maxPicks = inf;
        
        % string describing how to pick the next condition
        % @details
        % pickingMethod is the string name of a method for picking the next
        % condition.  See setPickingMethod() for a description of valid
        % pickingMethods.
        % @details
        % Users should call setPickingMethod() instead of accessing the
        % pickingMethod property directly.
        pickingMethod;
        
        % fevalable cell array for custom picking of condition numbers
        % @details
        % When pickingMethod is 'custom', run() invokes customPickFevalable
        % to pick the next condition number.  See setPickingMethod() for a
        % description of customPickFevalable.
        % @details
        % Users should call setPickingMethod() instead of accessing
        % customPickFevalable directly.
        customPickFevalable;
        
        % array of condition numbers to be picked
        % @details
        % When pickingMethod is 'shuffled' or 'sequential',
        % setPickingMethod() precomputes pickSequence with complete sets of
        % condition numbers.
        % @details
        % Users should call setPickingMethod() instead of accessing
        % pickSequence directly.
        pickSequence;
        
        % true or false, whether all done picking conditions
        % @details
        % When pickingMethond runs out of conditions to pick, or when
        % maxPicks is reached (whichever is first) sets isDone to true.
        % @details
        % If isDone is true when run() is called, first calls reset() to
        % prepare for future running.
        isDone = true;
        
        % optional fevalable cell array to invoke when isDone
        donePickingFevalable = {};

        % array of sizes for each parameter's @b values
        allSizes;
        
        % coefficients to convert contion number to @b values indexes
        subscriptCoefficients;
        
        % vasrargin details from the last call to setPickingMethod()
        pickingMethodDetails = {};
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsConditions(varargin)
            self = self@topsRunnable(varargin{:});
        end
                
        % Open a GUI to view object details.
        % @details
        % Opens a new GUI with components suitable for viewing objects of
        % this class.  Returns a topsFigure object which contains the GUI.
        function fig = gui(self)
            fig = topsFigure(self.name);
            allParametersPan = topsTablePanel(fig);
            currentValuesPan = topsTablePanel(fig);
            infoPan = topsInfoPanel(fig);
            selfInfoPan = topsInfoPanel(fig);
            fig.usePanels( ...
                {currentValuesPan selfInfoPan; allParametersPan infoPan});
            
            allParametersPan.isBaseItemTitle = true;
            allParametersPan.setBaseItem( ...
                self.allParameters, 'allParameters');
            currentValuesPan.isBaseItemTitle = true;
            currentValuesPan.setBaseItem( ...
                self.currentValues, 'currentValues');
            fig.setCurrentItem(self.currentCondition, 'currentCondition');
            
            selfInfoPan.setCurrentItem(self, self.name);
            selfInfoPan.refresh();
            selfInfoPan.isLocked = true;
        end
        
        % Add a parameter and set of values for condition formation.
        % @param parameter string field name of a parameter
        % @param values cell array of posssible values for @a parameter
        % @details
        % Adds the named @a parameter and its @a values call array to
        % allParameters.  If allParameters already contains a field named
        % @a parameter, its values will be replaced but any assignments
        % will remain in place.
        % @details
        % The parameter-value combinations in allConditions will be updated
        % immediately to reflect @a parameter and its set of @a values.
        % @details
        % After a parameter is added with addParameter(), parameter
        % assignments may be added with addAssignment().
        function addParameter(self, parameter, values)
            if isfield(self.allParameters, parameter)
                self.allParameters(1).(parameter).values = values;
            else
                self.allParameters(1).(parameter) = struct( ...
                    'values', {values}, ...
                    'assignments', struct('object', {}, 'subs', {}));
            end
            self.countConditions;
        end
        
        % Add an assignment target for a parameter value.
        % @param parameter one of the field names of allParameters
        % @param object an object to receive values of @a parameter
        % @param varargin arguments to pass to substruct() which specify a
        % property or element of @a object.
        % @details
        % Adds the specified property or element of @a object as an
        % assignment target for the given @a property.  During run() or
        % setCondition(), the new value of @a property will be
        % automatically assigned to the target.  A @a property may have
        % multiple assignment targets, each added with addAssignment().
        % @details
        % @a varargin will be passed to Matlab's built-in substruct to
        % specify an arbitrary reference into @a object--the reference
        % could be to one of @a object's properties, a sub-element or
        % sub-field of a property, an element of @a object if it's an
        % array, and so on.
        % @details
        % For example, to specify the 'data' property of @a object, you
        % would use the following to specify a "dot" reference to the
        % "data" field:
        % @code
        % addAssignment( ..., '.', 'data');
        % @endcode
        % @details
        % If @a parameter is not one of fields of allParameters, does
        % nothing.
        function addAssignment(self, parameter, object, varargin)
            if isfield(self.allParameters, parameter)
                subs = substruct(varargin{:});
                self.allParameters(1).(parameter).assignments(end+1) = ...
                    struct('object', object, 'subs', subs);
            end
        end
        
        % Account for parameter-value combinations from allParameters.
        function countConditions(self)
            fn = fieldnames(self.allParameters);
            n = length(fn);
            self.allSizes = zeros(1,n);
            for ii = 1:n
                self.allSizes(ii) = ...
                    numel(self.allParameters.(fn{ii}).values);
            end
            self.nConditions = prod(self.allSizes);
            
            self.subscriptCoefficients = ...
                cumprod([1, self.allSizes(1:end-1)]);
            
            self.currentValues = cell2struct(cell(1,n), fn, 2);
        end
        
        % Pick parameter values for the given condition number.
        % @param n the number of the condition to set, from 1 through
        % nConditions
        % @details
        % Sets currentCondition to the given @a n, appends @a n to the
        % history in previousConditions, and assigns appropriate values
        % to the fields of currentValues.  Adds the new currentCondition
        % and currentValues to topsDataLog.
        function setCondition(self, n)
            self.currentCondition = n;
            self.previousConditions(end+1) = n;
            
            phasic = floor((n-1)./self.subscriptCoefficients);
            subscripts = 1 + mod(phasic, self.allSizes);
            
            fn = fieldnames(self.allParameters);
            n = length(fn);
            for ii = 1:n
                param = fn{ii};
                paramInfo = self.allParameters(1).(param);
                value = paramInfo.values{subscripts(ii)};
                self.currentValues(1).(param) = value;
                
                asgn = paramInfo.assignments;
                for jj = 1:length(asgn)
                    subsasgn(asgn(jj).object, asgn(jj).subs, value);
                end
            end
            
            self.logAction('setCondition', self.currentCondition);
            self.logAction('setValues', self.currentValues);
        end
        
        % Choose how to pick new conditions.
        % @param pickingMethod string describing how to pick conditions.
        % @varargin additional arguments specific to each pickingMehtod,
        % described below.
        % @details
        % setPickingMethod() determines how run() will choose a new
        % conditon number and traverse parameter values.  @a pickingMethod
        % describes the general approach and @a varargin may supply some
        % details.
        % @details
        % The valid values for @a pickingMethod are:
        %   - 'coin-toss' uniform random picks without replacement and
        %   no specific limit on the number of picks
        %   -  'shuffled' uniform shuffling of conditions, spread out over
        %   some number of complete sets.  @a varargin may contain the
        %   number of sets to shuffle together, the default is 1.
        %   - 'sequential' non-random, systematic progression through
        %   conditions, finishing after some number of complete sets.  @a
        %   varargin may contain the number of sets to shuffle together,
        %   the default is 1.
        %   - 'custom' user-supplied customPickFevalable determines each
        %   condition.  @a varargin should contain an fevalable cell array.
        %   The function should expect this topsConditions object as the
        %   first argument.  Any additional arguments will be passed to the
        %   function starting at the second place.  The function should
        %   pick a new condition number, from 1 through nConditions, and
        %   return it.  The function may set isDone to indicate that
        %   picking is all done.
        %   .
        % @details
        % If @a pickingMethod is not one of the valid values above,
        % defaults to 'coin-toss'.
        function setPickingMethod(self, pickingMethod, varargin)
            if nargin < 2 || isempty(pickingMethod)
                pickingMethod = 'coin-toss';
            end
            
            if nargin == 3
                self.pickingMethodDetails = varargin;
            else
                self.pickingMethodDetails = {};
            end
            
            self.pickSequence = [];
            switch pickingMethod
                case 'shuffled'
                    if nargin == 3
                        nSets = varargin{1};
                    else
                        nSets = 1;
                    end
                    pickSet = 1:self.nConditions;
                    self.pickSequence = repmat(pickSet, 1, nSets);
                    shuffle = randperm(numel(self.pickSequence));
                    self.pickSequence = self.pickSequence(shuffle);
                    
                case 'sequential'
                    if nargin == 3
                        nSets = varargin{1};
                    else
                        nSets = 1;
                    end
                    pickSet = 1:self.nConditions;
                    self.pickSequence = repmat(pickSet, 1, nSets);
                    
                case 'custom'
                    if nargin == 3
                        self.customPickFevalable = varargin{1};
                    else
                        self.customPickFevalable = {};
                    end
                    
                otherwise
                    % includes 'coin-toss'
            end
            self.pickingMethod = pickingMethod;
        end
        
        % Log action and reset() as needed.
        % @details
        % Extends the start() method of topsRunnable to also reset()
        % condition picking as needed.
        function start(self)
            self.start@topsRunnable;
            if self.isDone
                self.reset;
            end
        end
        
        % Clear previous conditions and begin picking from scratch.
        % @details
        % Clears out the currentCondition and currentValues, and erases the
        % histor of condition numbers stored in previousConditions.  Calls
        % setPickingMethod() with the current pickingMethod, to generate a
        % fresh pickSequence as necessary.  Sets isDone to false.
        % @details
        % run() and start() automatically call reset() when isDone is true,
        % to prepare for future run() calls.
        function reset(self)
            self.setPickingMethod( ...
                self.pickingMethod, self.pickingMethodDetails{:});
            self.currentCondition = 0;
            self.previousConditions = [];
            self.currentValues = struct;
            self.isDone = false;
        end
        
        % Pick a new condition and assign parameter values to targets.
        function run(self)
            self.start;
            % pickConditionNumber may set isDone
            n = self.pickConditionNumber;
            self.setCondition(n);
            self.finish;
        end
        
        % Log action and call out as needed.
        % @details
        % Extends the finish() method of topsRunnable to also invoke
        % donePickingFevalable and tell caller to stop running, when
        % condition picking is over.
        function finish(self)
            if self.isDone
                self.logFeval('donePicking', self.donePickingFevalable);
                if isobject(self.caller) ...
                        && isa(self.caller, 'topsRunnable')
                    self.caller.isRunning = false;
                end
            end
            self.finish@topsRunnable;
        end
        
        % Pick a condition number using pickingMethod.
        % @details
        % Returns a new condition number picked using the pickingMethod and
        % other details specified with setPickingMethod().  If the picking
        % method has reached its natural conclusion, or the total number of
        % picks is greated than maxPicks, sets isDone to true.
        function n = pickConditionNumber(self)
            pickCount = length(self.previousConditions) + 1;
            switch self.pickingMethod
                case 'shuffled'
                    n = self.pickSequence(pickCount);
                    donePicking = pickCount >= length(self.pickSequence);
                    
                case 'sequential'
                    n = self.pickSequence(pickCount);
                    donePicking = pickCount >= length(self.pickSequence);
                    
                case 'custom'
                    picker = self.customPickFevalable;
                    if ~isempty(picker)
                        n = feval(picker{1}, self, picker{2:end});
                    end
                    % customPickFevalable may set isDone
                    donePicking = self.isDone;
                    
                otherwise
                    % includes 'coin-toss'
                    n = ceil(rand(1,1)*self.nConditions);
                    donePicking = false;
            end
            
            self.isDone = donePicking || pickCount >= self.maxPicks;
        end
    end
end