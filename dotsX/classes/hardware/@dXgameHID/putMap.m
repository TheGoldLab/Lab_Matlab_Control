function [g_, ret_, time_] = putMap(g_, map);
% change mappings, check against data for a jumpState

% clear auto fields
g_.checkList = [];
g_.checkRet  = {};
g_.default   = [];
g_.other     = [];

% map is a list of {input, output, ...} pairs
% Each row of an input array is a separate entry: [element#, v1, v2]
%   element# is the index of a gamepad element (see g_.HIDElementInfo)
%   For some element event value ve, a hit means v1 <= ve <= v2
%   if v2 is missing or nan, a hit means v1==ve
%   if v1 is missing or nan, a hit means ve==1
% output should be a string state name
for ii = 1:2:length(map) - 1

    if isnumeric(map{ii})

        m = size(map{ii}, 1);
        switch size(map{ii}, 2)

            case 1
                % let v1=1 and v2=nan
                cl = ones(m, 3);
                cl(:,1) = map{ii};
                cl(:,3) = nan;

            case 2
                % let v2=nan
                cl = ones(m, 3);
                cl(:,1:2) = map{ii}(:,1:2);
                cl(:,3) = nan;

            case 3
                % all set
                cl = map{ii};

            otherwise continue
        end

        g_.checkList = cat(1, g_.checkList, cl);
        g_.checkRet = ...
            cat(1, g_.checkRet, repmat(map(ii+1), m, 1));

    elseif ischar(map{ii})
        if strcmp(map{ii}, 'none')
            g_.default = map{ii+1};
        elseif strcmp(map{ii}, 'any')
            g_.other   = map{ii+1};
        end
    end
end

% optional trailing value is boolean for ignore previous hardware values
if mod(length(map), 2) && isscalar(map{end}) && map{end}
    g_.recentVal = size(g_.values, 1) + 1;
end

% check new mappings against existing data
[g_, ret_, time_] = getJump(g_);