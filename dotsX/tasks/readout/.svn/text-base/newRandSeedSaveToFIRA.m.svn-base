function newRandSeedSaveToFIRA
% pick a new seed for MATLAB's random number generator
%   save as an ecode to FIRA
global ROOT_STRUCT

% pick the new seed from the clock
ROOT_STRUCT.randSeed = GetSecs;
ROOT_STRUCT.randMethod = 'twister';
rand(ROOT_STRUCT.randMethod, ROOT_STRUCT.randSeed);

% save as an ecode for this trial
buildFIRA_addTrial('ecodes', {ROOT_STRUCT.randSeed, {'preDotsRandSeed'}, {'value'}});