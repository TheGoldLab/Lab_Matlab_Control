function feedback = readoutFeedback(dXp)
% generate a string which previews the upcoming task
%
%   Give a heads up to the subject.
%
%   feedback = readoutFeedback(dXp)

% copyright 2006 Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

if dXp.repeatAllTasks < 0

    feedback = 'All done.';

else

    switch rGet('dXtask', dXp.taski, 'name')

        % fine discrimination
        case 'Readout'

            feedback = 'Pick green or red.';

        otherwise
            feedback = 'Next: Unknown task!';
    end
end