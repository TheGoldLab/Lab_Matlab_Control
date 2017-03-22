function val_ = rGet(class_name, varargin)
%Get an object instance or properties of an instance by class index
%   val_ = rGet(class_name, varargin)
%
%   rGet calls the overloaded get method for the class specified by the
%   string class_name.  If varargin is empty, rGet will return a struc
%   containing the all the property values of all instances of class_name.
%
%   If varargin contains an index or array of indices, rGet will return a
%   struct containing all the property values for the specified instances
%   of class_name.
%
%   If varargin contains an index followed by a string, rGet will return
%   the value of the specified property for the specified instance of
%   class_name.  If the index is the empty [] or no index is provided, rGet
%   uses instance 1.  If an array of indices is provided, an overloaded get
%   method may use only the first index provided.
%
%   The following demonstates each mode of rGet.
%
%   % create five instances of the dXtarget class
%   rInit('debug');
%   rAdd('dXtarget', 5, 'color', {1,2,3,4,5});
%
%   % get the all property values of all instances
%   %   and show all the color values.
%   allDots = rGet('dXtarget');
%   [allDots.color]
%
%   % get all property values for selected instances
%   oddDots = rGet('dXtarget', [1,3,5]);
%   [oddDots.color]
%
%   % three ways to get the color of the first target instnace
%   rGet('dXtarget', 'color');
%   rGet('dXtarget', 1, 'color');
%   rGet('dXtarget', [], 'color')
%
%   % two ways to get the color of the second dots instance
%   rGet('dXtarget', 2, 'color');
%   rGet('dXtarget', 2:5, 'color')

%   See also rInit, dXtarget, rGetTaskByname, rSet

% Copyright 2005 by Joshua I. Gold
%  University of Pennsylvania

global ROOT_STRUCT

% possible check
if nargin < 1 || isempty(class_name) || ~any(strcmp(class_name, ROOT_STRUCT.classes.names))
    val_ = nan;
    return
end

if nargin == 1

    % return array of structs of all objects of the given class type
    val_ = struct(ROOT_STRUCT.(class_name));

    % deencapsulate dXremote object fields
    if isa(ROOT_STRUCT.(class_name), 'dXremote')
        val_ = [val_.fields];
    end

elseif nargin == 2

    if ischar(varargin{1})

        % use index == 1
        val_ = get(ROOT_STRUCT.(class_name)(1), varargin{1});

    else

        % return array of structs of objects of given indices
        val_ = struct(ROOT_STRUCT.(class_name)(varargin{1}));

        % deencapsulate dXremote object fields
        if isa(ROOT_STRUCT.(class_name)(varargin{1}), 'dXremote')
            val_ = [val_.fields];
        end
    end

else % if nargin == 3 && ~isempty(property)

    if isempty(varargin{1})

        % call class-specific get method for object 1
        val_ = get(ROOT_STRUCT.(class_name)(1), varargin{2});

    else
        % call class-specific get method for given object
        val_ = get(ROOT_STRUCT.(class_name)(varargin{1}), varargin{2});
    end
end
