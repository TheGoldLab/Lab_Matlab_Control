function isAvail = nextTrial(ta)
% function isAvail = nextTrial(ta)
%
% Prepare the next trial from task ta.  Probably delegate to 'control'
% helper.
%
% In:
%   ta  ... an instance of dXtask
%
% Out:
%   isAvail ... boolean--are any trials left to do from this task

% 2006 By Benjamin Heasly at University of Pennsylvania
global ROOT_STRUCT

% True unless set by hand or by 'control' helper
isAvail = ta(1).isAvailable;