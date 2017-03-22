function tcs_ = endTrial(tcs_, goodTrialFlag, statelistOutcome)
%endTrial method for class dXtc: do computations between trials
%   tcs_ = endTrial(tcs_, goodTrialFlag, statelistOutcome)
%
%   EndTrial methods allow DotsX classes to make computations with data
%   from the entire previous trial, or get ready for the next trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% end of trial method for class dXtc (tuning curve). Called
%-% automatically at the end of a statelist/loop (trial)
%-%
%-% cases on trialOrder, which can be set with dXgui, to setup next trial.
%-%
%-% Arguments:
%-%   tcs_             ... array of dXtc objects
%-%   goodTrialFlag    ... determined by statelist/loop, whether
%-%                           it was a good trial
%-%   statelistOutcome ... cell array created by statelist/loop
%-%
%-% Returns:
%-%   tcs_             ... updated array of dXtc objects
%----------Special comments-----------------------------------------------
%
%   See also endTrial dXtc

% Copyright 2005-2007 by Joshua I. Gold and Benjamin Heasly
%   University of Pennsylvania

% remember previous values
[tcs_.previousValue] = deal(tcs_.value);

global ROOT_STRUCT
switch rGetTaskByName(ROOT_STRUCT.groups.name, 'trialOrder')

    case {'block', 'random'}
        
        tcs_(1).index;
        tcs_(1).indices;
        if tcs_(1).index < length(tcs_(1).indices)

            if goodTrialFlag

                % After a good trial, increment index
                [tcs_.index] = deal(tcs_(1).index + 1);

            elseif strcmp(tcs_(1).indicesOrder, 'random')

                % after a bad trial in random mode,
                %   shuffle remaining indices
                tcs_(1).indices(tcs_(1).index:end) = ...
                    tcs_(1).indices(tcs_(1).index-1+randperm(end+1-tcs_(1).index));

                % apply to all instances
                if length(tcs_) > 1
                    [tcs_.indices] = deal(tcs_(1).indices);
                end
            end

            % pick the next value with new index or indices
            %   (redundant if bad trial in 'block' mode)
            tunCurv = tcs_(1).tc;
            valDumb = num2cell(tunCurv(tcs_(1).indices(tcs_(1).index), :));
            [tcs_.value] = deal(valDumb{:});

        elseif goodTrialFlag
            % reached the end of all tuning curve blocks--done
            rSetTaskByName(ROOT_STRUCT.groups.name, 'isAvailable', false);
        end

    case 'staircase'

        % do something clever with statelistOutcome...
        disp('there is no stair')

    case 'repeat'

        % Don't change values and don't increment index.
        %   Do anything at all???
end