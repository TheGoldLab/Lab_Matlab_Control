function time_ = sampleTime(args)
% function time_ = sampleTime(args)
%
% State Machine utility to sample from different distributions, 
%  typically to set the timeout field in a topsStateMachine state
%
% Created 6/22/2018 by jig

if nargin < 1 || isempty(args)
   
   % nada
   time_ = 0;
   
elseif isscalar(args)
   
   % args = fixed value
   time_ = args;
   
elseif length(args) == 2
   
   % args = [min max] of uniform random
   time_ = args(1) + diff(args)*rand();
   
   
elseif length(args) == 3
   
   % args = [min mean max] of exponential random
   time_ = args(1) + min(exprnd(args(2)), args(3));
end
