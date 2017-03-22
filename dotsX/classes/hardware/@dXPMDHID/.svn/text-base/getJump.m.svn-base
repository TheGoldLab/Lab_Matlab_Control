function [p_, ret_, time_] = getJump(p_);
% compare collected data to input-output mappings for a jumpstate

% basic sanity check
if ~p_.active || isempty(p_.values) || p_.recentVal > size(p_.values, 1);
    ret_ = p_.default;
    time_ = [];
    return
end

% return 'other' value if no match found
ret_  = p_.other;
time_ = [];

% each row of checkList is
%   {n, v, nan} channel value matches v,
%   {n, gt, lt} gt <= channel value <= lt, or
%   {fun, args} waveform analysis callback
hit = false;
recentVals = p_.values(p_.recentVal:end, :);
for ii = 1:size(p_.checkList, 1)

    cl = p_.checkList(ii,:);
    if size(cl,2) == 3

        % look for channel value matches
        if isnan(cl{3})

            % intersect button match with strict value match
            hit = cl{1} == recentVals(:,1) ...
                & cl{2} == recentVals(:,2);
        else

            % intersect button match with value range match
            hit = cl{1} == recentVals(:,1) ...
                & cl{2} <= recentVals(:,2) ...
                & cl{3} >= recentVals(:,2);
        end

        if any(hit)
            % found something in check list,
            %   return corresponding value in retList
            ret_  = p_.checkRet{ii};
            time_ = recentVals(find(hit,1),3);
            return
        end

    elseif size(cl,2) == 2

        % do waveform analysis with callback
        t = feval(cl{1}, recentVals, cl{2}{:});

        if ~isempty(t) && ~isnan(t)
            % found something in check list,
            %   return corresponding value in retList
            ret_  = p_.checkRet{ii};
            time_ = t;
            return
        end
    end
end