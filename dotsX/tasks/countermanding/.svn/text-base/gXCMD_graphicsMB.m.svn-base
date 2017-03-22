function graphics_ = gXCMD_graphics(varargin)
%Get graphics configuration for the simple_demo task
%
%   graphics_ = gXsimpleDemo_graphics(varargin)
%
%   gXsimpleDemo_graphics returns a cell array of class names, parameters,
%   and values for configuring the graphics of the simple_demo task.  This
%   includes:
%       one dXdots stimulus
%       one dXtarget fixation point
%       two dXtext feedback messages
%
%   graphics_ is a cell array with rows of the form
%       {class_name, number_of_instances, rAdd_args, parameters_and_values}
%   See below for details.
%
%   This is the form expected by the rGroup function, so invoking
%       rGroup('gXsimpleDemo_graphics')
%   will add all of the configured graphics to ROOT_STRUCT.
%
%   gXsimpleDemo_graphics may also be included as a helper for a dXtask, in
%   which case the configured graphics will be added to the ROOT_STRUCT for
%   that task.
%
%   varargin is ignored.
%
%   See also rGroup, rAdd, taskSimpleDemo

% 2008 by Benjamin Heasly
%   University of Pennsylvania
%   benjamin.heasly@gmail.com
%   (written in the Black Hills of South Dakota!)

% make shorthand for some colors
red =   [128 0 0];
green = [0 128 0];
blue =  [0 0 128];

% texture background

% sq=[1024, 1280]
% high = 9;
% low = 0;
% mid = 4;
% 
% arg_dXtexture = { ...
%     'textureFunction',  'textureChecker',  ...
%     'textureArgs',      {num2cell(sq./4), num2cell(sq./16)}, ...
%     'color',            low, ...
%     'bgColor',          high, ...
%     'visible',          {true, false}, ...
%     'filterMode',       0, ...
%     'w',                inf, ...
%     'h',                inf};
% 
% gray = [1 1 1]*mid;


% get parameters_and_values for three dXtarget objects

%   this will be the fixation point
arg_dXtarget = { ...
    'visible'       true, ...
    'y',            0, ...
    'x',            {0, -7}, ...
    'diameter',     0.8, ...
    'color',        red};

%   this will be the leftward target
% arg_dXtarget1 = { ...
%     'y',            0, ...
%     'x',            -2, ...
%     'diameter',     .2, ...
%     'color',        red};
% 
% %   this will be the rightward target
% arg_dXtarget2 = { ...
%     'y',            0, ...
%     'x',            2, ...
%     'diameter',     .2, ...
%     'color',        red};
 

% get parameters_and_values for two dXtext objects
%   these will give feedback to the subject after each trial
% arg_dXtext = { ...
%     'string',       {'pull left lever to begin', 'rest'}, ...
%     'color',        {red, red}, ...
%     'y',            5, ...
%     'x',            {-2.5, -3}};

% configure the rAdd_args.  This tells rAdd four things:
%   1. What group should these objects belong to?  'current' means add
%   objects to whatever group is currently active (e.g. the current task).
%
%   2. Should rAdd try to reuse existing objects of the same type?  If so,
%   rAdd will configure some existing objects rather than create new ones.
%
%   3. Should rAdd configure objects with rSet immediately upon creation?
%
%   4. Should rGroup reconfigure the object with rSet every time rGroup
%   activates this object (e.g. every time the task is activated)?
rAdd_args = {'current', false, true, false};

% the order of this list determines the layering of graphics onscreen
%   the top one here (i.e. dXtext) will be the top layer
graphics_ = { ...
%     'dXtext',	2,  rAdd_args,  arg_dXtext; ...
     'dXtarget',	2,  rAdd_args,	arg_dXtarget};
%      'dXtexture', 2,	rAdd_args,	arg_dXtexture};

    