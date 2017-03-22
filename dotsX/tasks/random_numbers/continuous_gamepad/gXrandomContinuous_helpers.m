function helpers_ = gXrandomContinuous_helpers(varargin)
x=1

if nargin && ~isempty(varargin{1})
    blockSD = varargin{1};
else
    blockSD = [1];
end


if nargin >1 && ~isempty(varargin{2})
    mSbs = varargin{2};
else
    mSbs = [20];
end


if nargin > 2 && ~isempty(varargin{3})
    useASL = varargin{3};
else
    useASL = false;
end

if nargin > 3 && ~isempty(varargin{4})
    HHvar = varargin{4};
else
    HHvar = 0
end





for ii = 1:length(blockSD)

    %   gaussian
    d(ii).gain = 1;
    d(ii).offset = 1;
    d(ii).args = {nan,blockSD(ii)};
    d(ii).func = @normrnd;
    d(ii).toFIRA = true;

    % degenerate metadistribution
    %   only the gaussian
    m(ii).first = ii;
    m(ii).second = ii;
    m(ii).p = .5;
    m(ii).count = 0;
    m(ii).args = {mSbs(ii)};

    a=blockSD

end


%% if running the hidden blocks task change total trials to 1200
if HHvar==1
    tt=1200
else
    tt=200
end


arg_dXdistr = { ...
    'name',         'random_number', ...
    'ptr',          {{'dXtext', 1, 'string'}}, ...
    'totTrials',    tt, ...
    'subBlockSize', nan, ...
    'subBlockMethod', @newMeanNewSubBlockSize, ...
    'distributions',d,	...
    'metaD',        m};

arg_dXfeedback = { ...
    'doEndTrial',       'block', ...
    'size',             22, ...
    'bold',             true, ...
    'x',                -16, ...
    'tasksColor',       [1 1 0]*255, ...
    'totalsColor',      [1 1 0]*255, ...
    'displaySecs',      6e2};

%disp(sprintf('dXsound mute (%s)', mfilename))
arg_dXsound = { ...
    'mute',         false, ...
    'rawSound',     {'Super Mario 2 - Pick Up.wav', ...
    '1 up.wav', 'Pipe Warp.wav', 'Pause.wav', 'Coin.wav', 'Super Mario 2 - Door.wav'}};

% channel manipulations to do in mex function
%   assume 2 axes (-1,0,1) plus 6 buttons (boolean)
[HIDChannelizer(1:2).high] = deal(127/4);
[HIDChannelizer(1:2).low] = deal(3*127/4);
[HIDChannelizer(3:8).high] = deal(nan);
[HIDChannelizer(3:8).low] = deal(nan);

arg_dXgameHID = { ...
    'HIDChannelizer',       HIDChannelizer};

% blink filter parameters:
%   these units are pretty raw:
BF.n = 5; % number of frames
BF.lowP = 0; % unknown units
BF.deltaP = 10; % unknown units per frame
BF.deltaH = 650; % point-of-gaze-units*100 per frame
BF.deltaV = 650; % point-of-gaze-units*100 per frame

mouseMode = false;
if mouseMode
    disp(sprintf('dXasl in mouseMode (%s)', mfilename))
end
arg_dXasl = { ...
    'mouseMode',    mouseMode, ...
    'freq',         120, ...
    'blinkParams',  BF, ...
    'aslRect',      [-2032, 1532, 4064, -3064], ...
    'showPlot',     true};

%       group, reuse, set now, set always
static = {'root', true, true, false};
reswap = {'current', false, true, false};

helpers_ = { ...
    'dXdistr',      1,  reswap,	arg_dXdistr; ...
    'dXfeedback',   1,  static,	arg_dXfeedback; ...
    'dXsound',      6,  static,	arg_dXsound; ...
    'dXgameHID',    1,  static,	arg_dXgameHID, ...
    };

if useASL
    asl = {'dXasl',	1,  static,	arg_dXasl};
    helpers_ = cat(1, helpers_, asl);
end