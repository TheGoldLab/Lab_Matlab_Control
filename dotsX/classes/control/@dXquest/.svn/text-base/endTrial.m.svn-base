function q_ = endTrial(q_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXquest: do computations between trials
%   q_ = endTrial(q_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% end of trial method for class dXquest. Called
%-% automatically at the end of a statelist/loop (i.e. a trial)
%-%
%-% ensemble of Quest update their threshold estimates based on the last
%-% trial (if good) and pick a new stimulus intensity, which is near some
%-% threshold of interest, or a blank stimulus, for the next trial
%-%
%-% Arguments:
%-%   q_               ... array of dXquest objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%-%
%-% Returns:
%-%   q_               ... updated array of dXquest objects
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXquest

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania
global ROOT_STRUCT

%disp(sprintf('quest end trial: practiceCount=%d, practiceTrials=%d, practiceValue=%d, Value=%d',...
%    q_(1).practiceTrialCount, q_(1).practiceTrials, q_(1).practiceValue, q_(1).value))

%% Loop through the objects, checking for overrides from previous trial
%
for qq = 1:length(q_)
    
    if q_(qq).overrideFlag == false 
        
        % no override, update goodTrialCount
        q_(qq).goodTrialCount = q_(qq).goodTrialCount + goodTrialFlag;

        % check for practice condition
    elseif q_(qq).goodTrialCount == 0 && q_(qq).practiceTrials > 0

        if q_(qq).practiceTrialCount == -1

            % yes, first time through
            q_(qq).overrideStorage    = [q_(qq).value q_(qq).dBvalue];
            q_(qq).value              = q_(qq).practiceValue;
            [q_, q_(qq).dBvalue]      = stim2dB(q_(qq), q_(qq).value);
            q_(qq).practiceTrialCount = 0;
 
        elseif isempty(q_(qq).overrideStorage)
            
            q_(qq).goodTrialCount = q_(qq).goodTrialCount + goodTrialFlag;
            q_(qq).overrideFlag   = false;
            
        elseif goodTrialFlag

            if q_(qq).practiceTrialCount < q_(qq).practiceTrials - 1

                q_(qq).practiceTrialCount = q_(qq).practiceTrialCount + 1;
            else

                % no, end of practice, so restore
                q_(qq).value           = q_(qq).overrideStorage(1);
                q_(qq).dBvalue         = q_(qq).overrideStorage(2);
                q_(qq).overrideStorage = [];
            end
        end     
    else
        
        % no practice, re-set override flag
        q_(qq).overrideFlag = false;        
    end
end

% possibly ignore some Quests
goOn = ~[q_.overrideFlag] & ([q_.doEndTrial] & ([q_.goPastConvergence] | isnan([q_.convergedAfter])));
if any(goOn)

    trialOrder = rGetTaskByName(ROOT_STRUCT.groups.name, 'trialOrder');
    if isempty(trialOrder)
        % hells no
        return
    end

    switch trialOrder

        case {'block', 'random', 'staircase'}

            % go on!
            qOn      = q_(goOn);
            num_vars = length(qOn);

            if goodTrialFlag

                for qq = 1:num_vars

                    % remember previous value
                    qOn(qq).previousValue   = qOn(qq).value;
                    qOn(qq).previousValuedB = qOn(qq).dBvalue;

                    % check for a correct response
                    if  any(strcmp(statelistOutcome(:,1), 'correct'))

                        % multiply pdf by shifted success function
                        %   success function generated on the fly
                        qOn(qq).pdfPost = qOn(qq).pdfPost .* ...
                            feval(qOn(qq).psycFunction, ...
                            qOn(qq).dBvalue-qOn(qq).dBDomain, ...
                            qOn(qq).psychParams);

                        resp = true;

                    else %if any(strcmp(statelistOutcome(:,1), 'incorrect'))

                        % multiply pdf by shifted failure function
                        %   failure function generated on the fly
                        qOn(qq).pdfPost = qOn(qq).pdfPost .* ...
                            (1-feval(qOn(qq).psycFunction, ...
                            qOn(qq).dBvalue-qOn(qq).dBDomain, ...
                            qOn(qq).psychParams));

                        resp = false;
                    end
                    
                    % maintain the posterior pdf--divide out the guess
                    qOn(qq).pdfLike = qOn(qq).pdfPost ./ qOn(qq).pdfPrior;

                    if qOn(qq).showPlot
                        % show the placement and outcome of the last trial
                        p = feval(qOn(qq).psycFunction, ...
                            qOn(qq).previousValuedB, ...
                            qOn(qq).psychParams);
                        line(qOn(qq).previousValuedB, p, ...
                            'Marker', '*', ...
                            'Color', [~resp, resp, 0], ...
                            'Parent', subplot(2,1,1));
                    end

                    % pdf will shrink forever unless normalized
                    if qOn(qq).pdfNorm
                        qOn(qq).pdfPost = ...
                            qOn(qq).pdfPost ./ sum(qOn(qq).pdfPost);
                        qOn(qq).pdfLike = ...
                            qOn(qq).pdfLike./sum(qOn(qq).pdfLike);
                    end

                    % get posterior estimate and next trial placement
                    switch qOn(qq).estimateType
                        case 'mean'
                            % mean as domain values weighted by pdf
                            qOn(qq).dBvalue = ...
                                sum(qOn(qq).dBDomain .* qOn(qq).pdfPost);

                            qOn(qq).estimateLikedB = ...
                                sum(qOn(qq).dBDomain .* qOn(qq).pdfLike);

                        case 'mode'

                            % mode is simply the value at max of the pdf
                            [m, ii] = max(qOn(qq).pdfPost);
                            qOn(qq).dBvalue = qOn(qq).dBDomain(ii);

                            [m, ii] = max(qOn(qq).pdfPrior);
                            qOn(qq).estimateLikedB = qOn(qq).dBDomain(ii);

                        case 'quantile'

                            % get a quantile from the cdf
                            cdf = cumsum(qOn(qq).pdfPost);
                            qi = find(cdf >= qOn(qq).estimateQuantile, 1);
                            qOn(qq).dBvalue = qOn(qq).dBDomain(qi);

                            cdf = cumsum(qOn(qq).pdfLike);
                            qi = find(cdf >= qOn(qq).estimateQuantile, 1);
                            qOn(qq).estimateLikedB = qOn(qq).dBDomain(qi);

                        otherwise
                            qOn(qq).dBvalue = nan;
                    end

                    % get stimulus unit value from posterior estimate dB value
                    %   and same for likelihood estimate
                    [qOn(qq), qOn(qq).value] = ...
                        dB2Stim(qOn(qq), qOn(qq).dBvalue);
                    [qOn(qq), qOn(qq).estimateLike] = ...
                        dB2Stim(qOn(qq), qOn(qq).estimateLikedB);

                    if qOn(qq).showPlot
                        % show the latest threshold pdf
                        if ~isempty(qOn(qq).plotStuff) ...
                                && all(ishandle(qOn(qq).plotStuff))
                            delete(qOn(qq).plotStuff);
                        end
                        l = line(qOn(qq).dBDomain, qOn(qq).pdfPost, ...
                            'Parent', subplot(2,1,2));
                        t = text(qOn(qq).dBvalue, max(qOn(qq).pdfPost), ...
                            sprintf('%.2f', qOn(qq).value), ...
                            'Parent', subplot(2,1,2));

                        qOn(qq).plotStuff = [l, t];
                    end

                    % check for any converged threshold estimates
                    %   get confidence interval bounds from chi-square
                    %   see Watson and Pelli, "QUEST...", 1983 p116.
                    if isnan(qOn(qq).convergedAfter)

                        % chi-square statistic at CI bounds
                        df = 1;
                        chistat = .5*chi2inv(qOn(qq).CIsignif,df);

                        % need pdf normalized, even if qOn(qq).pdfNorm==false
                        pdf = qOn(qq).pdfLike/sum(qOn(qq).pdfLike);

                        % log likelihood ratios under posterior pdf
                        [m,ii] = max(pdf);
                        llr = log(pdf(ii)) - log(pdf);

                        % where does pfd cross the CI bounds?
                        lowbi = find(llr<=chistat, 1, 'first');
                        highbi = find(llr<=chistat, 1, 'last');
                        qOn(qq).CIdB = qOn(qq).dBDomain([lowbi, highbi]);

                        if qOn(qq).showPlot
                            % illustrate confidence interval
                            l = line(qOn(qq).dBDomain([lowbi, highbi]), ...
                                qOn(qq).pdfPost([lowbi, highbi]), ...
                                'Parent', subplot(2,1,2));

                            % illustrate criterion
                            t = line([0 qOn(qq).CIcritdB] + qOn(qq).dBDomain(lowbi), ...
                                qOn(qq).pdfPost([lowbi,lowbi]), ...
                                'Color', [1 0 0], 'Parent', subplot(2,1,2));

                            qOn(qq).plotStuff = [qOn(qq).plotStuff, l, t];
                        end

                        if diff(qOn(qq).CIdB) <= qOn(qq).CIcritdB
                            % Converged.  After how many trials?
                            qOn(qq).convergedAfter = qOn(qq).goodTrialCount;
                            % rGetTaskByName(ROOT_STRUCT.groups.name, 'goodTrials');
                        end
                    end
                end
                
                % after updating, check if all quests converged
                if ~any([qOn.goPastConvergence] | isnan([qOn.convergedAfter]))

                    % mark the current dXtask as finished
                    rSetTaskByName(ROOT_STRUCT.groups.name, 'isAvailable', false);

                    % don't pick a new stimulus value, below
                    [q_(goOn)] = qOn;
                    return
                end
            end % if goodTrialFlag

            % showing blank trials?
            doBlanks = ~isempty(qOn(1).blankStim) && ~isnan(qOn(1).blankStim);

            % pick a Quest and get a new stimulus (or blank)
            qq = num_vars - floor(rand(1)*(num_vars + doBlanks));
            if ~qq
                % blank trial (min allowable intensity)
                [qOn.value] = deal(qOn(1).blankStim);
            else

                % possibly discretize stim parameter
                if ~isempty(qOn(qq).stimValues)

                    % find the element of 'values' closest to 'value'
                    [v,ii] = min(abs(qOn(qq).stimValues - qOn(qq).value));
                    val    = qOn(qq).stimValues(ii(1));
                    dBval  = qOn(qq).dBvalues(ii(1));
                else
                    val = qOn(qq).value;
                    [qOn(qq), dBval] = stim2dB(qOn(qq), val);
                end

                % distribute the value to each quest
                [qOn.value]   = deal(val);
                [qOn.dBvalue] = deal(dBval);
            end
            
            % check for overrides
            if any([q_.overrideProbability] > 0)
                for qq = find(rand(1,length(q_)) < [q_.overrideProbability])
                    q_(qq).overrideStorage = [q_(qq).value q_(qq).dBvalue];
                    q_(qq).overrideFlag    = true;
                    q_(qq).value           = q_(qq).overrideValue;
                    [q_, q_.dBvalue]       = stim2dB(q_, q_.value);                    
                end
            end
            
            % remember these things that have happened here
            [q_(goOn)] = qOn;

        case 'repeat'

            % don't change anything.
            % might bomb if 1st trial tries to repeat the previous, which DNE
    end
end

if any([q_.showPlot])
    drawnow
end
