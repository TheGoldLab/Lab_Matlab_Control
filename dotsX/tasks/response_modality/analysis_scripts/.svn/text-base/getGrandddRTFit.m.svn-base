function [Qs, varQs] = getGrandddRTFit(d, taskID, sessionID)
%Do a ddRT fit over all sessions to get a single Q for each task type
%
%   [Qs, varQs] = getGrandddRTFit(d, taskID)
%
%   d is the structure of data from getCommonDataTypes.
%
%   taskID is the vector of task IDs for all trials, from
%   unifyFIRATaskNames.
%
%   sessionID is the vector of session IDs for all trials, from
%   findFIRASessionsAndBlocks.
%
%   Qs is a 6xN array.  Columns are ddRT parameter values, rows are task
%   IDs.  N is the number of unique task IDs.

% 2008 by Benjamin Heasly at University of Pennsylvania

% ignore the first session of a new epoch, i.e.,
%   the very first session,
%   any session right after a dots change.
ignore = zeros(size(d.good));
for ee = d.epochs
    ignore = ignore | sessionID == ee;
end

tID = unique(taskID);
Qs = zeros(6, max(taskID));
varQs = zeros(6, max(taskID));
for tt = tID'

    select = taskID == tt & d.good & ~ignore;

    % package data from this task
    data = [d.coh(select), d.correct(select), d.RT(select)];

    % get reasonable start values and bounds for ddm parameters
    Qinit = [ddRT_initial_params(data), ddRT_bound_params];

    % fit the ddRT parameters
    [Qs(:,tt), varQs(:,tt)] = ddRT_fit(...
        @ddRT_psycho_nll, @ddRT_chrono_nll_from_pred, ...
        data, Qinit);
end