% set up UDP messaging socket
localIP = '192.168.1.4';
remoteIP = '192.168.1.6';
port = 6665;
socketTag = matlabUDP('open',localIP,remoteIP,port);

% demo code for showing four sets of dots and targets
sendMsg('rAdd(''dXtargets'',1,1,0,0,''visible'',true,''diameter'',0.50,''CLUTIndex'',2.00,''x'',[-12.00 -2.00 2.00 12.00 -12.00 -2.00 2.00 12.00 ],''y'',[4.00 4.00 4.00 4.00 -4.00 -4.00 -4.00 -4.00 ]);');
sendMsg('rAdd(''dXdots'',4,1,0,0,''visible'',true,''direction'',180.00,''size'',3.00,''apScale'',1.10,''speed'',3.00,''smooth'',{1.00 0.00 1.00 0.00 },''coherence'',{51.20 51.20 12.80 12.80 },''diameter'',6.00,''x'',{-7.00 7.00 -7.00 7.00 },''y'',{4.00 4.00 -4.00 -4.00 },''lifetimeMode'',{''random'',''random'',''limit'',''limit''},''flickerMode'',{''random'',''random'',''move'',''move''},''wrapMode'',{''random'',''random'',''wrap'',''wrap''});');
sendMsg('draw_flag=1;');
WaitSecs(4);
sendMsg('draw_flag=0;');
sendMsg('rGraphicsBlank;');
sendMsg('continue_flag=false;');

socketTag = matlabUDP('close');

% Here are some notes that I hope will get you started...

% The sendMsg function calls on our simple UDP implementation in
% matlabUDP.mexmac which I've included in case you want to try it out.  But
% in general, you can let the dXudp class take care of messaging. 

% You can get info about the client functions rAdd and rGraphicsBlank by
% typing e.g. <help rAdd> on the client machine MATLAB command prompt.

% dXdots objects will show the random dots stimulus.  For example,
% the message 
%   rAdd('dXdots',4,'x',{-9.00 -3.00 3.00 9.00 }, 'visible',true);
% will create 4 new instances of the dXdots class.  It will assign a
% different x-position to each instance and will make all of them visible.
% The message
%   rSet('dXdots',[1,2,3,4],'y',{5.00 1.50 -1.50 -5.00 },'diameter',4);
% will set the first through the fourth dXdots instance (all of them) to
% different y-positions and will give all of them the same diameter.

% You can specify the following properties of a dXdots object by
% parameter/vale pairs either when the object is created, with rAdd, or
% later with rSet:

%     % name              type		values	default
%     'coherence',        'scalar',	[],		51.2;	... % percent coherent motion
%     'direction',        'scalar',	[],		0;		... % deg from rightward = 0
%     'speed',            'scalar',	[],		8.0;    ... % deg/sec
%     'seed',             'array',	[],		[];		... % [base coh*dir]
%     'size',             'scalar',	[],		3;		... % dot size in pixels
%     'CLUTIndex',        'CLUTi',  [],		1;      ... % color index, 1-256
%     'maxPerFrame',      'scalar',	[],		9999;	... % number of dots
%     'loops',            'scalar', [],     3;      ... % interleaved dots
%     'duration',         'scalar', [],     0;      ... % ms (used if preCompute)
%     'density',          'scalar', [],     46.7;   ... % dots per sq.deg/sec
%     'x',                'scalar',	[],		0;		... % center deg visual angle
%     'y',                'scalar',	[],		0;		... % center deg visual angle
%     'diameter',         'scalar',	[],		10.0;   ... % aperture deg visual angle
%     'apScale',          'scalar', [],     1.1;    ... % >1 for bigger field than aperture
%     'userData',         'array',	[],		[];		... % arbitrary matrix if you want
%     'smooth',           'scalar', [],     1.0;    ... % smoother dot motion?
%     'preCompute',       'scalar', [],     0;      ... % -1='auto'; 0=no; 1+=#trials 
%     'deltaDir',         'scalar', [],     0;      ...
%     'flickerMode',      'string', {'random', 'move'},  'random'; ... % displacement of non-coh dots
%     'wrapMode',         'string', {'random', 'wrap'},  'wrap'; ... % dots behavior at edge of aperture
%     'lifetimeMode',     'string', {'random', 'limit'}, 'limit'; ... % force limited lifetime of dots
%     'visible',          'boolean',[],		0;		... % show dots or not
%     'tag',              'scalar',	[],		0;      ... % unused for now
%
% dXtarget objects will show a fixation point.  You can specify:
%
%     'visible',          'boolean',[],		false;	... % show target or not
%     'x',                'scalar',	[],		0;		... % center deg visual angle
%     'y',                'scalar',	[],		0;		... % center deg visual angle
%     'diameter',         'scalar',	[],		0;		... % deg visual angle
%     'diameter2',        'scalar',	[],		0;		... % unused here
%     'cmd',              'scalar', [],     0;      ... %0=fillOval,1=frameOval,2=fillRect,3=frameRect
%     'penWidth',         'scalar', [],     1;      ... % frame width
%     'CLUTIndex',        'CLUTi',	[],		4;		... % color index, 1-256

% Messages like <draw_flag=1> determine client stimulus presentation
% behavior as follows:

    %   drawFlag = 0 ... freeze the stimuli
    %   drawFlag = 1 ... animate stimuli until further notice
    %   drawFlag = 2 ... like 1, but stimuli accumulate on screen over time
    %   drawFlag = 3 ... increment stimulus animation by one timestep
    %   drawFlag = 4 ... like 3, but stimuli accumulate on screen over time

% you might only need 0 and 1.

% the message <continue_flag=false;> will cause the client to stop
% executing and return to the MATLAB command prompt.

% When creating or editing messages, beware of double quotes!  For example,
% the text 
%   rAdd('dXtargets',1);
% is a valid message which the mac mini client can evaluate.  The client
% expects single quotes around the class name, 'dXtargets.'  But in MATLAB,
% a written-out string containing that message must read 
%   'rAdd(''dXtargets'',1);'
% MATLAB interprets a nested double quote ('') like a single quote (').

% Ben
