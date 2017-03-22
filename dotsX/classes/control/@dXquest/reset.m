function q_ = reset(q_, force_reset, varargin)
%reset method for class dXquest: return to virgin state
%   q_ = reset(q_, force_reset, varargin)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Resets dXquest for fresh and clean, clean threshold estimation.
%-%
%----------Special comments-----------------------------------------------
%
%   See also reset dXquest

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

for qq = 1:length(q_)

    % use shorthand
    q = q_(qq);

    % convert range in stim units to dB
    [q, q.dBRange] = stim2dB(q, q.stimRange);

    % get domain of T estimate in dB and stimulus units
    q.dBDomain = q.dBRange(1):q.TGrain:q.dBRange(2);
    [q, q.stimDomain] = dB2Stim(q, q.dBDomain);

    % check for a threshold guess in stimulus units
    if ~isempty(q.guessStim)
        [q, q.T0] = stim2dB(q, q.guessStim);
    end

    % get initial T estimate pdf as a Gaussian over the dB domain
    q.pdfPrior = normpdf(q.dBDomain, q.T0, q.Tstd);
    q.pdfPrior = q.pdfPrior ./ sum(q.pdfPrior);

    % use the prior pdf to place the first trial
    q.pdfPost = q.pdfPrior;
    q.dBvalue = q.T0;
    [q, q.value] = dB2Stim(q, q.dBvalue);

    % convert the constrained list of stimulus values to dB
    [q, q.dBvalues] = stim2dB(q, q.stimValues);

    % reset trial counts
    q.goodTrialCount     = 0;
    q.practiceTrialCount = -1;
    
    % check for practice trials
    if q.practiceTrials > 0
        q.overrideFlag = true;
    end
    
    % save shorthand
    q_(qq) = q;
end

% forget the past
[q_.convergedAfter] = deal(nan);
[q_.previousValue] = deal([]);
[q_.previousValuedB] = deal([]);
[q_.override] = deal([]);

% prepare for first trial with a fake previous trial.  This will:
%   with good_trial = false, skip updating the pdf.
%   Check the starting value against the "values" list or possibly pick a blank trial
q_ = endTrial(q_, false, {});