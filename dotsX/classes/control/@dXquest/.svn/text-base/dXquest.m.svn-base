function [q_, attributes_, batchMethods_] = dXquest(num_objects)
% function [q_, attributes_, batchMethods_] = dXquest(num_objects)
%
% Constructor method for class dXquest
%
% dXquest instances in the same group cooperate, act as one thing.
% Interface with dXquest(1).
%
% Arguments:
%   num_objects   ... number of objects to create
%
% Returns:
%   q_            ... array of created Quests
%   attributes_   ... default object attributes
%   batchMethods_ ...

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% default object attributes
attributes = { ...
    % name              type		ranges(?)	default
    'name',             'scalar',   [],         []; 	...
    'psycFunction',     'function_handle',[],   @dBWeibull; ... %on decibels
    'psychParams',      'array',	[],         [];     ... % arg to psycFunction
    'stimRange',        'arary',    [],         [1 10]; ... % [min,max] of possible T (stim units)
    'stimValues',       'scalar',   [],         [];     ... % discrete vals?
    'blankStim',        'scalar',   [],         [];     ... % for blank trials
    'refStim',          'scalar',   [],         5;      ... % for dB conversion
    'refExponent',      'scalar',   [],         20;     ... % for dB conversion
    'ptr',              'cell',     [],         [];     ... % {class,ind,prop}
    'override',         'scalar',   [],         [];     ... % replace value in stim units
    'estimateType',     'string',   {'mean', 'mode', 'quantile'}, 'mean';...
    'estimateQuantile',	'scalar',   [],         .5;     ...
    'guessStim',        'scalar',   [],         [];     ... % overrides T0, in stim units
    'T0',               'scalar',   [],         0;      ... % guess of T (dB), 0=refStim
    'Tstd',             'scalar',   [],         3;      ... % guess confidence (dB)
    'TGrain',           'scalar',   [],         .1;     ... % resolution of T estimate (dB)
    'pdfNorm',          'boolean',  [],         true;   ...
    'CIsignif',         'scalar',   [],         .95;    ... % convergence criterion
    'CIcritdB',         'scalar',   [],         1;      ... % convergence criterion
    'goPastConvergence','boolean',  [],         false;  ... % is done done?
    'FIRAdataType',     'string',   [],         'QUESTData'; ...
    'showPlot',         'boolean',  [],         false;  ... % plot trials and pdf?
    'doEndTrial',       'boolean',  [],         true;   ... % automatic update each trial?    
    'practiceTrials',   'scalar',   [],         0;      ... % number of practice trials to start
    'practiceValue',    'scalar',   [],         [];     ... % value to use for practice trials
    'practiceTrialCount',  'scalar',   [],         0;      ... % updated count of practice trials
    'overrideProbability', 'scalar',[],         0;      ... % probability of overriding quest value
    'overrideValue',    'scalar',   [],         [];     ... % value to use for override trials
    'overrideStorage',  'auto',     [],         [];     ... % values to store during override
    'overrideFlag',     'auto',     [],         false;  ... % values to store during override    
    'convergedAfter',   'auto',     [],         nan; 	... % when done?
    'goodTrialCount',   'auto',     [],         0;      ... % keep track of good trials (error + correct)
    'CIdB',             'auto',     [],         nan;    ... % attained width
    'dBRange',          'auto',     [],         [];     ... % [min,max] of possible T (dB)
    'dBDomain',         'auto',     [],         [];     ... % support for T estimate (dB)
    'stimDomain',       'auto',     [],         [];     ... % support for T estimate (stim units)
    'pdfPrior',         'auto',     [],         [];     ... % T guess distribution
    'pdfPost',          'auto',     [],         [];     ... % T guess and evidence
    'pdfLike',          'auto',     [],         [];     ... % T likelihood distribution
    'value',            'auto',     [],         nan;    ... % posterior T (stim units)
    'dBvalue',          'auto',     [],         nan;    ... % posterior T (dB)
    'estimateLike',     'auto',     [],         nan;    ... % likelihood T (stim units)
    'estimateLikedB',	'auto',     [],         nan;    ... % likelihood T (dB)
    'dBvalues',         'auto',     [],         [];     ... % converted from stimValues
    'previousValue',    'auto',     [],         nan;    ...
    'previousValuedB',	'auto',     [],         nan;    ...
    'ptrType',          'auto',     [],         [];     ...
    'ptrClass',         'auto',     [],         [];     ...
    'ptrIndex',         'auto',     [],         [];     ...
    'fig',              'auto',     [],         nan;    ...
    'plotStuff',        'auto',     [],         nan;    ...
    };

% make struct from defaults
sl = cell2struct(attributes(:,4), attributes(:,1), 1);
for i = 1:num_objects
    q_(i) = class(sl, 'dXquest');
end

% It returns the attributes.  It does this whenever it is asked.
if nargout > 1
    attributes_ = attributes;
end

% It returns a list of batch methods.  It does this whenever it is asked.
if nargout > 2
    batchMethods_ = {'control', 'update', 'endTrial', 'saveToFIRA'};
end