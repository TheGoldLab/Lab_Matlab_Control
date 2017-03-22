function eStr = fineEarnings(varargin)
% calculate earnings for the fine discrimination task
%
%   eStr = fineEarnings(varargin)
%
%   eStr is a string giving the the earnings for the task.
%
%   Let e be earnings in pennies, p be some number of pennies, c the number
%   of correct responses, and g the number of good trials.  Then
%   e = 2pc - p(g-c).  2p for correct, -p for incorrect.
%
%   There are 520 trials in a normal session of the fine discrimination
%   task.  At worst, people should average 50% correct.  So with p=2, e can
%   take a range from about 520 up to 2040--people should make about
%   $5-$20.

% 2008 by Benjamin Heasly at University of Pennsylvania

global FIRA

if ~isempty(FIRA) && isfield(FIRA, 'ecodes')

    eCorrect = strcmp(FIRA.ecodes.name, 'correct');
    if ~any(eCorrect)
        correct = 0;
    else
        correct = ~isnan(FIRA.ecodes.data(:,eCorrect));
    end

    eGood = strcmp(FIRA.ecodes.name, 'good_trial');
    good = FIRA.ecodes.data(:,eGood);

    p = 2;
    e = p*(3*sum(correct) - sum(good));
    eStr = sprintf('You get %d cents!', e);
else
    eStr = '0';
end