% Get the absolute path to the Snow Dots project root.
%
% @ingroup dotsUtilities
function dotsPath = dotsRoot()
utilitiesPath = fileparts(which('SnowDots'));
dotsPath = fullfile(utilitiesPath, '..');