function fc_ = call(fc_)
% function fc_ = call(fc_)
%
% call method for class dXfunctionCaller builds and dispaches a function
% call from its property values.
%
% Arguments:
%   fc_ ... array of dXfunctionCaller objects
%
% Returns:
%   fc_ ... the array of objects

% Copyright 2006 by Benjamin Heasly University of Pennsylvania

num_objects = length(fc_);
if ~num_objects

    % get real
    return

elseif  num_objects == 1

    % one instance, avoid loop
    ans = [];
    switch fc_.functionType

        case 1

            % some arbitrary function
            feval(fc_.function, fc_.args{:});

        case 2

            % probably some rStarRunner function
            %   with unspecified indices
            feval(fc_.function, fc_.class, [], fc_.args{:});

        case 3

            % probably some rStarRunner function
            %   in full form with class, inds, args
            feval(fc_.function, fc_.class, fc_.indices, fc_.args{:});
    end

    % capture one output arg
    if ~isempty(ans)
        fc_.ans = ans;
    end
else

    % loop through some instances
    for ii = 1:num_objects
        ans = [];
        switch fc_(ii).functionType

            case 1

                % some arbitrary function
                feval(fc_(ii).function, fc_(ii).args{:});

            case 2

                % probably some rStarRunner function
                %   with unspecified indices
                feval(fc_(ii).function, fc_(ii).class, fc_(ii).args{:});

            case 3

                % probably some rStarRunner function
                %   in full form with class, inds, args
                feval(fc_(ii).function, ...
                    fc_(ii).class, fc_(ii).indices, fc_(ii).args{:});
        end

        % capture one output arg
        if ~isempty(ans)
            fc_(ii).ans = ans;
        end
    end
end