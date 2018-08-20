function RTDcalibratePupilLabs(datatub)
% function RTDcalibratePupilLabs(datatub)
%
% RTD = Response-Time Dots
%
% Run pupilLabs calibration routines
%
% Inputs:
%   datatub - A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
% 
% 5/17/18 created by jig

% Check for pupil labs
ui = datatub{'Control'}{'ui'};
if isa(ui, 'dotsReadableEyePupilLabs')

    % Get the screen ensemble
    screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};

    % This does internal calibration and mapping to snow-dots
    %   then re-sets the clock and starts the data file
    ui.setupPupilLabs(screenEnsemble.getObjectProperty('windowRect'));
    
    % Save a maker that we just calibrated    
    topsDataLog.logDataInGroup(mglGetSecs, 'pupilLabsCalibration');
end