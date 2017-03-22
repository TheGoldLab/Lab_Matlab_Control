function graphics_ = gXsimpleDemo_graphics(varargin)
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

% get parameters_and_values for one dXdots object
%   this will be the stimulus
arg_dXdots = { ...
    'x',            0, ...
    'y',            0, ...
    'diameter',     6, ...
    'size',         3, ...
    'speed',        5, ...
    'coherence',    100, ...
    'direction',    0, ...
    'density',      25, ...
    'wrapMode',     'wrap', ...
    'color',        [1 1 1 1]*255, ...
    'bgColor',      [0 0 0]};

% get parameters_and_values for one dXtarge object
%   this will be the fixation point
arg_dXtarget = { ...
    'y',            0, ...
    'x',            0, ...
    'diameter',     .2, ...
    'color',        blue};

% get parameters_and_values for two dXtext objects
%   these will give feedback to the subject after each trial
arg_dXtext = { ...
    'string',       {'correct', 'incorrect', 'invalid response!'}, ...
    'color',        {green, red, red}, ...
    'y',            5, ...
    'x',            {-2.5, -3, -5.5}};

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
    'dXtext',	3,  rAdd_args,  arg_dXtext; ...
    'dXdots',	1,  rAdd_args,	arg_dXdots; ...
    'dXtarget',	1,  rAdd_args,	arg_dXtarget; ...
    };