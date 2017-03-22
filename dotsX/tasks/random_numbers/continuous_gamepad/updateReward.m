function updateReward(earnLine)

global ROOT_STRUCT

rnd = 1;
est = 2;

% only do reward for good trials
if ~isfield(ROOT_STRUCT, 'badTrialFlag') || ~ROOT_STRUCT.badTrialFlag

    % read new number and compare to subject's estimate
    
    newNum = rGet('dXtext', rnd, 'string');
    if ischar(newNum)
        newNum = sscanf(newNum, '%f', 1);
    end
    
    estNum = rGet('dXtext', est, 'string');
    if ischar(estNum)
        estNum = sscanf(estNum, '%f', 1);
    end
    errNum = abs(newNum-estNum);

    % keep track of total points
    %   scale to make reasonable max earning expectation $15

        a=rGet('dXdistr', 1, 'blockIndex');
        b=rGet('dXdistr', 1, 'distributions');
        c= b(a).args;
        c=c{2};
          

        
        % keep track of total points
        %   scale to make reasonable max earning expectation $15
        newPoints = rGet('dXtask', 1, 'userData') + max([(2-((errNum)./c).^2), -4]);
        rSet('dXtask', 1, 'userData', max([newPoints 0]));

        % grow the earnings line to match total points
        maxPoints = 400.*15./20;
        maxDeg = 30;
        newDeg = (newPoints*maxDeg/maxPoints)-maxDeg/2;
        rSet('dXline', earnLine, 'x2', newDeg);
   

end

% always reset for the next trial
ROOT_STRUCT.badTrialFlag = false;

%disp('reward:')
%disp(rGet('dXtask', 1, 'userData'))

    
if earnLine==3
    rSet('dXtext', rnd, 'visible', false)
    rSet('dXtext', est, 'visible', true)
    rSet('dXline', earnLine, 'visible', false)
    rGraphicsDraw
end