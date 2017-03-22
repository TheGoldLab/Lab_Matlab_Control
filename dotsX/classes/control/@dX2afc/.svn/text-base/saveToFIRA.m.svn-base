function saveToFIRA(afs)
%saveToFIRA method for class dX2afc: copy data to FIRA data record
%   saveToFIRA(afs)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded saveToFIRA method for class 2afc
%-%
%-% Arguments:
%-%   afs ... array of 2afc objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dX2afc

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

buildFIRA_addTrial('ecodes', { ...
    [afs(1).outcomeVal, afs(1).rt1Val, afs(1).rt2Val], ...
    {'outcome',         'rt1',         'rt2'}});
