classdef topsCallList < topsConcurrent
    % @class topsCallList
    % A list of functions to call sequentially, as a batch.
    % topsCallList manages a list of functions to be called as a batch.
    % @details
    % Since topsCallList extends topsConcurrent, a topsCallList object can
    % be added as one of the components of a topsConcurrentComposite
    % object, and its batch of functions can be invoked concurrently with
    % other topsConcurrent objects.
    % @details
    % A topsCallList object has no internal state to keep track of, so it
    % has no natural way to decide when it's done running.  The
    % alwaysRunning property determines whether the object should be
    % considered running following each call to runBriefly().
    % @details
    % topsCallList expects functions of a particular form, which it
    % calls "fevalable".  Fevalables are cell arrays that have a function
    % handle as the first element.  Additional elements are treated as
    % arguments to the function.
    % @details
    % The fevalables convention makes it easy to make arbitrary function
    % calls with Matlab's built-in feval() function--hence the name--so the
    % cell array "foo" would be an fevalable if it could be executed with
    % feval(foo{:}).
    % @details
    % By default, all of the fevalables in the call list will be called
    % during each runBriefly().  The activity of each call can be
    % controlled with setActiveByName() or with callByName() with the
    % isActive flag.  A call can also be replaced by passing a new call
    % with the same name to addCall().

    properties
        % struct array with fevalable cell arrays to call as a batch
        calls = struct( ...
            'name', {}, ...
            'fevalable', {}, ...
            'isActive', {});
        
        % true or false, whether to run indefinitely
        alwaysRunning = true;
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsCallList(varargin)
            self = self@topsConcurrent(varargin{:});
        end

        % Open a GUI to view object details.
        % @details
        % Opens a new GUI with components suitable for viewing objects of
        % this class.  Returns a topsFigure object which contains the GUI.
        function fig = gui(self)
            fig = topsFigure(self.name);
            callsPan = topsTablePanel(fig);
            infoPan = topsInfoPanel(fig);
            selfInfoPan = topsInfoPanel(fig);
            fig.usePanels({callsPan selfInfoPan; callsPan infoPan});
            
            fig.setCurrentItem(self.calls, 'calls');
            callsPan.isBaseItemTitle = true;
            callsPan.setBaseItem(self.calls, 'calls');
            
            selfInfoPan.setCurrentItem(self, self.name);
            selfInfoPan.refresh();
            selfInfoPan.isLocked = true;
        end
        
        % Add an "fevalable" to the call list.
        % @param fevalable a cell array with contents to pass to feval()
        % @param name unique name to assign to @a fevalable
        % @details
        % Appends or inserts the given @a fevalable to the calls struct
        % array.  @a name should be unique so that @a fevalable can be
        % referred to later by @a name.  It will replace any existing
        % fevalable with the same @a name will be replaced.
        % @details
        % Returns the index into the calls struct array where @a fevalable
        % was appended or inserted.
        function index = addCall(self, fevalable, name)
            % is this a new name or a replacement?
            index = topsFoundation.findStructName(self.calls, name);
            
            % insert or append the new call
            self.calls(index).name = name;
            self.calls(index).fevalable = fevalable;
            self.calls(index).isActive = true;
        end
        
        % Toggle whether a call is active.
        % @param name given to an fevalable during addCall()
        % @param isActive true or false, whether to invoke the named
        % fevalable during runBriefly()
        % @details
        % Determines whether the named fevalable function call in the calls
        % struct array will be invoked during runBriefly().  If multiple
        % calls have the same name, @a isActive will be applied to all of
        % them.
        function setActiveByName(self, isActive, name)
            [index selector] = ...
                topsFoundation.findStructName(self.calls, name);
            [self.calls(selector).isActive] = deal(isActive);
        end
        
        % Invoke a call now, whether or not it's active.
        % @param name given to an fevalable during addCall()
        % @param isActive whether to activate or un-activate the call at
        % the same time
        % @details
        % @a name must be the name of a call added to this call list with
        % addCall().  Invokes the fevalable for that call, whether or not
        % it's active.  If isActive is provided, sets whether the named
        % call is active, to be invoked in the future by runBriefly().
        % @details
        % Returns the first output from the named call, if any.
        function result = callByName(self, name, isActive)
            
            % need to return a result?
            isResult = nargout > 0;
            
            % toggle the call's runBriefly() activity?
            if nargin >= 3
                self.setActiveByName(isActive, name);
            end
            
            % invoke the call
            [index selector] = ...
                topsFoundation.findStructName(self.calls, name);
            if any(selector)
                call = self.calls(selector);
                
                % with or without returning a result
                if isResult
                    result = feval(call(1).fevalable{:});
                else
                    feval(call(1).fevalable{:});
                end
            end
        end
        
        % Invoke active calls in a batch.
        function runBriefly(self)
            if ~isempty(self.calls)
                isActive = [self.calls.isActive];
                fevalables = {self.calls(isActive).fevalable};
                for ii = 1:length(fevalables)
                    feval(fevalables{ii}{:});
                end
                self.isRunning = self.isRunning && self.alwaysRunning;
            end
        end
    end
end
