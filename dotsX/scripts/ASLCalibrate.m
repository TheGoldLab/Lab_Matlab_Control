% Asl eye tracker calibration script

% Copyright 2007 by Benjamin Heasly at University of Pennsylvaniaq

global ROOT_STRUCT
rInit('remote');

try
    % black background
    rSet('dXscreen', 1, 'bgColor', [1 1 1]*4);

    % we want eye positions with blink filter
	BF.n = 33;
    BF.lowP = 0;
	BF.deltaP = 5;
	BF.deltaH = 5;
	BF.deltaV = 5;
    %rAdd('dXasl', 1, 'mouseMode', false);%  , 'blinkParams', BF);

    % get standard calibration point set
    rGroup('gXASLCalibrate');

    % the last target should represent eye position
    eye = length(ROOT_STRUCT.dXtarget);
    
    %rSet('dXtarget', eye, 'visible', false);

    % show targets in dXasl plot
    % rSet('dXasl', 1, ...
    %     'movePtr',      {'dXtarget', eye}, ...
    %     'showPtr',      {{'dXtarget', 1:eye-1}}, ...
    %     'showPlot',     true);

    % show all targets
    rGraphicsDraw;

    rPutMappings('dXkbHID', 1, {'q', 'quit'});
    disp('PRESS Q TO QUIT')
    while isempty(ROOT_STRUCT.jumpState) ...
            || ~strcmp(ROOT_STRUCT.jumpState, 'quit')

        % check keyboard
        HIDx('run');

        % get latest eye position
        %   automatically plot/animate it among the targets
        %ROOT_STRUCT.dXasl = query(ROOT_STRUCT.dXasl);

        % update Screen graphics and dXasl figure
        rGraphicsDraw;
        drawnow
        WaitSecs(.001);
    end

    rDone
catch
    e = lasterror
    rDone
end