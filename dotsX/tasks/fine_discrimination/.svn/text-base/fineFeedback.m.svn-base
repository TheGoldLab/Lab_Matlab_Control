function feedback = previewFeedback(dXp)
% generate a string which previews the upcoming task
%
%   This is a hack.  dXtasks probably should hold these strings.  Whatever.
%
%   feedback = previewFeedback(dXp)


% copyright 2006 Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

if dXp.repeatAllTasks < 0

    feedback = 'All done.';

else

    switch rGet('dXtask', dXp.taski, 'name')

        case 'FineDiscrimLever'
            feedback = 'Next: pull "same" (left lever) or "different" (right lever)';

        case 'FineDiscrimEye'
            feedback = 'Next: look at "same" (left) or "different" (right)';
            
        otherwise
            feedback = 'Next: Unknown task!';
    end
end