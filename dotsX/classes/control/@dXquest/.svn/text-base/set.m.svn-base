function q_ = set(q_, varargin)
%set method for class dXquest: specify property values and recompute dependencies
%   q_ = set(q_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of dXquest object(s).
%-% Recomputes internal values.
%-%
%----------Special comments-----------------------------------------------
%
%   See also set dXquest

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

% set the fields, one at a time...
for i = 1:2:nargin-1
    % change it
    if iscell(varargin{i+1})
        [q_.(varargin{i})] = deal(varargin{i+1}{:});
    else
        [q_.(varargin{i})] = deal(varargin{i+1});
    end
end

% check for total reset vs update
if any(isempty([q_.pdfPost]))

    % Initialize quest and forget past trials
    q_ = reset(q_);
end

% if plotting evolution of trials and threshold estimate,
%   keep track of a figure handle
if any([q_.showPlot])

    f = figure(9327);
    clf(f);
    [q_.fig] = deal(f);

    % trial placements and outcomes
    range = [min([q_.dBRange]), max([q_.dBRange])];
    dB = linspace(range(1), range(2), 5);
    [q_(1), stim] = dB2Stim(q_(1), dB);
    sp = subplot(2,1,1, 'Parent', f, ...
        'XLim', range, 'XTick', dB, 'XTickLabel', stim, ...
        'YLim', [0 1], ...
        'XGrid', 'on', 'YGrid', 'on');
    xlabel(sp, 'trial')
    ylabel(sp, 'P_C')

    % threshold pdf
    sp = subplot(2,1,2, 'Parent', f, ...
        'XLim', range, 'XTick', dB, 'XTickLabel', stim, ...
        'XGrid', 'on', 'YGrid', 'on');

    xlim(sp, [min([q_.dBRange]), max([q_.dBRange])]);
    xlabel(sp, 'T')
    ylabel(sp, 'f(T)')
end

% recompute speedy pointer info
if any(strcmp(varargin(1:2:end), 'ptr'))
    num_vars = length(q_);
    for qqq = 1:num_vars

        if isempty(q_(qqq).ptr)
            q_(qqq).ptrType  = 0;
            q_(qqq).ptrClass = [];
            q_(qqq).ptrIndex = [];
        else
            if isempty(q_(qqq).ptr{2})
                q_(qqq).ptrType = 1;
            else
                q_(qqq).ptrType = 2;
            end
            q_(qqq).ptrClass = q_(qqq).ptr{1};
            q_(qqq).ptrIndex = q_(qqq).ptr{2};
        end
    end
end
