function rBatch(method, classes, varargin)
%Invoke a method for multiple objects belonging to like or unlike classes
%   rBatch(method, classes, varargin)
%
%   rBatch invokes a same-named method for multiple objects of like or
%   unlike classes.
%
%   'method' specifies the name of the method to invoke.  'method' may be a
%   string containing the name of one method, or a cell, see below.
%
%   classes is optional and may have one of two forms:
%	-A list of class names,
%
%       {class_name1, class_name2, ...},
%
%	dictates that 'method' should be invoked only for instances of the
%	specified classes.
%
%   -A cell array of paired strings and indices,
%
%       {class_name1, indices1, class_name2, indices2, ...},
%
%	dicatates that 'method' should be invoked only for the specified
%	instances of the specified classes.  If e.g. indices1 is the empty
%	[], 'method' will be invoked for all active instances of
%	class_name1.
%
%   varargin is an optional cell array of arguments to include when
%   invoking 'method'.
%
%   'method' may alternatively contain a cell array of which each row
%   specifies a separate method invokation.  In this case, classes and
%   varargin should not be provided, and rows of method must have the form
%
%       {method_name, class_name, indices [,arguments]; ... }.
%
%   In this case, each method_name specifies the name of a method to
%   invoke, each class_name specifies the name of one class for which to
%   invoke method_name, and each indices specifies active class instances
%   on which to invoke method_name.  each arguments is an optional cell
%   array of arguments to include when invoking 'method_name'.
%
%   The following demonstrated several modes of rBatch.
%
%   % set up some objects
%   rInit('debug');
%   rAdd('dXdots', 5);
%   rAdd('dXtarget', 10);
%   rAdd('dXtext', '2');
%   rGraphicsShow;
%
%   % invoke the 'draw' method for all active instances of all classes that
%   %   define a 'draw' method.
%   rBatch('draw');
%
%   % invoke the 'blank' method for one instance of dXdots
%   %   and all instances of dXtarget
%   rBatch('blank', {'dXdots', 1; 'dXtarget', []});
%
%   % make dXtext instances green
%   rBatch('set', {'dXtext'}, 'color', [0,255,0]);
%
%   % make odd-numbered dXdots instances blue,
%   %   make all dXtarget instances white,
%   %   and draw all dXdots and dXtarget instances
%   dotArg = {'color', [0,0,255]};
%   targArg = {'color', [1,1,1]*255};
%   rBatch({ ...
%       @set,   'dXdots',   [1,3,5],    dotArg; ...
%       @set,   'dXtarget', [],         targArg; ...
%       @draw,  'dXdots',   [],         {}; ...
%       @draw,  'dXtarget', [],         {}})
%
%   See also rDone rInit rAdd rGraphicsShow

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% break up into (most) possible combinations of inputs,
%   to avoid conditionalization within the loop
if nargin < 3

    if iscell(method)

        % full method list
        if size(method, 2) == 4

            %%%
            % Full batch cell array given as first arg
            % Syntax:
            %   rBatch({<fun>, <class>, <indices>, <args>; ...})
            %%%
            for ii = 1:size(method, 1)

                % check for index list
                if isempty(method{ii, 3})
                    ROOT_STRUCT.(method{ii, 2}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2}), ...
                        method{ii, 4}{:});
                else
                    ROOT_STRUCT.(method{ii, 2})(method{ii, 3}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2})(method{ii, 3}), ...
                        method{ii, 4}{:});
                end
            end

        else % size == 3

            %%%
            % Partial batch cell array given as first arg
            % Syntax:
            %   rBatch({<fun>, <class>, <indices>; ...})
            %%%
            for ii = 1:size(method, 1)

                % check for index list
                if isempty(method{ii, 3})
                    ROOT_STRUCT.(method{ii, 2}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2}));
                else
                    ROOT_STRUCT.(method{ii, 2})(method{ii, 3}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2})(method{ii, 3}));
                end
            end
        end

    else

        if nargin < 2 || isempty(classes)
            classes = ROOT_STRUCT.methods.(method);
        end

        % class list includes indices
        if size(classes, 2) == 2 && isnumeric(classes{1, 2})

            %%%
            % Method and class list given
            % Syntax:
            %   rBatch(<fun>, {<class>, <indices>; ...})
            %%%
            for ii = 1:size(classes, 1)
                if isempty(classes{ii, 2})
                    ROOT_STRUCT.(classes{ii, 1}) = ...
                        feval(method, ROOT_STRUCT.(classes{ii, 1}));
                else
                    ROOT_STRUCT.(classes{ii, 1})(classes{ii, 2}) = ...
                        feval(method, ROOT_STRUCT.(classes{ii, 1})(classes{ii, 2}));
                end
            end

        else

            %%%
            % Only method list given
            % Syntax:
            %   rBatch(<fun>, {<class1>, <class2>, ...})
            %%%

            for cl = classes
                ROOT_STRUCT.(cl{:}) = feval(method, ROOT_STRUCT.(cl{:}));
            end
        end
    end

else

    % ARGLIST GIVEN
    if iscell(method)

        % full method list
        if size(method, 2) == 4

            for ii = 1:size(method, 1)

                % check for index list
                if isempty(method{ii, 3})
                    ROOT_STRUCT.(method{ii, 2}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2}), ...
                        method{ii, 4}{:}, varargin{:});
                else
                    ROOT_STRUCT.(method{ii, 2})(method{ii, 3}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2})(method{ii, 3}), ...
                        method{ii, 4}{:}, varargin{:});
                end
            end

        else % size == 3

            for ii = 1:size(method, 1)

                % check for index list
                if isempty(method{ii, 3})
                    ROOT_STRUCT.(method{ii, 2}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2}), varargin{:});
                else
                    ROOT_STRUCT.(method{ii, 2})(method{ii, 3}) = ...
                        feval(method{ii, 1}, ROOT_STRUCT.(method{ii, 2})(method{ii, 3}), ...
                        varargin{:});
                end
            end
        end

    else

        if nargin < 2 || isempty(classes)
            classes = ROOT_STRUCT.methods.(method);
        end

        % class list includes indices
        if size(classes, 2) == 2 && isnumeric(classes{1, 2})

            % method and class list given
            for ii = 1:size(classes, 1)
                if isempty(classes{ii, 2})
                    ROOT_STRUCT.(classes{ii, 1}) = ...
                        feval(method, ROOT_STRUCT.(classes{ii, 1}), varargin{:});
                else
                    ROOT_STRUCT.(classes{ii, 1})(classes{ii, 2}) = ...
                        feval(method, ROOT_STRUCT.(classes{ii, 1})(classes{ii, 2}), varargin{:});
                end
            end

        else

            % only method list given
            for cl = classes
                ROOT_STRUCT.(cl{:}) = ...
                    feval(method, ROOT_STRUCT.(cl{:}), varargin{:});
            end
        end
    end
end
