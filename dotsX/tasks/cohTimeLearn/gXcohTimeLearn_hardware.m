function hardware_specs = gXcohTimeLearn_hardware(varargin)

if nargin
    settings = varargin{1};
else
    settings.useASL = true;
    settings.mouseMode = false;
    settings.mute = false;
    settings.usePMD = false;
end

% blink filter parameters:
%   these units are pretty raw:
BF.n = 5; % number of frames
BF.lowP = 0; % unknown units
BF.deltaP = 10; % unknown units per frame
BF.deltaH = 650; % point-of-gaze-units*100 per frame
BF.deltaV = 650; % point-of-gaze-units*100 per frame

if settings.mouseMode
    disp(sprintf('\ndXasl in mouseMode (%s)\n', mfilename))
end
arg_dXasl = { ...
    'mouseMode',    settings.mouseMode, ...
    'freq',         120, ...
    'blinkParams',  BF, ...
    'aslRect',      [-2032, 1532, 4064, -3064], ...
    'showPlot',     true, ...
    'showPtr',      {{'dXdots'};{'dXtarget'}}};

if settings.mute
    disp(sprintf('dXbeep mute (%s)', mfilename))
end
arg_dXbeep = { ...
    'mute',         settings.mute, ...
    'frequency',    {417.3917,	834.7833}, ...
    'duration',     {.100,      .100}, ...
    'gain',         .2};

arg_dXsound = { ...
    'mute',         settings.mute, ...
    'rawSound',     {'Coin.wav',    'AOL_Hurt.wav',	'AOL_Map.wav'}, ...
    'gain',         {1,             2,              .5}};

% scan 4 analog inputs (vs. ground) at 1000Hz
%   mode = 1 means +/-10V
chans = 8:11;
nc = length(chans);
modes = ones(size(chans));
f = 1000;
[load, loadID] = formatPMDReport('AInSetup', chans, modes);
[start, startID] = formatPMDReport('AInScan', chans, f);
[stop, stopID] = formatPMDReport('AInStop');

% tell HIDx which channels are in use
cc = num2cell(chans);
[PMDChans(1:nc).ID]      = deal(cc{:});

% covert integers to decimal Voltages and divide out internal gain
gc = num2cell(0.01./2);
[PMDChans(1:nc).gain]	= deal(gc{:});

[PMDChans(1:nc).offset]	= deal(0);
[PMDChans(1:nc).high]	= deal(nan);

% only report lever state changes
%   i.e. crossing the +3V line
[PMDChans(1:nc).low]     = deal(3);
[PMDChans(1:nc).delta]	= deal(.5);

% convert serial numbers to sample times
[PMDChans(1:nc).freq]	= deal(f);

arg_dXPMDHID = { ...
    'HIDChannelizer',   PMDChans, ...
    'loadID',           loadID, ...
    'loadReport',       load, ...
    'startID',          startID, ...
    'startReport',      start, ...
    'stopID',           stopID, ...
    'stopReport',       stop};

arg_dXfeedback = { ...
    'doEndTrial',       'block', ...
    'size',             22, ...
    'bold',             true, ...
    'x',                -16, ...
    'tasksColor',       [1 1 0]*255, ...
    'totalsColor',      [1 1 0]*255, ...
    'displaySecs',      6e2};

% {'group', reuse, set now, set always}
static = {'root', true, true, false};
hardware_specs = { ...
    'dXbeep',       2,  static, arg_dXbeep; ...
    'dXsound',      3,  static, arg_dXsound; ...
    'dXfeedback',	1,	static, arg_dXfeedback; ...
    };

if settings.useASL
    hardware_specs = cat(1, {'dXasl', 1, static, arg_dXasl}, hardware_specs);
end

if settings.usePMD
    hardware_specs = cat(1, {'dXPMDHID', 1, static, arg_dXPMDHID}, hardware_specs);
end