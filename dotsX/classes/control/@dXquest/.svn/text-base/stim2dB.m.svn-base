function [q_, dB] = stim2dB(q_, stim)
%Convert an array of stimulus unit values to dB
%   [q_, dB] = stim2dB(q_, stim)
%
%   Using the reference value and exponent in the dXquest instance q_,
%   convert the array of stimulus unit values stim to the equivalent array
%   of decibel values dB.
%
%   Input:      q_      ... a dXquest object.
%               dB      ... an array of decibel values
%
%   Output:     q_      ... a dXquest object.
%               stim    ... an array of stimulus unit values
%
%   See also dXquest dXquest/reset dXquest/dB2Stim

% Copyright 2008 Benjamin Heasly University of Pennsylvania
dB = q_.refExponent.*log10(stim./q_.refStim);