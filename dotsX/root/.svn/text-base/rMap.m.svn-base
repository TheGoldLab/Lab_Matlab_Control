function rMap(fromPtr, toPtr)
%Copy a property value from one object to another
%   rMap(fromPtr, toPtr)
%
%   rMap copies any property value from one object and assigns that value
%   to any property field of another object.  fromPtr and toPtr are cell
%   arrays which each specify a unique object and property.  They have the
%   form {class_name, index, property_name}.
%
%   fromPtr and toPtr can be n-by-3 cell arrays.  The object property
%   specified on each row of fromPtr will be copied to the object property
%   specified on each corresponding row of toPtr.
%
%   The following creates several unlike objects and aligns them
%   horizontally using rMap.
%
%   % show some unlike objects
%   rInit('local');
%   rAdd('dXdots', 1, 'x', -8, 'y', -7, 'diameter', 3);
%   rAdd('dXtext', 1, 'x', 5, 'y', -3, 'string', 'align em');
%   rAdd('dXtarget', 1);
%   rGraphicsShow;
%   rGraphicsDraw(1000);
%
%   % align objects horizontally
%   from = repmat({'dXtarget', 1, 'y'}, 2, 1);
%   to = {'dXdots', 1, 'y'; 'dXtext', 1, 'y'};
%   rMap(from, to);
%   rGraphicsDraw(2000);
%   rDone;
%
%   See also rInit rCallFunction

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania
    
global ROOT_STRUCT

if size(fromPtr, 1) == 1

    ROOT_STRUCT.(toPtr{1})(toPtr{2}) = ...
        set(ROOT_STRUCT.(toPtr{1})(toPtr{2}), ...
        toPtr{3}, get(ROOT_STRUCT.(fromPtr{1})(fromPtr{2}), fromPtr{3}));

else

    for ii = 1:size(fromPtr, 1)

        ROOT_STRUCT.(toPtr{ii, 1})(toPtr{ii, 2}) = ...
            set(ROOT_STRUCT.(toPtr{ii, 1})(toPtr{ii, 2}), ...
            toPtr{ii, 3}, get(ROOT_STRUCT.(fromPtr{ii, 1})(fromPtr{ii, 2}), ...
            fromPtr{ii, 3}));
    end
end
