function tcs_ = saveToFIRA(tcs_)
%saveToFIRA method for class dXtc: copy data to FIRA data record
%   saveToFIRA(tcs_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overlaoded saveToFIRA method for class dXtc (tuning curve)
%-%
%-% Arguments:
%-%   tcs_ ... array of dXtc objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXtc

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% save 'value', not 'previousValue', since dXtask/trial calls saveToFiRA
% before dXparadigm/runTasks calls endTrial (which is where 'value' gets
% bumped into 'previousValue').

buildFIRA_addTrial('ecodes', {[tcs_.value], ...
    {tcs_.name}, repmat({'id'}, size(tcs_))});