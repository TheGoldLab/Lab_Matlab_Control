function P = dBWeibull(dB, params)
% probabilities for a cumulative Weibull distribution on a decibel abscissa
%
%   P = dBWeibull(dB, params)
%
%   dB is an array of decibel abscissa values where 
%       1dB is a factor of 10^(1/20) 
%
%   params is an optional vector of Weibull parameters of the form
%       [alpha, beta, lambda, gamma]
%
%   alpha is the threshold/inflection point (often where p=0.632 p=0.816),
%   default = 0.
%
%   beta controls steepness/shape, default = 3.5.
%
%   lambda and gamma come from from Abbott's law.  lambda is the lapse
%   rate with default = .01.  gamma is the guess rate/false alarm rate
%   with default = 0;
%
%   Returns P(dB), the percent correct/detect/whatever, where
%       P(dB) = gamma + (1-gamma-lambda) * p(dB)
%   implements Abbott's law, and
%       p(dB) = 1-exp{-10^[(dB-alpha)*beta/20]}
%   is a decibel Weibull with threshold alpha and shape parameter beta.
%
%   This formulation of the Weibull assumes that the reference value X_ref,
%   used to define decibels in terms of linear units, is the same as some
%   linear-unit Weibull threshold, X_th.  Thus alpha = 0dB corresponds to
%   X_th = 1 linear unit.
%
%   In practice 0dB corresponds to a refrence, X_ref, in linear units, and
%       X = 10^(dB/20) * X_ref
%   and
%       X_th = 10^(alpha/20) * X_ref
%
%   See also dXquest quick4 linearWeibull

% copyright 2007 Benjamin Heasly University of Pennsylvania

G = [0, 3.5, .01, 0];
if nargin == 2 && ~isempty(params) && isnumeric(params)
    G(1:length(params)) = params;
end
P = G(4) + (1-G(4)-G(3)) .* (1-exp(-10.^((G(2)/20).*(dB-G(1)))));