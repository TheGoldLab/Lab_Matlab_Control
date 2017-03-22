function [g_, ret_, time_] = getJump(g_);
% compare collected data to input-output mappings for a jumpstate

% basic sanity check
if ~g_.active || isempty(g_.values) || g_.recentVal > size(g_.values, 1);
    ret_ = g_.default;
    time_ = [];
    return
end

% return 'other' value if no match found
ret_  = g_.other;
time_ = [];

% each row of checkList is either
%   [n, v, nan] button value matches v, or
%   [n, gt, lt] gt <= button value <= lt
hit = false;
recentVals = g_.values(g_.recentVal:end, :);
for ii = 1:size(g_.checkList, 1)

    cl = g_.checkList(ii,:);
    if isnan(cl(3))

        % intersect button match with strict value match
        hit = cl(1) == recentVals(:,1) ...
            & cl(2) == recentVals(:,2);
    else

        % intersect button match with value range match
        hit = cl(1) == recentVals(:,1) ...
            & cl(2) <= recentVals(:,2) ...
            & cl(3) >= recentVals(:,2);
    end

    if any(hit)
        % found something in check list,
        %   return corresponding value in retList
        ret_  = g_.checkRet{ii};
        time_ = recentVals(find(hit,1),3);
        return
    end
end