function hardware_ = gXCMD_hardware(varargin)
%Get hardware device configuration for the simple_demo task
%
%   hardware_ = gXsimpleDemo_hardware(varargin)
%
%   gXsimpleDemo_hardware returns a cell array of class names, parameters,
%   and values for configuring hardware for the simple_demo task.  This
%   includes:
%       two dXbeep objects for task timing
%       two dXsound objects for performance feedback
%
%   The simple_demo task also uses the dXkbHID hardware device for checking
%   keyboard inputs, but that device is automatically activated and
%   configured by rInit.
%
%   hardware_ is a cell array with rows of the form
%       {class_name, number_of_instances, rAdd_args, parameters_and_values}
%   See below for details.
%
%   This is the form expected by the rGroup function, so invoking
%       rGroup('gXsimpleDemo_hardware')
%   will add all of the configured hardware devices to ROOT_STRUCT.
%
%   gXsimpleDemo_hardware may also be included as a helper for a dXtask, in
%   which case the configured hardware devices will be added to the
%   ROOT_STRUCT for that task.
%
%   varargin may be a boolean specifying whether to mute all sounds.
%
%   See also rInit, rGroup, rAdd, taskSimpleDemo

% 2008 by Benjamin Heasly
%   University of Pennsylvania
%   benjamin.heasly@gmail.com
%   (written in the Black Hills of South Dakota!)

% check varargin for a mute value
if nargin && varargin{1}
    mute = true;
else
    mute = false;
end

% get parameters_and_values for one dXbeep object
%   the second is a low tone to scold the subject for an invalid response.
arg_dXbeep = { ...
    'mute',         mute, ...
    'frequency',    {500}, ...
    'duration',     .100, ...
    'gain',         .2};

% get parameters_and_values for two dXsound objects
%   the first is a Mario coin sound to indicate a correct response.
%   the second is a Zelda damage sound to indicate an incorrect response.
arg_dXsound = { ...
    'mute',         mute, ...
    'rawSound',     {'Coin.wav',    'AOL_Hurt.wav'}, ...% scan 4 analog inputs (vs. ground) at 1000Hz
    'gain',         {.5,            2}};


%%%FOR USING LEVERS

% scan 4 analog inputs (vs. ground) at 1000Hz   
% % mode = 1 means +/-10V
% chans = 8:11;
% nc = length(chans);
% modes = ones(size(chans));
% f = 1000;
% [load, loadID] = formatPMDReport('AInSetup', chans, modes);
% [start, startID] = formatPMDReport('AInScan', chans, f);
% [stop, stopID] = formatPMDReport('AInStop');
% 
% % tell HIDx which channels are in use
% cc = num2cell(chans);
% [PMDChans(1:nc).ID]      = deal(cc{:});
% 
% % covert integers to decimal Voltages and divide out internal gain
% gc = num2cell(0.01./2);
% [PMDChans(1:nc).gain]	= deal(gc{:});
% 
% [PMDChans(1:nc).offset]	= deal(0);
% [PMDChans(1:nc).high]	= deal(nan);
% 
% % only report lever state changes
% %   i.e. crossing the +3V line
% [PMDChans(1:nc).low]     = deal(3);
% [PMDChans(1:nc).delta]	= deal(.5);
% 
% % convert serial numbers to sample times
% [PMDChans(1:nc).freq]	= deal(f);
% 
% arg_dXPMDHID = { ...
%     'HIDChannelizer',   PMDChans, ...
%     'loadID',           loadID, ...
%     'loadReport',       load, ...
%     'startID',          startID, ...
%     'startReport',      start, ...
%     'stopID',           stopID, ...
%     'stopReport',       stop};

%%END LEVER CODE

    
% configure the rAdd_args.  This tells rAdd four things:
%   1. What group should these objects belong to?  'root' means add
%   objects to the root group, which is always active.
%
%   2. Should rAdd try to reuse existing objects of the same type?  If so,
%   rAdd will configure some existing objects rather than create new ones.
%
%   3. Should rAdd configure objects with rSet immediately upon creation?
%
%   4. Should rGroup reconfigure the object with rSet every time rGroup
%   activates this object (e.g. every time the task is activated)?
rAdd_args = {'root', true, true, false};

hardware_ = { ...
    'dXbeep',	1,  rAdd_args,	arg_dXbeep; ...
    'dXsound',	2,  rAdd_args,	arg_dXsound; ...
%     'dXPMDHID', 1,  rAdd_args, arg_dXPMDHID; ...  %%%FOR LEVERS
    };