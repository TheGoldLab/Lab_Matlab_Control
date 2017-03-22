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


        case {'ModalityFVTEye', 'ModalityRTEye'}
            feedback = 'Next: respond by looking at the targets.';

        case {'ModalityFVTLever', 'ModalityRTLever'}
            feedback = 'Next: respond by pulling the levers.';

        otherwise
            feedback = 'Next: Unknown task!';
    end
end