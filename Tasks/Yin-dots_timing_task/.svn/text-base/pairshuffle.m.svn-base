function [shuffCond1, shuffCond2] = pairshuffle(cond1, cond2, numpercond)
% PAIRSHUFFLE Generates shuffled version of pair-wise combination of
% conditions.  These conditions can be used to set parameters of a trial.
%
%   [shuffCond1, shuffCond2] = pairshuffle(cond1, cond2, numpercond)
%
% INPUTS:
%   cond1 = array of first set of conditions
%   cond2 = array of 2nd set of conditions
%   numpercond = number of trials per pair of conditions
%
% OUTPUTS:
%   shuffCond1 = array of 1st set of conditions, shuffled
%   shuffCond2 = array of 2nd set of conditions, shuffled
%
% yl 2010-09-01

% 1. generate a big matrix to put pairs of conditions in
A = zeros(length(cond2), length(cond1), 2);
A(:,:,1) = repmat(cond1, length(cond2), 1);
A(:,:,2) = repmat(cond2',1, length(cond1));

% 2. 'flatten' to a single dimensions
shuffCond1 = []; shuffCond2 = [];
for i = 1:length(A(:,1,1))
    shuffCond1 = [shuffCond1 A(i,:,1)];
    shuffCond2 = [shuffCond2 A(i,:,2)];
end

% 3. expand to numpercond times
shuffCond1 = repmat(shuffCond1,1,numpercond);
shuffCond2 = repmat(shuffCond2,1,numpercond);

% 4. shuffle
shuffIndex = randperm(length(shuffCond1));
shuffCond1 = shuffCond1(shuffIndex);
shuffCond2 = shuffCond2(shuffIndex);