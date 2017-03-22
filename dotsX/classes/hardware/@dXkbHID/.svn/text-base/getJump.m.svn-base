function [kb_, ret_, time_] = getJump(kb_)
% compare collected data to input-output mappings for a jumpstate

% basic sanity check
if ~kb_.active || isempty(kb_.values) || kb_.recentVal > size(kb_.values, 1);
    ret_ = kb_.default;
    time_ = [];
    return
end

ret_ = kb_.other;
time_ = [];
recentVals = kb_.values(kb_.recentVal:end,:);
for ii = 1:size(kb_.checkList, 1)

    % intersect button match with value match
    hit = kb_.checkList(ii,1) == recentVals(:,1) ...
            & kb_.checkList(ii,2) == recentVals(:,2);

    if any(hit)
        ret_ = kb_.checkRet{ii};
        time_ = recentVals(find(hit, 1),3);
        return
    end
end