function likeT = quest_like(trialData, domain, psychFcn, Q)
%Compute the quest threshold liklihood function for some data and PMF.
%
%   likeT = quest_like(trialData, domain, psychFcn, Q)
%
%   likeT is the likelihood of threshold evaluated over the specified
%   domain.
%
%   trialData is a column of stimulus strengths and a column of responses:
%       trialData(:,1) is the stimulus strength of each trial (log units).
%       trialData(:,2) is corresponding 2afc choices (0 or 1)
%   The number of rows of trialData is the number of trials.
%
%   domain is the array of stimulus strengths that are candidates for
%   threshold, i.e. all reasonable stimulus strengths (log units).
%
%   psychFcn is a function handle to any function that represents a
%   psychometric function.  It must have the form
%       P = psychFcn(x, Q),
%   where x is stimulus strength in log units and Q is a set of parameters.
%   The first parameter, Q(1), must correspond to threshold, and it should
%   shift psychFcn along the x-axis.
%
%   Q is an array of psychometric function parameters.  Q(1) must
%   correspond to threshold and must shift psychFcn along the x-axis.
%   Other parameters are unconstrained, but must be expected by psychFcn.
%   For example, if psychFcn = @dBWeibull, then
%       Q(1) = alpha, the decibel Weibull threshold or shift parameter
%       Q(2) = beta, the decibel Weibull shape or slope parameter
%       Q(1) = lambda, upper asymptote or lapse rate
%       Q(1) = gamma, the lower asymptote or guess rate
%
%   Note: if Q(1) is non-zero, domain will be shifted by that amount.  This
%   is like using an epsilon in Watson and Pelli* equation 13.
%
%   *Watson and Pelli, "QUEST: A Bayesian adaptive psychometric
%   method," Perception and Psychophysics, 1983, 33 (2), 113:120;
%
%   See also, dBWeibull, dXquest, dXquest/endTrial, QuestDemo

% 2008 Benjamin Heasly at University of Pennsylvania

likeT = ones(size(domain));

correct = logical(trialData(:,2))';
for ii = find(correct)
    
    % multiply by the success function for each "correct" respose
    f = feval(psychFcn, trialData(ii,1)-domain, Q);
    likeT = likeT .* f;
    likeT = likeT/(sum(likeT));
end

for ii = find(~correct)

    % multiply by the failure function for each "incorrect" response
    f = (1-feval(psychFcn, trialData(ii,1)-domain, Q));
    likeT = likeT .* f;
    likeT = likeT/(sum(likeT));
end