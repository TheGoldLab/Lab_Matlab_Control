classdef topsEnsemble < topsCallList
    % @class topsEnsemble
    % Aggregate objects into an ensemble for batch opertaions.
    % @details
    % topsEnsemble groups together other objects and can access their
    % properties or methods all at once.  Individual objects in the
    % ensemble can be accessed or removed by index.  The order of objects
    % in the ensemble, can be specified as they're added to the ensemble.
    % This affects the order in which properties and methods will be
    % accessed.
    % @details
    % Any objects can be added to an ensemble.  The objects should have
    % at least one property name or methods in common, so that they can
    % respond in concert to the same property access or method calls.
    % @details
    % topsEnsemble is expected to work with "handle" objects (objects that
    % inherit from the built-in handle class).  Other objects or data types
    % may be added, but these may behave poorly:
    %   - Non-handle objects may not reflect property changes correctly.
    %   - Non-object data types may cause errors when the ensemble attempts
    %   to access their properties or methods.
    % @details
    % topsEnsemble extends topsCall list.  Where topsCall list is able to
    % call arbitrary functions, topsEnsemble can also call arbitrary
    % methods on its aggrigated objects.
    properties (SetAccess = protected)
        % array of objects in the ensemble
        objects = {};
    end
    
    methods
        % Constuct with name optional.
        % @param name optional name for this object
        % @details
        % If @a name is provided, assigns @a name to this object.
        function self = topsEnsemble(varargin)
            self = self@topsCallList(varargin{:});
        end
        
        % Open a GUI to view object details.
        % @details
        % Opens a new GUI with components suitable for viewing objects of
        % this class.  Returns a topsFigure object which contains the GUI.
        function fig = gui(self)
            fig = topsFigure(self.name);
            objectsPan = topsTablePanel(fig);
            callsPan = topsTablePanel(fig);
            infoPan = topsInfoPanel(fig);
            selfInfoPan = topsInfoPanel(fig);
            fig.usePanels( ...
                {callsPan selfInfoPan; objectsPan infoPan});
            
            objectsPan.isBaseItemTitle = true;
            objectsPan.setBaseItem(self.objects(:), 'objects');
            callsPan.isBaseItemTitle = true;
            callsPan.setBaseItem(self.calls, 'calls');
            fig.setCurrentItem(self.objects, 'objects');
            
            selfInfoPan.setCurrentItem(self, self.name);
            selfInfoPan.refresh();
            selfInfoPan.isLocked = true;
        end
        
        % Add one object to the ensemble.
        % @param object any object to add to the ensemble
        % @param index optional index where to insert the object
        % @details
        % Adds the given @a object to this ensemble.  By default, adds @a
        % object at the end of the ensemble, so it will be accessed after
        % any other objects.  If @a index is provided it must be a positive
        % integer specifying where to insert @a object in the ensemble.
        % Any existing object with the same index will be replaced.
        % @details
        % topsEnsemble assumes that objects are packed without gaps into
        % its objects array.  This will always be the case if @a index is
        % omitted.  If @a index is provided, care must be taken to pack
        % objects into the ensemble.
        % @details
        % Returns the index where @a object was appended or inserted into
        % the ensemble, which may be the same as the given @a index.
        function index = addObject(self, object, index)
            % insert or append?
            if nargin < 3 || isempty(index)
                [self.objects, index] = topsFoundation.cellAdd( ...
                    self.objects, object);
                
            else
                [self.objects, index] = topsFoundation.cellAdd( ...
                    self.objects, object, index);
            end
        end
        
        % Remove one or more objects from the ensemble.
        % @param index ensemble object index or indexes
        % @details
        % Removes the indicated object or objects from this ensemble.
        % Since removal changes the size of the ensemble, previously used
        % indexes may become invalid.  Returns the object that was removed,
        % or a cell array of removed objects.
        function object = removeObject(self, index)
            object = self.getObject(index);
            self.objects = topsFoundation.cellRemoveElement( ...
                self.objects, index);
        end
        
        % Get one or more objects in the ensemble.
        % @param index ensemble object index or indexes
        % @details
        % Returns the indexed object from this ensemble, or a cell array
        % containing multiple objects.
        function object = getObject(self, index)
            if isscalar(index)
                object = self.objects{index};
            else
                object = self.objects(index);
            end
        end
        
        % Is the given object a member of the ensemble?
        % @param object an object that might be in the ensemble
        % @details
        % Returns true if the given @a object is equal to an object in this
        % ensemble, otherwise returns false.  Also returns as a second
        % output the index of the first object found to be equal to the
        % given @a object.  If no object is found to be equal, the returned
        % index will be empty.
        function [isMember, index] = containsObject(self, object)
            selector = topsFoundation.cellContains(self.objects, object);
            isMember = any(selector);
            index = find(selector, 1, 'first');
        end
        
        % Assign one object to a property of one other object.
        % @param innerIndex ensemble index of the object to be assigned
        % @param outerIndex ensemble index of the object that will receive
        % @param varargin asignment specification pased to substruct()
        % @details
        % "Wires up" an aggregation relationship between two ensemble
        % objects.  @a innerIndex specifies the inner object which will be
        % assigned to an outer object.  @a outerObject specifies the outer
        % object.  Both objects must belong to this ensemble.
        % @details
        % @a varargin specifies how to assign the inner object to the outer
        % object. These trailing arguments will be passed to Matlab's
        % built-in substruct() function.  @a varargin could specify a
        % property of the outer object, or drill down to specify a
        % sub-field or element of a property.
        % @details
        % For example, to specify the 'data' property of the outer object,
        % use the following "dot" reference to the 'data' property:
        % @code
        % assignObject(@a innerIndex, @a outerIndex, '.', 'data');
        % @endcode
        % The result would be the same as
        % @code
        % outerObject.data = innerObject;
        % @endcode
        % @details
        % Assignment can be undone by passing an empty @a innerIndex.
        function assignObject(self, innerIndex, outerIndex, varargin)
            % resolve the ensemble objects
            if isempty(innerIndex)
                innerObject = [];
            else
                innerObject = self.getObject(innerIndex);
            end
            outerObject = self.getObject(outerIndex);
            
            % create an arbitrary substruct
            subs = substruct(varargin{:});
            subsasgn(outerObject, subs, innerObject);
        end
        
        % Pass one object to a method of another object.
        % @param innerIndex ensemble index of the object to pass
        % @param outerIndex ensemble index of the receiving object
        % @param method function_handle of a receiving object method
        % @param args optional cell array of arguments to pass to @a method
        % @param argIndex optional index into @a args of the object to pass
        % @details
        % Passes one ensemble object to a method of another ensmble object.
        % @a innerIndex specifies the inner object which will be passed as
        % an argument.  @a outerObject specifies the outer object which
        % will have its @a method invoked, and the inner object passed to
        % it.  Both objects must belong to this ensemble.
        % @details
        % By default, the inner object is passed as the first and only
        % argument to the outer object's @a method.  This case would be
        % equivalent to
        % @code
        % outerObject.method(innerObject);
        % @endcode
        % @details
        % @a args may contain additional arguments to pass to @a method. @a
        % argIndex may specify where in the @a args to place the inner
        % object.  This case would be equivalent to
        % @code
        % args{argIndex} = innerObject;
        % outerObject.method(args{:});
        % @endcode
        % Any value at @a args{@a argIndex} will be replaced with the inner
        % object.  If @a argIndex is omitted, it defaults to 1.
        function passObject( ...
                self, innerIndex, outerIndex, method, args, argIndex)
            
            if nargin < 5 || isempty(args)
                args = {};
            end
            
            if nargin < 6 || isempty(argIndex)
                argIndex = 1;
            end
            
            % resolve ensemble objects
            innerObject = self.getObject(innerIndex);
            outerObject = self.getObject(outerIndex);
            
            if isempty(args)
                % inner object is the first and only argument
                feval(method, outerObject, innerObject);
                
            else
                % additional arguments to pass along with inner object
                args{argIndex} = innerObject;
                feval(method, outerObject, args{:});
            end
        end
        
        % Set a property for one or more objects.
        % @param property string name of an ensemble object property
        % @param value one value to assign to @a property
        % @param index optional ensemble object index or indexes
        % @details
        % Sets the value of the named @a property, which ensemble objects
        % have in common.  @a value can be any value to set to all objects.
        % @details
        % By default, sets @a value to all objects in the ensemble.  If @a
        % index is provided, it may specify a subset of ensemble objects.
        function setObjectProperty(self, property, value, index)
            % all or indexed objects?
            if nargin >= 4
                objs = self.objects(index);
            else
                objs = self.objects;
            end
            
            % set one at a time
            nObjects = numel(objs);
            for ii = 1:nObjects
                objs{ii}.(property) = value;
            end
        end
        
        % Get a property value for one or more objects.
        % @param property string name of an ensemble object property
        % @param index optional ensemble object index or indexes
        % @details
        % Gets the value of the named @property, which ensemble objects
        % have in common.  Returns a cell array with one element per
        % object, containing each @a property value.  If there is only one
        % object, returns the value without enclosing it in a cell array.
        % @details
        % By default, gets a value from each each ensemble object.  If @a
        % index is provided, it may specify a subset of ensemble objects.
        function value = getObjectProperty(self, property, index)
            % all or indexed objects?
            if nargin >= 3
                objs = self.objects(index);
            else
                objs = self.objects;
            end
            nObjects = numel(objs);
            
            % get one at a time
            value = cell(1, nObjects);
            for ii = 1:nObjects
                value{ii} = objs{ii}.(property);
            end
            
            % cell array or scalar value?
            if nObjects == 1
                value = value{1};
            end
        end
        
        % Call a method for one or more objects.
        % @param method function_handle of an ensemble object method
        % @param args optional cell array of arguments to pass to @a method
        % @param index optional ensemble object index or indexes
        % @param isCell optional whether to pass objects in one cell array
        % @details
        % Calls the given @a method, which ensemble objects have in
        % common.  If @a args is provided, passes the elements of @a args
        % as arguments to @a method.  Returns a cell array with one element
        % per object, containing the first @a method result from each
        % object.  If there is only one object, returns the result without
        % enclosing it in a cell array.
        % @details
        % By default, calls @a method once per object in the ensemble.
        % If @a index is provided, it may specify particular ensemble
        % objects.  For example, @a index may specify a subset of objects,
        % or the order in which objects should have @a method invoked.
        % @details
        % By default, iterates through objects, invoking @a method once per
        % object.  If isCell is true, invokes @a method only once, passing
        % a cell array of objects as the first argument.  This assumes that
        % @a method is a static class method that operates on multiple
        % objects at once.  @a method could also be a regular function.
        function result = callObjectMethod( ...
                self, method, args, index, isCell)
            % pass arguments to method?
            if nargin < 3 || isempty(args)
                args = {};
            end
            
            % all or indexed objects?
            if nargin < 4 || isempty(index)
                objs = self.objects;
            else
                objs = self.objects(index);
            end
            nObjects = numel(objs);
            
            % invoke as one batch
            if nargin < 5 || isempty(isCell)
                isCell = false;
            end
            
            % need to collect a result?
            %   pass objects as a cell array?
            if nargout == 0
                if isCell
                    % invoke once for the cell array
                    feval(method, objs, args{:});
                    
                else
                    % invoke for each object
                    for ii = 1:nObjects
                        feval(method, objs{ii}, args{:});
                    end
                end
                
            else
                if isCell
                    % collect one result for the cell array
                    result = feval(method, objs, args{:});
                    
                else
                    % collect a result for each object
                    result = cell(1, nObjects);
                    for ii = 1:nObjects
                        result{ii} = feval(method, objs{ii}, args{:});
                    end
                    % return cell array or scalar value?
                    if nObjects == 1
                        result = result{1};
                    end
                end
            end
        end
        
        % Prepare to repeatedly call a method, for one or more objects.
        % @name name string name given to this automated method call
        % @param method function_handle of an ensemble object method
        % @param args optional cell array of arguments to pass to @a method
        % @param index optional ensemble object index or indexes
        % @param isCell optional whether to pass objects in one cell array
        % @param isActive whether the named method call should be active
        % @details
        % Defines an automated method call, with the given @a name.
        % Any existing call with @a name will be replaced. The
        % automated call can be treated like other topsCallList calls: it
        % may be invoked by the user with callByName(), or automatically
        % during runBriefly().
        % @details
        % By default, automated method calls will be invoked during
        % runBriefly().  If @a isActive is provided and
        % false, runBriefly() will ignore the named call.  Calls may be
        % activated or deactivated later with setActiveByName() or
        % callByName() with the isActive flag.
        % @details
        % Prepares to call @a method, which ensemble objects have in
        % common.  If @a args is provided, the elements of @a args will be
        % passed as arguments to @a method.
        % @details
        % By default, calls @a method once per object in the ensemble.
        % If @a index is provided, it may specify particular ensemble
        % objects.  For example, @a index may specify a subset of objects,
        % or the order in which objects should have @a method invoked.
        % @details
        % By default, iterates through objects, invoking @a method once per
        % object.  If isCell is true, invokes @a method only once, passing
        % a cell array of objects as the first argument.  This assumes that
        % @a method is a static class method that operates on multiple
        % objects at once.  @a method could also be a regular function.
        % @details
        % Returns the index into the calls struct array where the automated
        % method call was appended or inserted.
        function index = automateObjectMethod( ...
                self, name, method, args, index, isCell, isActive)
            
            if nargin < 7 || isempty(isActive)
                isActive = true;
            end
            
            % call this method on self
            fevalable = {@callObjectMethod, self, method};
            
            % pass args to method?
            if nargin >= 4
                fevalable{4} = args;
            end
            
            % subset of ensemble objecs?
            if nargin >= 5
                fevalable{5} = index;
            end
            
            % pass objects as one cell array?
            if nargin >= 6
                fevalable{6} = isCell;
            end
            
            % append or insert in call list
            index = self.addCall(fevalable, name);
            self.setActiveByName(isActive, name);
        end
    end
end