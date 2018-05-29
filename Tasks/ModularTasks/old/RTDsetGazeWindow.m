function RTDsetGazeWindow(ui, varargin)
% function RTDsetGazeWindow(ui, varargin)
%
% RTD = Response-Time Dots
%
% Utility to update gaze window settings
%
% arguments are cell arrays of arguments to dotsReadableEye.addGazeWindow
%
% 5/11/18 written by jig

if isa(ui, 'dotsReadableEye')    
    for ii = 1:nargin-1
        ui.addGazeWindow(varargin{ii}{:});
    end
end
