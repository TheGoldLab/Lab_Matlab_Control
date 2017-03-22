function fc_ = set(fc_, varargin)
%set method for class dXfunctionCaller: specify property values and recompute dependencies
%   fc_ = set(fc_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of dXfunctionCaller object(s).
%----------Special comments-----------------------------------------------
%
%   See also set dXfunctionCaller

% Copyright 2006 by Benjamin Heasly at University of Pennsylvania

% set the fields, one at a time...

num_objects = length(fc_);

if num_objects == 1

    % for one object, one-to-one setting
    for i = 1:2:nargin-1
        fc_.(varargin{i}) = varargin{i+1};
    end
else

    % for many objects, cell indicates one val for each obj
    %   would need double cell for fc_(i).args
    for i = 1:2:nargin-1
        if iscell(varargin{i+1})
            [fc_.(varargin{i})] = deal(varargin{i+1}{:});
        else
            [fc_.(varargin{i})] = deal(varargin{i+1});
        end
    end
end


for ii = 1:num_objects

    % force indices into integers.
    %   esp. useful for taking keyboard strings as numbers
    if ischar(fc_(ii).indices)
        fc_(ii).indices = round(str2double(fc_(ii).indices));
    end

    % classify the function call
    if isempty(fc_(ii).function)

        % no function at all
        fc_(ii).functionType = 0;

    else

        if isempty(fc_(ii).class)

            % some arbitrary function
            fc_(ii).functionType = 1;

        else

            % probably some rStarRunner function
            if isempty(fc_(ii).indices)

                % unspecified indices
                fc_(ii).functionType = 2;

            else

                % full form with class, inds, args
                fc_(ii).functionType = 3;

            end
        end
    end
end