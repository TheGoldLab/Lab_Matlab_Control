function num_ = getRandomNumber(spec)
% function num_ = getRandomNumber(spec)
%
% Gets a random number from cell array
%  'specifier'

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

if isscalar(spec)

    % convert ms to s
    num_ = spec*0.001;
    return
end

nargs = size(spec, 2) - 1;

switch spec{1}

    case 'exp'

        % mean min max
        if nargs == 1
            num_ = exprnd(spec{2});

        elseif nargs == 2
            num_ = exprnd(spec{2}) + spec{3};

        elseif nargs >= 3
            num_ = exprnd(spec{2}) + spec{3};
            num_(num_ > spec{4}) = spec{4};
        end

    case 'uniform'

        % min max
        if nargs == 1
            num_ = spec{2};

        elseif nargs >= 2
            num_ = spec{2} + rand*(spec{3} - spec{2});
        end

    case 'norm'

        % mean std min max
        if nargs == 1
            num_ = normrnd(spec{2}, 1);

        elseif nargs == 2
            num_ = normrnd(spec{2}, spec{3});

        elseif nargs == 3
            num_ = normrnd(spec{2}, spec{3});
            num_(num_ > spec{4}) = spec{4};

        elseif nargs >= 4
            num_ = normrnd(spec{2}, spec{3});
            num_(num_ < spec{4}) = spec{4};
            num_(num_ > spec{5}) = spec{4};
        end

    otherwise
        num_ = nan;
end

% convert from ms to s
num_ = num_*0.001;