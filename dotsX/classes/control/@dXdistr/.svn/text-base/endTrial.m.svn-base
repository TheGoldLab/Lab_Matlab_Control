function d_ = endTrial(d_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXdistr: do computations between trials
%   d_ = endTrial(d_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% end of trial method for class dXdistr. Called
%-% automatically at the end of a statelist/loop (trial)
%-%
%-% cases on trialOrder, which can be set with dXgui, to setup next trial.
%-%
%-% Arguments:
%-%   d_             ... array of dXdistr objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%-%
%-% Returns:
%-%   d_             ... updated array of dXdistr objects
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXdistr

% Copyright 2005-2007 by Joshua I. Gold and Benjamin Heasly
%   University of Pennsylvania

num_vars = length(d_);
for di = 1:num_vars

    % increment trials only when good
    d_(di).numTrials = d_(di).numTrials + goodTrialFlag
    d_(di).subBlockTrial = d_(di).subBlockTrial + goodTrialFlag;

    % done with this block?
    if d_(di).numTrials >= d_(di).totTrials

        % reset trial count
        d_(di).numTrials = 0;

        % increment block counter
        %   persists through reset() calls
        d_(di).blockIndex = d_(di).blockIndex + 1;

        global ROOT_STRUCT
        rSetTaskByName(ROOT_STRUCT.groups.name, 'isAvailable', false);
    end

    % done with this sub-block?
    if ~isempty(d_(di).subBlockSize) && d_(di).subBlockTrial >= d_(di).subBlockSize

        % reset sub-block count
        d_(di).subBlockTrial = 0;
    end

    % delegate to sub-block function
    if d_(di).subBlockTrial == 0 && ~isempty(d_(di).subBlockMethod)
        d_(di) = feval(d_(di).subBlockMethod, d_(di));
    end

    % pick a metadistribution for next trial
    mi = mod(d_(di).blockIndex-1, length(d_(di).metaD))+1;
    m = d_(di).metaD(mi);

    % increment usage count
    m.count = m.count + goodTrialFlag;

    % remember the change
    d_(di).metaD(mi) = m;

    % p can be constant or an arbitrary array
    %   can get stuck at the last element of m.p
    if ~isscalar(m.p)
        pval = m.p(min(m.count,length(m.p)));
    else
        pval = m.p;
    end

    % pick a distribution for next trial
    if binornd(1,pval)
        d = d_(di).distributions(m.first);
    else
        d = d_(di).distributions(m.second);
    end

    % pick a new nextValue
    %   always a positive integer
    d_(di).value = d_(di).nextValue;
    d_(di).nextValue = abs(round(feval(d.func, d.args{:})*d.gain + d.offset));

    %disp(d_(di).value)
end