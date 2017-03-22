function [q_, stim] = dB2Stim(q_, dB)
%Convert an array of dB values to stimulus units
%   [q_, stim] = dB2Stim(q_, dB)
%
%   Using the reference value and exponent in the dXquest instance q_,
%   convert the array of decibal values dB to the equivalent array of
%   stimulus unit values stim.
%
%   Input:      q_      ... a dXquest object.
%               dB      ... an array of decibel values
%
%   Output:     q_      ... a dXquest object.
%               stim    ... an array of stimulus unit values
%
%   See also dXquest dXquest/reset dXquest/stim2dB

% Copyright 2008 Benjamin Heasly University of Pennsylvania
stim = 10.^(dB./q_.refExponent)*q_.refStim;