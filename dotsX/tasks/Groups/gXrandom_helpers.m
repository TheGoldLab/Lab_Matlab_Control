function helpers_ = gXrandom_helpers

% define three distributions
%   gaussian
d(1).gain = 10;
d(1).offset = -15;
d(1).args = {5,1};
d(1).func = @normrnd;

%   exponential
d(2).gain = 12;
d(2).offset = 3;
d(2).args = {1};
d(2).func = @distrExp;

%   backwards exponential
d(3).gain = -12;
d(3).offset = 75;
d(3).args = {1};
d(3).func = @distrExp;

% define four metadistributions for mixing above
%   only the gaussian
m(1).first = 1;
m(1).second = 1;
m(1).p = .5;

%   only the first exponential
m(2).first = 2;
m(2).second = 2;
m(2).p = .5;

%   only the second exponential
m(3).first = 3;
m(3).second = 3;
m(3).p = .5;
m(3).count = 0;

%   mix of exponentials
m(4).first = 2;
m(4).second = 3;
m(4).p = floor(linspace(0,10+1e15/(1e15+1),330))/10;
m(4).count = 0;

% when to go to the next metadistribution
changes = cumsum([0 100 150 150]);

arg_dXdistr = { ...
    'name',         'random_number', ...
    'ptr',          {{'dXtext', 1, 'string'}}, ...
    'totTrials',    730, ...
    'distributions',d,	...
    'metaD',        m,	...
    'changeMetaD',  changes};

arg_dXfunctionCaller = { ...
    'function',     @lrFromDiff, ...
    'doEndTrial'    false, ...
    'args',	{{'dXdistr', 1, 'nextValue'}, {'dXdistr', 1, 'value'}}};

%disp(['HEY BUTTHEAD, THE BEEPS ARE MUTED (',mfilename,').'])
arg_dXbeep = { ...
    'mute',         false, ...
    'frequency',    {783.99,    1046.5,	493.88, 391.995}, ...
    'duration',     {.100,      .500,	.250,   .300}};

arg_dXfeedback = { ...
    'doEndTrial',       'block', ...
    'size',             22, ...
    'bold',             true, ...
    'x',                -16, ...
    'tasksColor',       [1 1 0]*255, ...
    'totalsColor',      [1 1 0]*255, ...
    'displaySecs',      6e2};

arg_dXlpHID = {};

arg_dXkbHID = {};

%       group, reuse, set now, set always
tony = {'root', true, true, false};
biff = {'current', false, true, false};
greg = {'current', false, true, true};
helpers_ = { ...
    'dXdistr',      1, biff, arg_dXdistr; ...
    'dXfunctionCaller',1,biff,arg_dXfunctionCaller; ...
    'dXbeep',       4, tony, arg_dXbeep; ...
    'dXfeedback',   1, tony, arg_dXfeedback; ...
    'dXlpHID',      1, tony, arg_dXlpHID; ...
    'dXkbHID',      1, tony, arg_dXkbHID};