%% feedback for confidence task

function feedback = errorFeedback(t)
% generate a string which shows error on a random numbers task

% copyright 2008 Matt Nassar
%   University of Pennsylvania



global FIRA
if ~isempty(FIRA) && isfield(FIRA, 'ecodes')

    trialNum=FIRA.ecodes.data(1:end, strcmp(FIRA.ecodes.name, 'trial_num'));
    if trialNum(end)==200 || trialNum(end)==1000  % This is sloppy these are block length in visible and hidden change conditions


        a=rGet('dXdistr', 1, 'blockIndex')

        block=0
        for i=1:length(FIRA.distrData)-1
            if trialNum(i)==0 || (trialNum(i)==1 & ~(i>1 && trialNum(i-1)==1))
                block=block+1
            end
            param(i)=FIRA.distrData{i}(block).args{1};
            stdev(i)=FIRA.distrData{i}(block).args{2};
        end

        val = FIRA.ecodes.data(1:end-1, strcmp(FIRA.ecodes.name, 'random_number_value'))


        %val=round(normrnd(150, 30, 800,1))
        %gMe=repmat(150, 800,1)
        %gCon=round(repmat(30.*norminv(.925, 0,1), 800,1))

        gMe=[150 param(1) param(1:end-2)]'
        gCon=round(stdev.*norminv(.925, 0, 1))'
        bMe=[150 val(1:end-1)']'
        bCon=abs(val(2:end)-val(1:end-1))+1
        bCon(end+1)=bCon(end)

        gWin=val>=gMe-gCon & val<=gMe+gCon;
        bWin=val>=bMe-bCon & val<=bMe+bCon;



        %scale earnings
        maxPoints = 800*600;
        maxDeg = 30;
        % generate probability of getting it right for all confidences
        Poss=1:400;
        Mean=200;

        bPoints=0;
        gPoints=0 ;
        for i = 1:length(val)
            stDev=stdev(i);
            stuff=normcdf(Poss, Mean, stDev);
            stuffy=stuff(Mean.*2:-1:Mean+1);
            stuffg=stuff(1:Mean);
            k(length(stuffy):-1:1)=stuffy-stuffg;
            cost=normpdf(1:Mean, find(k>=.85, 1), stDev);
            cost=maxPoints.*cost./max(cost)./800;
            pay=cost./k;

            bPoints = bPoints+pay(bCon(i)).*bWin(i);
            gPoints = gPoints+pay(gCon(i)).*gWin(i);
        end
        gPoints=gPoints./100
        bPoints=bPoints./100
        subPoints=rGet('dXtask', 1, 'userData')./100



        gold   = round((gPoints.*2+bPoints.*1)./3)
        silver = round((gPoints.*1+bPoints.*2)./3)
        bronze = round(bPoints)


        if subPoints > gold
            hint = ' Great job!';
        else
            hint = '';
        end

        feedback = sprintf('you scored %.0f points. Gold ($15) = %.1f, Silver ($12) = %.1f, Bronze ($10) = %.1f', ...
            subPoints, gold, silver, bronze);

    else
        feedback = '';

    end
end