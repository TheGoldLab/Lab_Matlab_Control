function P = linearWeibull(x, params)
% probabilities for a cumulative Weibull distribution on a linear abscissa
%
%   P = linearWeibull(x, params)
%
%   x is an array of stimulus abscissa values.
%
%   params is an optional vector of Weibull parameters of the form
%       [alpha, beta, lambda, gamma]
%
%   alpha is the threshold/inflection point (where p = 0.632), default = 1.
%
%   beta controls steepness/shape, default = 3.5.
%
%   lambda and gamma come from from Abbott's law.  lambda is the lapse
%   rate with default = .01.  gamma is the guess rate/false alarm rate
%   with default = 0;
%
%   Returns P(x), the percent correct/detect/whatever, where
%       P(x) = gamma + (1-gamma-lambda) * p(x)
%   implements Abbott's law, and
%       p(x) = 1-exp{(x/alpha)^beta}
%   is a cumulative Weibull with threshold alpha and shape parameter beta.
%
%   See also quick4 dBWeibull

% copyright 2007 Benjamin Heasly University of Pennsylvania

G = [1, 3.5, .01, 0];
if nargin == 2 && ~isempty(params) && isnumeric(params)
    G(1:length(params)) = params;
end
P = G(4) + (1-G(4)-G(3)) .* (1-exp(-(x./G(1)).^G(2)));