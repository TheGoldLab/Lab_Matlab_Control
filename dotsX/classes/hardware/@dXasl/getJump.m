function [a_, ret_, time_] = getJump(a_);
% compare collected data to input-output mappings for a jumpstate

% basic sanity check
if ~a_.active || isempty(a_.values) || a_.recentVal > size(a_.values, 1);
    ret_ = a_.default;
    time_ = [];
    return
end

% return 'other' value if no match found
ret_  = a_.other;
time_ = [];

% if eye was IN a checkList rectangle for all returned datapoints,
% return the mapped jump state.  Otherwise, return 'other' jump state


recentVals = a_.values(a_.recentVal:end, :);
for ii = 1:size(a_.checkList,1)

    cl = a_.checkList(ii,:);%[x,y,w,h,io,nt] if rectangle,   [x, y, rad] if circle


   if a_.checkShape==0                                   % MN 8/16/09
        % WHEN was eye pos IN the rectangle?
        io = recentVals(:,2) >= cl(1) ...
            & recentVals(:,3) >= cl(2) ...
            & recentVals(:,2) <= cl(1) + cl(3) ...
            & recentVals(:,3) <= cl(2) + cl(4);
    elseif a_.checkShape==1

        % WHEN was eye pos IN the circle? 
        io = recentVals(:,2) >= cl(1)-cl(3) ...
             & recentVals(:,2) <= cl(1) + cl(3) ...
             & recentVals(:,3) <= cl(2) + sqrt(cl(3).^2 - (recentVals(:,2)-cl(1)).^2)...
             & recentVals(:,3) >= cl(2) -sqrt(cl(3).^2  - (recentVals(:,2)-cl(1)).^2);
     
    end

% how many times did eye pos transition in or out?
trans = logical(diff(io));
nt = sum(trans);

if io(end) == cl(5) && nt <= cl(6)
    % correct final position and passable number of transitions
    ret_  = a_.checkRet{ii};

    if nt
        time_ = recentVals(find(trans, 1, 'last'),4)/a_.freq;
    else
        time_ = recentVals(end,4)/a_.freq;
    end
    return
end
end
