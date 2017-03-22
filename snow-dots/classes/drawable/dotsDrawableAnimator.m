classdef dotsDrawableAnimator < dotsDrawable
    % @class dotsDrawableAnimator
    % Update properties or methods of dotsDrawable objects, over time.
    % @details
    % dotsDrawableAnimator organizes time-dependent value changes for
    % dotsDrawable objects.  An array of @b times specifies the time course
    % for value changes, and an array of @b values specifies the changes
    % themselves.
    % @details
    % Value changes may be applied to any object member: they may be
    % assigned to object properties, or passed to object methods.
    % Furthermore, each member may be updated in a variety of ways.  Some
    % members may have @b values interpolated between @a times while others
    % may change by abrupt steps.  Some members may reach a stopping point
    % and remain fixed, others may drift endlessly, and others may wrap
    % endlessly.
    % @details
    % Member values must be numeric, to alow for interpolation.  They may
    % be scalars, or matrices of any size.  Matrices will be interpolated
    % element-wise, so all of the values for a given member must have the
    % same size.
    % @details
    % dotsDrawableAnimator is itself a subclass of dotsDrawable, so it may
    % be used as an aggregate of one or more other dotsDrawable objects.
    % The draw() method performs member updating and can invoke draw() on
    % each aggregated object.  Similarly, prepareToDrawInWindow() invokes
    % prepareToDrawInWindow() on each aggregated object.
    % @details
    % The aggregated drawables may belong to different dotsDrawable
    % subclasses.  But the same members must apply to all of the drawables,
    % so that the animator can treat them uniformly.
    properties
        % function that returns the current time as a number
        clockFunction;
        
        % whether draw() should invoke draw() on aggregated drawables
        isAggregateDraw = true;

        % struct array of values, times, and other animation data
        % @details
        % Each element of allMembers contains information for updating a
        % drawable property or invoking a method, over time.  The fields of
        % allMembers are:
        % 	- @b name a string name of an object property or method
        %   - @b method a function handle, if @a name is a method name.
        %   Any function that takes an object as the first argument and @b
        %   currentValue as the second argument may be used as a "method".
        % 	- @b times a vector of monotonic increasing times, with one
        % 	element for each element of @b values
        %   - @b values a cell array of values to be applied to the member,
        %   based on the time course specified in @b times.
        %   - @b currentValue the current time-varying value of the member
        %   - @b isInterpolated whether @b values are interpolated between
        %   @b times (true), or changed abruptly (false, default).
        %   - @b completionStyle how to behave when the member runs out of
        %   @b times and @b values.  See setMemberCompletionStyle().
        %   Default is 'stop'.
        %   - @b completionHint parameter for guiding 'wrap' or 'drift'
        %   completion style.
        %   .
        % @details
        % Users should call addMember(), editMemberByName(), and
        % setMemberCompletionStyle() instead of manipulating allMembers
        % directly.
        allMembers = struct([]);
    end
    
    properties (SetAccess = protected)
        % cell array of aggregated dotsDrawable objects to animate
        drawables;
        
        % zero-time for the beginning of each animation sequence
        startTime;
        
        % cell array of strings for supported completionStyle
        validCompletionStyle = {'stop', 'wrap', 'drift'};
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableAnimator()
            self = self@dotsDrawable();
        end
        
        % Invoke prepareToDrawInWindow() on aggregated drawables.
        function prepareToDrawInWindow(self)
            if self.isAggregateDraw
                for ii = 1:numel(self.drawables)
                    d = self.drawables{ii};
                    d.prepareToDrawInWindow();
                end
            end
            self.startTime = feval(self.clockFunction);
        end
        
        % Update member values and invoke draw() on aggregated drawables.
        function draw(self)
            
            % update the time-varying values of members
            self.updateMembers();
            members = self.allMembers;
            
            % assign all current values to each drawable
            %   optionally draw() each drawable
            for ii = 1:numel(self.drawables)
                d = self.drawables{ii};
                for jj = 1:numel(members)
                    m = members(jj);
                    if isempty(m.method)
                        d.(m.name) = m.currentValue;
                    else
                        feval(m.method, d, m.currentValue);
                    end
                end
                
                if self.isAggregateDraw && d.isVisible
                    d.draw();
                end
            end
        end
        
        % Update the time-varying currentValue value for each member.
        function updateMembers(self)
            % pick a new currentValue for each member
            currentTime = feval(self.clockFunction) - self.startTime;
            members = self.allMembers;
            for ii = 1:numel(members)
                
                % wrapping behavior?
                if strcmp(members(ii).completionStyle, 'wrap')
                    % completion hint is a time divisor
                    divisor = members(ii).completionHint;
                    t = rem(currentTime, divisor);
                else
                    t = currentTime;
                end
                
                % where does t fall among the member's times?
                times = members(ii).times;
                values = members(ii).values;
                if t < times(1)
                    % clamp to the first value
                    currentValue = values{1};
                    
                elseif t >= times(end)
                    % drifting behavior?
                    if strcmp(members(ii).completionStyle, 'drift')
                        % completionHint is a constant drift rate
                        deltaT = t - times(end);
                        driftRate = members(ii).completionHint;
                        deltaV = deltaT .* driftRate;
                        currentValue = values{end} + deltaV;
                        
                    else
                        % clamp to the last value
                        currentValue = values{end};
                    end
                    
                else
                    % interpolated values?
                    jj = find(t < times, 1, 'first') - 1;
                    if members(ii).isInterpolated
                        fraction = ...
                            (t - times(jj)) ./ (times(jj+1) - times(jj));
                        deltaV = fraction.*(values{jj+1} - values{jj});
                        currentValue = values{jj} + deltaV;
                        
                    else
                        currentValue = values{jj};
                    end
                end
                
                members(ii).currentValue = currentValue;
            end
            
            self.allMembers = members;
        end
        
        % Add a dotsDrawable object to the aggregated drawables.
        % @param drawable dotsDrawable object
        % @details
        % addDrawable() adds the given @a drawable to the array of
        % dotsDrawable objects in drawables.  Returns the index into
        % drawables where @a drawable was added.
        function index = addDrawable(self, drawable)
            [self.drawables, index] = ...
                topsFoundation.cellAdd(self.drawables, drawable);
        end
        
        % Remove a dotsDrawable object from the aggregated drawables.
        % @param drawable dotsDrawable object
        % @details
        % removeDrawable() searches the array of dotsDrawable objects in
        % drawables for the given @a drawable, and removes all instances it
        % finds.
        % @details
        % Returns an array of indexes into drawables where @a drawable was
        % found and removed.  The returned indexes are no longer valid,
        % because @a drawable is gone and drawables has changed length.
        function index = removeDrawable(self, drawable)
            selector = ...
                topsFoundation.cellContains(self.drawables, drawable);
            index = find(selector);
            self.drawables = self.drawables(~selector);
        end
        
        % Specify new values and times for animating a drawable member.
        % @param member string name of a drawable property, or handle of a
        % drawable method
        % @param times monotonic increasing vector of animation time points
        % @param values numeric vector or cell array of matrices of
        % animation values, with the same size as @a times
        % @param isInterpolated whether @a values should be interpolated
        % between @times (true), or applied in abrupt steps (false,
        % default)
        % @details
        % addMember() specifies a new drawable property or method to be
        % animated.  The given @a mamber should match the name of a
        % property or match a method shared by all of the dotsDrawable
        % objects in drawables.
        % @details
        % @a times and @a values specify the time course and values to be
        % applied during animation.  During each draw(), the current time
        % is used as a key to pick the current element of @a times and the
        % corresponding element of @a values.  The current value is applied
        % to @a member for all the objects in @a drawables.
        % @details
        % If @a member is a string property name, objects will receive the
        % current value by assignment:
        % @code
        % object.(member) = currentValue;
        % @endcode
        % If @a member is a method function handle, each object and the
        % current value will be passed to the method:
        % @code
        % feval(member, object, currentValue);
        % @endcode
        % Note that this "method" syntax will work for any function that
        % expects an object and a value as the first two arguments.
        % @details
        % If @a isInterpolated is false (the default), the current value
        % will always be equal to one of the elements of @values, and the
        % current value will change abruptly for each element of @a times.
        % If @a isInterpolated is true, the current value will be
        % interpolated between neighboring elements of @a values, based on
        % the fraction of time that has passed between neighboring elements
        % of @a times.
        % @details
        % addMember() returns the index into allMembers where the new
        % animation specification was stored.  If allMembers already
        % contains a specification for @a member, the existing
        % specification will be replaced.  Otherwise, the new specification
        % will be appended to allMembers.
        function index = addMember( ...
                self, member, times, values, isInterpolated)
            
            if nargin < 5 || isempty(isInterpolated)
                isInterpolated = false;
            end
            
            if ischar(member)
                name = member;
                method = [];
            elseif isa(member, 'function_handle')
                name = genvarname(func2str(member));
                method = member;
            else
                warning('member must be a string or function_handle');
                index = [];
                return;
            end
            
            % replace existing member, or append
            if isempty(self.allMembers)
                index = 1;
            else
                existingNames = {self.allMembers.name};
                existingSelector = strcmp(name, existingNames);
                if any(existingSelector)
                    index = find(existingSelector, 1, 'first');
                else
                    index = numel(self.allMembers) + 1;
                end
            end
            
            % convert vector of values to cell array
            if isnumeric(values)
                values = num2cell(values);
            end
            
            if numel(times) ~= numel(values)
                warning('numel(times) %d must match numel(values) %d', ...
                    numel(times), numel(values))
            end
            
            % fill in a new element of allMembers
            newMember.name = name;
            newMember.method = method;
            newMember.times = times;
            newMember.values = values;
            newMember.currentValue = values(1);
            newMember.isInterpolated = isInterpolated;
            newMember.completionStyle = self.validCompletionStyle{1};
            newMember.completionHint = [];
            if isempty(self.allMembers)
                self.allMembers = newMember;
            else
                self.allMembers(index) = newMember;
            end
        end
        
        % Remove an animation specification.
        % @param member string name of a drawable property, or handle of a
        % drawable method, that was added with addMember()
        % @details
        % removeMember() searches allMembers for an animation specification
        % with member equal to the given @a member, and removes it.
        % @details
        % removeMember() returns the index into allMembers where @a member
        % was found and removed, or [] if it did not find @a member.  The
        % returned index is no longer a valid because @member is gone and
        % allMembers has changed length.
        function index = removeMember(self, member)
            % remove all existing member instances
            if ischar(member)
                name = member;
            elseif isa(member, 'function_handle')
                name = genvarname(func2str(member));
            else
                index = [];
                return;
            end
            existingNames = {self.allMembers.name};
            existingSelector = strcmp(name, existingNames);
            index = find(existingSelector);
            if any(existingSelector)
                self.allMembers(existingSelector) = [];
            end
        end
        
        % Choose what to do when a member runs out of times and values.
        % @param member string name of a drawable property, or handle of a
        % drawable method, that was added with addMember()
        % @param style string name of an animation completion style, must
        % be 'stop', 'wrap', or 'drift'.
        % @param hint parameter which affects 'wrap' or 'drift' behavior
        % @details
        % Each animation specification in allMembers contains a finite
        % number of @b times.  So how should @a member behave when the
        % current time surpasses the last elements of @b times?
        % setMemberCompletionStyle() selects one of three completion
        % styles: 'stop', 'wrap', or 'drift'.
        % @details
        % If @a style is 'stop', then @a member will progress through
        % @b times and @b values once, then stop at the last element of @b
        % values.  In this case, @a hint should be omitted.
        % @details
        % If @a style is 'wrap', then @a member will loop forever
        % through @b times and @a values.  In this case, @a hint must be
        % the wrapping period, which will be used as a divisor for the
        % current time. Note that the wrapping period need not be equal to
        % the last element of @b times.
        % @details
        % If @a style is 'drift', then @a member will progress through
        % @b times and @b values once, then drift at a constant rate.  In
        % this case, @a hint must be the constant drift rate.  The current
        % value will be calculated as the last element of @b values, plus
        % the drift since the last element of @b times.
        % @details
        % The default completion style for each member is 'stop'.
        % @details
        % setMemberCompletionStyle() returns the index into allMembers
        % where @a member was found and updated, or [] if it did not
        % find @a member.
        function index = setMemberCompletionStyle( ...
                self, member, style, hint)
            
            if nargin < 4 || isempty(hint)
                hint = 1;
            end
            
            if ischar(member)
                name = member;
            elseif isa(member, 'function_handle')
                name = genvarname(func2str(member));
            else
                index = [];
                return;
            end
            
            % find one existing member instance
            existingNames = {self.allMembers.name};
            existingSelector = strcmp(name, existingNames);
            index = find(existingSelector, 1, 'first');
            if any(existingSelector)
                if any(strcmp(style, self.validCompletionStyle))
                    self.allMembers(index).completionStyle = style;
                    self.allMembers(index).completionHint = hint;
                else
                    warning('completion style "%s" is not valid', style)
                end
            end
        end        
    end
end