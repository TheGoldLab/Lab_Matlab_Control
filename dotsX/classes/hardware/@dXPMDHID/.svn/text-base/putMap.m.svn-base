function [p_, ret_, time_] = putMap(p_, map);
% change mappings, check against data for a jumpState

% clear auto fields
p_.checkList = {};
p_.checkRet  = {};
p_.default   = [];
p_.other     = [];

% PMD can hit on two kinds of events:
%   -Channel value events, much like gamepad events:
%   {c, v1, v2}
%   for channel event value vc, hit means v1 <= vc <= v2
%   if v2 is missing or nan, hit means vc == v1
%   if v1 is missing or nan, hit means vc == 1
%   -Waveform analysis callback events, using arbitrary functions
%   {fun, args}
%   function must be a function_handle to a function of the form
%   time = fun(values, varargin)
%   where time is an event time (or nan), and values is p_.values
%   args should be a cell array which gets passed to fun as varargin

for ii = 1:2:size(map, 2) - 1

    if isnumeric(map{ii})

        % numeric arguments are c, v1, v2
        m = size(map{ii}, 1);
        switch size(map{ii}, 2)

            case 1
                % let v1=1 and v2=nan
                cl = cell(m, 3);
                cl(:,1) = num2cell(map{:,ii});
                [cl{:,2}] = deal(1);
                [cl{:,3}] = deal(nan);

            case 2
                % let v2=nan
                cl = cell(m, 3);
                cl(:,1:2) = num2cell(map{ii}(:,1:2));
                [cl{:,3}] = deal(nan);

            case 3
                % all set
                cl(:,1:3) = num2cell(map{ii});

            otherwise continue
        end

        p_.checkList = cat(1, p_.checkList, cl);
        p_.checkRet = ...
            cat(1, p_.checkRet, repmat(map(ii+1), m, 1));

    elseif iscell(map{ii}) && isa(map{ii}{1}, 'function_handle')

        % function handle, look for {fun, args}
        if size(map{ii},2) == 2
            cl = map{ii};
        elseif size(map{ii},2) == 1
            cl{2} = {};
            cl(1) = map{ii};
        end
        p_.checkList = cat(1, p_.checkList, cl);
        p_.checkRet = cat(1, p_.checkRet, map(ii+1));

    elseif ischar(map{ii})

        if strcmp(map{ii}, 'none')
            p_.default = map{ii+1};

        elseif strcmp(map{ii}, 'any')
            p_.other   = map{ii+1};
        end
    end
end

% optional trailing value is boolean for ignore previous hardware values
if mod(length(map), 2) && isscalar(map{end}) && map{end}
    p_.recentVal = size(p_.values, 1) + 1;
end

% check new mappings against existing data
[p_, ret_, time_] = getJump(p_);