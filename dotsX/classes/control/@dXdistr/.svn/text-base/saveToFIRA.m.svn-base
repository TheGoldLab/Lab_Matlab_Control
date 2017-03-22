function d_ = saveToFIRA(d_)
%saveToFIRA method for class dXdistr: copy data to FIRA data record
%   saveToFIRA(d_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overlaoded saveToFIRA method for class dXdistr (random number gen)
%-%
%-% Arguments:
%-%   d_ ... array of dXdistr objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXdistr

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

names = {d_.name};
valName = cell(size(names));
nextName = cell(size(names));
for di = 1:length(names)
    valName{di} = [names{di} '_value'];
    nextName{di} = [names{di} '_nextValue'];
end

buildFIRA_addTrial('ecodes', {[d_.value], ...
    valName, repmat({'value'}, size(d_))});

buildFIRA_addTrial('ecodes', {[d_.nextValue], ...
    nextName, repmat({'value'}, size(d_))});

d = d_.distributions;
toFIRA = [d.toFIRA];
if any(toFIRA)
    buildFIRA_addTrial(d_.FIRAdataType, {d(toFIRA)});
end