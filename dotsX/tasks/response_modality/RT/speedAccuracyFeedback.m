function speedAccuracyFeedback(dXt, varargin)
%Show the subject her speed and accuracy with bars, in the iti.
%
%   set speedAccuracyFeedback as the intertrialFcn of a dXtask, to be
%   called after each trial
%
%   dXline(1) is a green bar for speed
%   dXline(2) is a red bar for accuracy
%
%   Both lines run vertically from -5 to 5 degrees, near the middle of the
%   screen.  speedAccuracyFeedback should adjust the height of the lines.
%
%   Get data from the current FIRA.
%
%   Speed and accuracy shouuld each be calculated over the last few trials,
%   maybe 10-20.  Pick this value below.  If fewer than this number of
%   trials has elapsed, the bars should be tiny or gone.
%
%   Speed is just mean response time.
%
%   Accuracy is a QUEST-like estimate of (coherence) threshold.

% 2008 Benjamin Heasly at University of Pennsylvania
global FIRA ROOT_STRUCT

recentTrials = 15;

lowRT = 100;
highRT = 1500;

if ~isempty(FIRA) && FIRA.header.numTrials >= recentTrials ...
        && ~strcmp(ROOT_STRUCT.groups.name, 'iti')

    % get trial numbers
    eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
    trialNum = FIRA.ecodes.data(:, eTrial);

    % check number of trials
    lastTrial = trialNum(end);

    if lastTrial >= recentTrials
        
        % use only good (i.e. complete) trials
        eGood = strcmp(FIRA.ecodes.name, 'good_trial');
        good = logical(FIRA.ecodes.data(:, eGood));

        % get selection of recent good trials
        selectRecent = ...
            find(trialNum==lastTrial-recentTrials, 1, 'last')+1: ...
            find(trialNum==lastTrial, 1, 'last');
        goodRecent = selectRecent(good(selectRecent));

        % compute speed

        % timing data in 3 columns
        eChoose = strcmp(FIRA.ecodes.name, 'choose');
        eLeft = strcmp(FIRA.ecodes.name, 'left');
        eRight = strcmp(FIRA.ecodes.name, 'right');

        % mean over all columns
        RTs = FIRA.ecodes.data(goodRecent,eChoose|eLeft|eRight);
        meanRT = nanmean((RTs(1:numel(RTs))));

        % compute speed as normalized, negative response time
        speed = max(min(1, (highRT - meanRT) / (highRT - lowRT)),0);

        % compute accuracy

        % get an example quest
        qn = 1;
        qNow = rGet('dXquest', qn);
        
        % divide out recent threshold likelihood
        qdRecent = FIRA.QUESTData{goodRecent(1)+1}(qn);
        likeT = (qNow.pdfLike) ./ (qdRecent.pdfLike);

        % normalize likelihood to unit sum and mean it
        meanT = sum((likeT/sum(likeT)).*qNow.dBDomain);

        accuracy = max(min(1, (qNow.dBDomain(end) - meanT) ...
            / (qNow.dBDomain(end) - qNow.dBDomain(1))),0);

        % find the bottom of these bars
        minY = rGet('dXline', 1, 'y1');

        % set length of bars (0-maxL) from speed and accuracy (0-1)
        maxL = 10;
        rSet('dXline', 1, 'y2', speed*maxL + minY);
        rSet('dXline', 2, 'y2', accuracy*maxL + minY);

        % show all feedback graphics
        rSet('dXline', 1:4, 'visible', true);
        rSet('dXtext', 1:4, 'visible', true);
        rGraphicsDraw;
    end
end