function [s_, attributes_, batchMethods_] = dXscreen(num_objects)% [s_, attributes_, batchMethods_] = dXscreen(num_objects)%% Creates a dXscreen object, "parent" class%   of all graphics objects%% Arguments:%   num_objects    ... ignored%% Returns:%   s_             ... created dXscreen object%   attributes_    ... default object attributes%   batchMethods_  ... methods that can be run in a batch (e.g., draw)% Copyright 2004 by Joshua I. Gold%   University of Pennsylvania% because of debug/remote mode, this can% be run on a computer without 'Screen' ...% so check first before using 'Screen' to% establish defaultsif isempty(which('Screen'))    screenMode      = 'debug';    screenNumber    = 0;    hideCursor      = false;    frameRate       = 60;    monitorWidth    = 38;    viewingDistance = 60;else    % check for appropriate version    AssertOpenGL;    % local screen mode    screenMode = 'local';    % default screen number is the highest numbered screen    screenNumber = max(Screen('Screens'));    % frame rate can be determined by Screen    frameRate = Screen('FrameRate', screenNumber);    if frameRate == 0        frameRate = 60;    end    % check specific computer    [s,w] = unix('hostname');    % set some machine-specific defaults    loadGamma8bit = false;    loadGammaBitsPlus = false;    if strncmp(w, 'Joshuas-MacBook-Pro.', 20)        monitorWidth    = 82;        viewingDistance = 60;    elseif strncmp(w, 'gold.', 5)        monitorWidth    = 31.75;        viewingDistance = 60;    elseif strncmp(w, 'labs-mac-mini.', 14)        monitorWidth    = 40;        viewingDistance = 63.5;        loadGammaBitsPlus = true;    elseif strncmp(w, 'duoSlave.', 9)        % these are worth doublechecking from time to time        monitorWidth    = 40;        viewingDistance = 63.5;        loadGamma8bit = true;    elseif strncmp(w, 'goldpsych.', 10)        % these are made up        monitorWidth    = 40;        viewingDistance = 63.5;    elseif strncmp(w, 'quadMaster.', 11)        % these are worth doublechecking from time to time        monitorWidth    = 40;        viewingDistance = 63.5;            elseif strncmp(w, 'Rig4-mini', 9)                monitorWidth    = 59.69;        viewingDistance = 60;        loadGamma8bit   = true;          else        monitorWidth    = 38;        viewingDistance = 60;    end    % build a gamma table filename from hostname    wdot      = find(w == '.');    gammaFile = ['Gamma_', w(1:wdot), 'mat'];    if ~isempty(which(gammaFile))        load(gammaFile);    end    % check for existing gamma tables that should have beel loaded above    if ~(exist('gamma8bit') == 1)        % default RGB gamma table        gamma8bit = repmat(linspace(0, 2^8 -1, 256)'./255, 1, 3);    end    if ~(exist('gamma16bit') == 1)        % default Mono++ gamma table        gamma16bit = round(linspace(0, 2^16 -1, 2^16))';    endend% hide cursor only if one screen foundif length(Screen('Screens'))==1    hideCursor = true;else    hideCursor = false;end% make the gamma table that 'connects' the video card to the Bits++ box;gammaBitsPlus = linspace(0,(255/256),256)'*ones(1,3);% default object attributesattributes = { ...    % name              type		ranges  default    'screenMode',       'string',	{'local', 'debug', 'remote'}, screenMode; ...    'hideCursor',       'boolean',	[],		hideCursor;     ...    'priority',         'scalar',	[],     9;              ...    'multiSampling',    'scalar',   [],     0;              ...    'screenNumber',     'scalar',	[],     screenNumber;   ...    'openRect',         'scalar',	[],     [];             ...    'pixelSize',        'scalar',	[],		32;             ...    'monitorWidth',     'scalar',	[],		monitorWidth;   ...    'viewingDistance',  'scalar',	[],		viewingDistance;...    'numberOfBuffers',  'scalar',   [],     2;              ...    'showWarnings',     'boolean',  [],     true;          ...    'loadGamma8bit',    'boolean',	[],     loadGamma8bit;  ...    'loadGammaBitsPlus','boolean',	[],     loadGammaBitsPlus; ...    'bgColor',          'array',    [],     [0,0,0,255];    ...    'windowNumber',     'auto',     [],     -1;             ...    'screenRect',       'auto',     [],     [0 0 30 20];	...    'flipMode',         'auto',     [],     false;          ...    'frameRate',        'auto',     [],     frameRate;      ...    'pixelsPerDegree',  'auto',     [],     10;             ...    'gammaBitsPlus',    'auto',     [],     gammaBitsPlus;  ...    'gamma8bit'         'auto',     [],     gamma8bit;      ...    'gamma8bitOld'      'auto',     [],     [];             ...    'gamma16bit',       'auto',     [],     gamma16bit;     ...    'remoteClockLog',   'auto',     [],     []};% make an array of objects from structs made from the attributess_ = class(cell2struct(attributes(:,4), attributes(:,1), 1), 'dXscreen');% return the attributes, if necessaryif nargout > 1    attributes_ = attributes;endif nargout > 2    batchMethods_ = {'root', 'blank'};end