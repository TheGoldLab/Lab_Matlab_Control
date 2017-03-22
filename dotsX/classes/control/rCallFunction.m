function rCallFunction(inds)
% function rCallFunction(varargin)
%
% disbatches the call method for dXfunctionCaller objects
%
% if inds is empty, use all objects
%
% Arguments:
%   inds    ...	which dXfunctionCaller instances to call call

% Copyright 2006 by Benjamin Heasly University of Pennsylvania

global ROOT_STRUCT

if ~nargin
    % usal all objects
    inds = 1:length(ROOT_STRUCT.dXfunctionCaller);
end

% invoke call() on inds instances
ROOT_STRUCT.dXfunctionCaller(inds) = call(ROOT_STRUCT.dXfunctionCaller(inds));