% Get the absolute path to the Tower of Psych project root.
% @details
% If Tower of Psych is on the Matlab path, returns an absolute path string
% to where Tower of Psych is located.
%
% @ingroup topsUtilities
function topsPath = topsRoot()
utilitiesPath = fileparts(which('TowerOfPsych'));
topsPath = fullfile(utilitiesPath, '..');