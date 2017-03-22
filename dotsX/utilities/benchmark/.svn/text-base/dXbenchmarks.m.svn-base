% For a given DotsX machine, with a given CPU, graphics card, etc., measure
% performance of DotsX in local mode.  In particular:
%   - How much CPU time is available during each graphics frame?
%   - How does the machine perform with various dXdot densities?
%   - What is the overhead in calling draw() for multiple class types?
%
% Test relevant graphics and show plots to answer each question.

% Copyright 2007 by Benjamin Heasly, University of Pennsylvania

% CPU time
cpuFig = measureFrameFlipDeadline;

% dot density
dotFig = measureDotDensityPerformance;
set(dotFig, 'Position', get(dotFig, 'Position') + [50 -100 0 0]);

% class overhead
overFig = measureClassDrawingOverhead;
set(overFig, 'Position', get(overFig, 'Position') + [100 -200 0 0]);