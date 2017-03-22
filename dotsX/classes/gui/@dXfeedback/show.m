function fb_ = show(fb_, doTask, doParadigm)
%show feedback to subject
%   fb_ = show(fb_)
%
%   fb_         ... an instance of dXfeedback.
%   dotask      ... boolean whether to show feedback for the current task
%   doparadigm  ... boolean whether to show feedback for the whole paradigm
%
%
%   Updated class instances are always returned.
%
%   See also dXfeedback/endTrial dXfeedback

% Copyright 2007 by Bemjamin Heasly
%   University of Pennsylvania

if nargin < 2 || isempty(doTask)
    doTask = true;
end
if nargin < 3 || isempty(doParadigm)
    doParadigm = true;
end

if ~(doTask || doParadigm)
    return
end

global ROOT_STRUCT

% copy of the paradigm properties, for easy access
dXp = struct(ROOT_STRUCT.dXparadigm(1));

% get the same 'now' time for paradigm-level statistics
totalClock = clock - dXp.sessionTime;
totalMins = sum(totalClock(4:6).*[60, 1, 1/60]);

% Use dXtext in the intertrial interval group
rGroup(fb_.groupName);

% Fill out dXtext instances with feedback
%   from paradigm and/or current task
num_showing = 0;

% feedback for the current task?
if doTask
    taskName = rGet('dXtask', dXp.taski, 'name');
    taskMins = (GetSecs - rGet('dXtask', dXp.taski, 'startTime'))/60;
    [fb_, num_showing] = ...
        writeToText(fb_, dXp, num_showing, taskName, taskMins);

    % color code the feedback as task-specific
    if num_showing
        rSet('dXtext', fb_.dXtextInstances(1:num_showing), ...
            'color', fb_.tasksColor);
    end
end

% feedback for the total of all trials?
if doParadigm
    last = num_showing;
    [fb_, num_showing] = ...
        writeToText(fb_, dXp, num_showing, 'total', totalMins);

    % color code the feedback as general-interest
    if num_showing - last > 0
        rSet('dXtext', fb_.dXtextInstances(last+1:num_showing), ...
            'color', fb_.totalsColor);
    end
end


% clear the screen before showing feedback?
if fb_.preBlank
    rGraphicsBlank;
    rGraphicsDraw;
end

% show and horizontally center dXtext instances
if ~num_showing

    return

elseif num_showing == 1

    % avoid cell in single case
    rSet('dXtext', fb_.dXtextInstances(1), 'visible', true, 'y', 0);

    % set remaining to invisible!
    rSet('dXtext', fb_.dXtextInstances(2:end), 'visible', false);


elseif num_showing > 1

    % center all the used texts
    rSet('dXtext', fb_.dXtextInstances(1:num_showing), ...
        'visible',  true, ...
        'y',        num2cell(((1:num_showing)-num_showing/2)*-fb_.yScale));

    % set remaining to invisible!
    if num_showing < length(fb_.dXtextInstances)
        rSet('dXtext', fb_.dXtextInstances(num_showing+1:end), ...
            'visible', false);
    end
end



% show the feedback!
% check for timeout and hardware query
rGraphicsDraw();

% are we checking hardware, or just the clock?
timeout = GetSecs + fb_.displaySecs;
if iscell(fb_.query) && ~isempty(fb_.query)

    % wait just a little for e.g. levers to return to set position
    WaitSecs(.1);

    %checking hardware with a query mapping
    query_list = {};
    hid_list   = {};
    for ii = 1:size(fb_.query, 1)
        if isfield(ROOT_STRUCT, fb_.query{ii, 1})

            % get rid of old events,
            ROOT_STRUCT.(fb_.query{ii, 1}) = reset( ...
                ROOT_STRUCT.(fb_.query{ii, 1}));

            % set any response mapping,
            %   but all responses have the same result: continue.
            ROOT_STRUCT.(fb_.query{ii, 1}) = putMap( ...
                ROOT_STRUCT.(fb_.query{ii, 1}), fb_.query{ii, 2});

            % keep track of active queryable objects
            if ismethod(fb_.query{ii, 1}, 'query')
                query_list = cat(2, query_list, fb_.query{ii, 1});
            elseif ~isempty(strfind(fb_.query{ii, 1}, 'HID'))
                hid_list = cat(2, hid_list, fb_.query{ii, 1});
            end
        end
    end

    % wait for clock and check hardware
    ROOT_STRUCT.jumpState = [];
    while GetSecs < timeout
        % check hardware and short circuit when any device gets a hit
        HIDx('run')
        for ql = query_list
            [ROOT_STRUCT.(ql{1}), ROOT_STRUCT.jumpState, ...
                ROOT_STRUCT.jumpTime] = query(ROOT_STRUCT.(ql{1}));
        end

        if ~isempty(ROOT_STRUCT.jumpState)
            break
        end
        WaitSecs(.002);
    end

    % wait just a little for e.g. levers to return to set position
    WaitSecs(0.75);
    for ql = query_list
        ROOT_STRUCT.(ql{1}) = reset(ROOT_STRUCT.(ql{1}));
    end
    for hl = hid_list
        ROOT_STRUCT.(hl{1}) = reset(ROOT_STRUCT.(hl{1}));
    end
else

    % only checking clock
    while GetSecs < timeout
        WaitSecs(.002);
    end
end

% clear the screen after feedback?
if fb_.postBlank
    rGraphicsBlank;
    rGraphicsDraw;
end
