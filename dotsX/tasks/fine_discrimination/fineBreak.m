function fineBreak(taski, varargin)
% A wrapper for takeABreak.m, that checks whether this is a good time to
% take a break.  I think every other block would be good, and not following
% the final block.  Intended for use with the fine discrimination task.
%
% fineBreak(taski, varargin)
%
% taski and varargin passed to takeABreak

% 2008 by Benjamin Heasly at University of Pennsylvania


global FIRA

if ~isempty(FIRA) & isfield(FIRA, 'ecodes')
    
    % count the number of trial #1
    eTrial = strcmp(FIRA.ecodes.name, 'trial_num');
    blocks = nansum(FIRA.ecodes.data(:,eTrial)==1);
    
    % take a break every other trial and not after the last trial
    if any(blocks == [2 4 6 8])
        takeABreak(taski, varargin{:});
    end
end