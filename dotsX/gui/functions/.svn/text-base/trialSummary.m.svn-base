function s = trialSummary(name, num, good, correct, minutes, other)
%
% Handy function to make strings that summarize completed trials (and
% column headers in a dXhistoryGUI). Called from more than one
% class/function and meant for dXtask, dXparadigm, or arbitrary strings, so
% it's not reallt a class method.
%
% In:
%   name    ... string name of a dXtask
%   num     ... number of trials done from that task,
%               or an arbitrary string
%   good    ... number of GOOD trials done from that task,
%               or an arbitrary string
%   correct ... number of CORRECT trials done from that task,
%               or an arbitrary string
%   minutes ... minutes elapsed during current paradigm,
%               or an arbitrary string
%   other   ... an optional aribitrary string
%
%   NB: good, correct, and minutes should be of same type as num
%
% Out:
%   s       ... a nice, consistently formatted string
%               that summarizes data passed in

% 2006 by Benjamin Heasly at University of Pennsylvania


% Fire up the Coverterator4000 and lets crunch those numbers!
if isnumeric(num) && isnumeric(minutes)
    if ~num
        % don't divide by Satan
        correct = sprintf('%3d(%2.1f%%)(%1.1f/min)', correct, 0, 0);
        good = sprintf('%3d(%2.1f%%)(%1.1f/min)', good, 0, 0);
    else
        % correct is % of good, good is % of num
        correct = sprintf('%3d(%2.1f%%)(%1.1f/min)', ...
            correct, 100*correct/max(eps,good), correct/max(eps,minutes));
        good = sprintf('%3d(%2.1f%%)(%1.1f/min)', ...
            good, 100*good/max(eps,num), good/max(eps,minutes));
    end
    num = sprintf('%3d', num);
end

% don't gack if there aint no other
if nargin < 6
    other = '';
end

% names are getting long these days
if length(name) > 13
    name = ['''', name(end-11:end)];
end

% Start with 50 space characters
s = char(32*ones(1,70));

% insert data at consistent columns
s([1:size(name,2), 14:13+size(num,2), 20:19+size(good,2), ...
    41:40+size(correct,2), 62:61+size(other,2)]) = ...
    [name, num, good, correct, other];

% for uicontrol of type listbox, cell is most useful
s = {s};