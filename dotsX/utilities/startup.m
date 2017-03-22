% when MATLAB finds this script at startup, it will cd to DotsX.
[pat, nam, ext] = fileparts(mfilename('fullpath'));
homeDir = sprintf('%s/..', pat);
cd(homeDir)
disp(sprintf('cd %s', pwd))
clear all