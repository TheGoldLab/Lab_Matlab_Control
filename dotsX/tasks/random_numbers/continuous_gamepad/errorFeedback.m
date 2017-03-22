function feedback = errorFeedback(t)
% generate a string which shows error on a random numbers task

% copyright 2006 Benjamin Heasly
%   University of Pennsylvania

global FIRA
if ~isempty(FIRA) && isfield(FIRA, 'ecodes')

    trialNum=FIRA.ecodes.data(1:end, strcmp(FIRA.ecodes.name, 'trial_num'));
    if trialNum(end)==200 || trialNum(end)==1200  % This is sloppy these are block length in visible and hidden change conditions
    
        a=rGet('dXdistr', 1, 'blockIndex')
        block=0
        for i=1:length(FIRA.distrData)-1
            if trialNum(i)==0 || trialNum(i)==1 & i==1 || (trialNum(i)==1 & trialNum(i-1)>1)
                block=block+1
            end
            param(i)=FIRA.distrData{i}(block).args{1};
            stdev(i)=FIRA.distrData{i}(block).args{2};
        end

        % feedback for continuous numbers tasks!!!!
        if ~any(strmatch('rewTarget', FIRA.ecodes.name))
        
    


        eEstimate = strcmp(FIRA.ecodes.name, 'estimate');
        est = FIRA.ecodes.data(1:end-1,eEstimate);
        name = rGet('dXdistr', 1, 'name');
        val = FIRA.ecodes.data(1:end-1, strcmp(FIRA.ecodes.name, 'random_number_value'))
        %% Subject mean absolute error
        errMean = nanmean(abs(est-val))
        %% optimal mean absolute error
        perPicks= [150 param(1) param(1:end-2)]'
        perMean = nanmean(abs(perPicks-val))
        %% last number mean absolute error
        badPicks= [150 val(1:end-1)']'
        badMean = nanmean(abs(badPicks-val))

        CWrecord = (perMean+badMean)./2
        gold   = (perMean.*2+badMean.*1)./3
        silver = (perMean.*1+badMean.*2)./3
        bronze = badMean    
        
        if errMean < 22
            hint = ' Great job!';
        else
            hint = '';
        end

        feedback = sprintf('Your average error was %.1f. Gold ($15) = %.1f, Silver ($12) = %.1f, Bronze ($10) = %.1f', ...
            errMean, gold, silver, bronze);

        %% feedback for monkBelief task!!!!!!
        elseif any(strmatch('rewTarget', FIRA.ecodes.name))   
          rewTarg=FIRA.ecodes.data(:,strmatch('rewTarget', FIRA.ecodes.name))
          subPick=FIRA.ecodes.data(:,strmatch('subPick', FIRA.ecodes.name))
          bestPick=param./ (360./(length(rGet('dXtarget'))-2))  +1
          
          bestCorr=nanmean(bestPick'==rewTarg(1:length(bestPick))).*100
          corr=nanmean(subPick==rewTarg).*100
          badCorr =nanmean(rewTarg(1:end-1)==rewTarg(2:end)).*100
        
          gold   = (bestCorr.*1.5+badCorr.*1.5)./3
          silver = (bestCorr.*1+badCorr.*2)./3
          bronze = badCorr
        
          feedback = sprintf('Your got %.1f percent correct. Gold ($15) = %.1f, Silver ($12) = %.1f, Bronze ($10) = %.1f', ...
          corr, gold, silver, bronze);

        end
          
          
          
    else
        feedback = '';

    end
end