function compareEstimate(earnLine, conf)

% read new number and compare to subject's estimate
rnd = 1;
newNum = rGet('dXtext', rnd, 'string');
if ischar(newNum)
    newNum = sscanf(newNum, '%f', 1);
end
est = 2;
estNum = rGet('dXtext', est, 'string');
if ischar(estNum)
    estNum = sscanf(estNum, '%f', 1);
end
errNum = abs(newNum-estNum);


disp(errNum)

% set error text and line
err = 3;
rSet('dXtext', err, 'string', errNum);
rSet('dXline', err, ...
    'x1', rGet('dXline', rnd, 'x2'), ...
    'x2', rGet('dXline', est, 'x2'));


if isempty(conf)

    % don't update points or move the line in the pupil task--yet.
    if earnLine ~= 4 & earnLine ~= 3  
        
        a=rGet('dXdistr', 1, 'blockIndex');
        b=rGet('dXdistr', 1, 'distributions');
        c= b(a).args;
        c=c{2};      
        % keep track of total points
        %   scale to make reasonable max earning expectation $15
        newPoints = rGet('dXtask', 1, 'userData') + max([(2-((errNum)./c).^2), -6]);
        rSet('dXtask', 1, 'userData', max([newPoints 0]));

        % grow the earnings line to match total points
        maxPoints = 800.*15./20;
        maxDeg = 30;
        newDeg = (newPoints*maxDeg/maxPoints)-maxDeg/2;
        rSet('dXline', earnLine, 'x2', newDeg);
   
  
    end

    %if errNum == 0
    %    rPlay('dXsound', 2);
    %end

elseif conf==1
    a=rGet('dXdistr', 1, 'blockIndex')
    b=rGet('dXdistr', 1, 'distributions')
    c= b(a).args
    c=c{2}



    con = rGet('dXtext', 11, 'string');
    if ischar(con)
        con = sscanf(con, '%f', 1);
    end


    if abs(con)>=errNum

        if abs(con) > 200
            newPoints=rGet('dXtask', 1, 'userData')
        else

            %scale earnings
            maxPoints = 800*600;
            maxDeg = 30;
            % generate probability of getting it right for all confidences
            Poss=1:400;
            Mean=200;
            stDev=c;

            stuff=normcdf(Poss, Mean, stDev);
            stuffy=stuff(Mean.*2:-1:Mean+1);
            stuffg=stuff(1:Mean);
            k(length(stuffy):-1:1)=stuffy-stuffg;

            cost=normpdf(1:Mean, find(k>=.85, 1), stDev);
            cost=maxPoints.*cost./max(cost)./800;
            pay=cost./k;


            % assign points
            newPoints = rGet('dXtask', 1, 'userData') + pay(abs(con));
        end
        rSet('dXtask', 1, 'userData', max([newPoints 0]));

        % show earnings on line
        newDeg = (newPoints*maxDeg/maxPoints)-maxDeg/2;
        rSet('dXline', earnLine, 'x2', newDeg);

        %indicate successful trials
        rPlay('dXsound', 2);
    end
end

if  earnLine==3
    rSet('dXtext', est, 'visible', false)
    rSet('dXtext', rnd, 'visible', true)
    rGraphicsDraw
end

