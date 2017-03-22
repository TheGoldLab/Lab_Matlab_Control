function q_ = saveToFIRA(q_)
%saveToFIRA method for class dXquest: copy data to FIRA data record
%   saveToFIRA(q_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overlaoded saveToFIRA method for class dXquest
%-%
%-% Arguments:
%-%   q_ ... array of dXquest objects
%-%
%-% Returns:
%-%   same q_
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXquest

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% track interesting fields (mostly that change every trial)
changes = {'override', 'convergedAfter', 'CIdB', 'pdfLike', ...
    'estimateLike', 'estimateLikedB', 'value', 'dBvalue'};

used = cell(size(q_));
for ii = 1:length(q_)

    % last stim value used
    used{ii} = [q_(ii).name, '_used'];

    % identity/purpose of this dXquest
    copious(ii).name = q_(ii).name;
    
    % many interesting values that change trial-by-trial
    for fn = changes
        copious(ii).(fn{1}) = q_(ii).(fn{1});
    end
end

% record stim value that was used as a handy ecode
buildFIRA_addTrial('ecodes', {[q_.value], ...
    used, repmat({'value'}, size(q_))});

% record copious QUEST info as special data type
buildFIRA_addTrial(q_(1).FIRAdataType, {copious});