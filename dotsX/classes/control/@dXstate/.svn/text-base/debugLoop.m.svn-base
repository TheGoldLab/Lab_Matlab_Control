function outcome_ = debugLoop(states, timeout, fig)
% function outcome_ = debugLoop(states, timeout, fig)
%
% Arguments:
%   states  ... array of dXstate objects
%   timeout ... optional arg (in secs)
%   fig     ... handle of the dXstateGUI for current task
%
% Returns:
%   outcome__ ... nx5 cell array, rows are states, columns are:
%       - state name
%       - time of state creation
%       - time just after state eval
%       - time just after (first) flip
%       - time returned by check, if any (i.e., if it causes a
%           jump to the next state)
%       - list of times (between VBLs)
%           corresponding to dropped frames
%   First state includes two times,
%       absolute time (from GetSecs) of beginning of loop,
%       and absolute time (from GetSecs) of wrt event
%       (see below)

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% check args
if nargin < 2 || isempty(timeout)
    timeout = inf;
end

% return/status/useful variables
wn               = ROOT_STRUCT.windowNumber;	% for speed
screenMode       = ROOT_STRUCT.screenMode;      % for speed
draw_list        = ROOT_STRUCT.methods.draw;	% for speed
blank_list       = ROOT_STRUCT.methods.blank;	% for speed
query_list       = ROOT_STRUCT.methods.query;	% for speed
wait_end         = 0;
wait             = 0;
last_time        = 0;
frame_pd         = 1.05./rGet('dXscreen', 'frameRate'); % 5% tolerance on VBL time
num_states       = size(states, 1);
sli              = 1;
state_names      = {states.name};
state            = struct('reps', 0, 'jump', state_names{1}, 'draw', 0);
outcome_         = cell(num_states+1, 6);
start_time       = GetSecs;
outcome_(1, 1:3) = {'start', start_time, start_time};
time_of_return   = 1;
time_of_flip     = 0;
lastFlipCleared  = false;

% call soft "reset" helpers (with start time arg)
rBatch('reset', [], start_time);

% Should be <5 ms up to this point

% bring the dXstateGUI for this current task to the top
figure(fig);
handles = guidata(fig);
buttons = [handles.rowBook.name];
redState = [];

% start the loop
while 1

    % Check for return message, if wait time is done
    %   and we are in remote mode
    if wait <= 0 && isnan(time_of_return)

        % wait for return message -- timestamp
        time_of_return = getMsgH(500);

        if isempty(time_of_return)
            warning('Oops!.  Did not get a return from client in 500ms!')
        end

        % if there is more time to wait, then wait...
        % conditionalization ensures that we do NOT do this
        %   if we got a return message from a QUERY (see below)
        if wait_end ~= 1
            wait_end = wait_end + (time_of_return - outcome_{sli, 4});
            wait     = 1;
        end

        % store new value
        outcome_{sli, 4} = time_of_return;
    end


    %%%
    %% conditionally execute current state (if done waiting)
    %%%
    if wait <= 0

        % restore draw flag
        if state.draw < 0
            state.draw = -state.draw;
        end

        % conditionally get state from name
        if state.reps > 0

            % Still have repetitions, redo state
            state.reps = state.reps - 1;

        else

            % get the next state
            Lstate = strcmp(state.jump, state_names);
            if any(Lstate)

                % got the state
                state = states(Lstate);
                % disp(state.name)

                % highlight current state name in dXstateGUI
                set(buttons(redState), 'ForegroundColor', [0,0,1]);
                set(buttons(Lstate), 'ForegroundColor', [1,0,0]);
                redState = Lstate;

                % Drawing takes time.  Hence this separaete debugLoop.
                drawnow;

                %%
                % check for conditionalizations, of the form:
                % state.cond = { ...
                % {'<field>', {<'class'>, <inds>, <prop>}, [vals], {replacements}; ...
                %  ... }
                %
                % if [vals] is empty, assume that the "pointer" (arg 2)
                %   returns the new value directly
                if ~isempty(state.cond)

                    if size(state.cond, 1) == 1

                        % one conditionalization, avoid loop
                        if isempty(state.cond{3})

                            % get the new value
                            state.(state.cond{1}) = get(ROOT_STRUCT.(state.cond{2}{1}) ...
                                (state.cond{2}{2}), state.cond{2}{3});
                        else

                            % compare the return value to the 'vals' array
                            Lptr = get(ROOT_STRUCT.(state.cond{2}{1})(state.cond{2}{2}), ...
                                state.cond{2}{3}) == state.cond{3};

                            if any(Lptr)

                                % found conditional replacement
                                state.(state.cond{1})= state.cond{4}{Lptr};

                            end
                        end

                    else % if size(state.cond, 1) > 1

                        % multiple conditionalizations, use loop
                        for ii = 1:size(state.cond, 1)

                            if isempty(state.cond{ii, 3})

                                % get the new value
                                state.(state.cond{ii, 1}) = ...
                                    get(ROOT_STRUCT.(state.cond{ii, 2}{1}) ...
                                    (state.cond{ii, 2}{2}), state.cond{ii, 2}{3});
                            else

                                % compare the return value to the 'vals' array
                                Lptr = get(ROOT_STRUCT.(state.cond{ii, 2}{1})(state.cond{ii, 2}{2}), ...
                                    state.cond{ii, 2}{3}) == state.cond{ii, 3};

                                if any(Lptr)

                                    % found conditional replacement
                                    state.(state.cond{ii, 1}) = state.cond{ii, 4}{Lptr};
                                end
                            end
                        end
                    end
                end % conditionalization

                %%
                % check for query mappings
                %
                % state.query can be:
                %   a cell array, used to set mappings (then set to true)
                %   true  ... use existing mappings, query this state
                %   false ... no query this state
                if iscell(state.query)

                    if size(state.query, 1) == 1

                        % set mappings, avoid loop. always assume
                        % one object
                        ROOT_STRUCT.(state.query{1}) = set( ...
                            ROOT_STRUCT.(state.query{1}), 'mappings', ...
                            state.query{2});

                    else % if size(state.query, 1) > 1

                        % set mappings with loop
                        for ii = 1:size(state.query, 1)

                            ROOT_STRUCT.(state.query{ii, 1}) = set( ...
                                ROOT_STRUCT.(state.query{ii, 1}), 'mappings', ...
                                state.query{ii, 2});
                        end
                    end

                    % set flag
                    state.query = true;
                end

            else

                % no state found, break ...
                break
            end
        end

        % save the name, current time
        sli = sli + 1;
        if sli > size(outcome_, 1)
            outcome_ = cat(1, outcome_, cell(num_states, 6));
        end
        outcome_(sli, 1:2) = {state.name, GetSecs};

        %%%
        % EVALUATE STATE!!!!!!
        %%%
        if ~isempty(state.func)
            % disp(sprintf('******<%s>******', func2str(state.func)))
            feval(state.func, state.args{:});
        end

        % save the current time
        outcome_{sli, 3} = GetSecs;

        % check for timeout
        if (outcome_{sli, 3} - start_time) > timeout
            break
        end

        % reset wait_end time
        wait_end = 0;
    end

    %%%
    %% Conditionally Draw
    %%%
    if state.draw > 0

        switch screenMode

            case 0

                % Debug only, just get current time (used below)
                current_time = GetSecs;

            case 1

                % Flip ... using 'state.draw' as a flag whether
                %   or not to clear the screen; specifically:
                %   draw = 0 ... no draw
                %   draw = 1 ... draw, clear buffer
                %   draw = 2 ... draw, do NOT clear buffer
                %   draw = 3 ... draw ONCE, clear buffer
                %   draw = 4 ... draw ONCE, do NOT clear buffer
                %   draw = 5 ... flip/clear buffers, call blank
                % Return args from Flip are:
                %   current_time    ... estimate of time of flip
                %   ot              ... estimate of stimulus onset time
                %   ft              ... time at end of Flip's execution
                %   m
                switch state.draw

                    case 1
                        for dl = draw_list
                            ROOT_STRUCT.(dl{:}) = draw(ROOT_STRUCT.(dl{:}));
                        end
                        [time_of_flip, ot, ft, m] = ...
                            Screen('Flip', wn, 0, 0);
                        lastFlipCleared = true;

                    case 2
                        for dl = draw_list
                            ROOT_STRUCT.(dl{:}) = draw(ROOT_STRUCT.(dl{:}));
                        end
                        [time_of_flip, ot, ft, m] = ...
                            Screen('Flip', wn, 0, 1);
                        lastFlipCleared = false;

                    case 3
                        for dl = draw_list
                            ROOT_STRUCT.(dl{:}) = draw(ROOT_STRUCT.(dl{:}));
                        end
                        [time_of_flip, ot, ft, m] = ...
                            Screen('Flip', wn, 0, 0);
                        state.draw = 0;
                        lastFlipCleared = true;

                    case 4
                        for dl = draw_list
                            ROOT_STRUCT.(dl{:}) = draw(ROOT_STRUCT.(dl{:}));
                        end
                        [time_of_flip, ot, ft, m] = ...
                            Screen('Flip', wn, 0, 1);
                        state.draw = 0;
                        lastFlipCleared = false;

                    case 5
                        [time_of_flip, ot, ft, m] = ...
                            Screen('Flip', wn, 0, 0);
                        if ~lastFlipCleared
                            [time_of_flip, ot, ft, m] = ...
                                Screen('Flip', wn, 0, 0);
                        end
                        for bl = blank_list
                            ROOT_STRUCT.(bl{:}) = blank(ROOT_STRUCT.(bl{:}));
                        end
                        state.draw = 0;
                        lastFlipCleared = true;
                end

                % check for dropped frames
                if last_time && time_of_flip - last_time > frame_pd

                    % if the time since last VBL is greater than the
                    % frame period (with tolerance defined above), save
                    %   the actual frame period
                    outcome_{sli, 6} = cat(1, outcome_{sli, 6}, ...
                        time_of_flip - last_time);
                end

                % save most recent time
                last_time = time_of_flip;

            case 2

                % Draw remotely
                sendMsgH(sprintf('draw_flag=%d;', state.draw));
                state.draw     = -state.draw; % send once
                time_of_flip   = GetSecs;     % flag to check for return message
                time_of_return = nan;
        end

        % save current time in dXtask
        if isempty(outcome_{sli, 4})
            outcome_{sli, 4} = time_of_flip; % system vbl timestamp
        end

    else % state.draw == 0

        % pseudo 'time_of_flip' needed for wait time in non-draw states
        time_of_flip = GetSecs;

        % pause briefly
        WaitSecs(0.0015);

        % reset last time (i.e., don't check for dropped frames)
        last_time = 0;
    end

    %%%
    %% conditionally query UI
    %%%
    if state.query

        % loop through each ui name
        for ql = query_list

            % !! EVALUATE UI CHECK !!
            [ROOT_STRUCT.(ql{:}), ret, time] = query(ROOT_STRUCT.(ql{:}));

            % query ret value for state jump
            if ~isempty(ret)

                % disp(sprintf('query <%s>, time <%d>, ret <%s>', ql{:}, time, ret))

                % save time in outcome_
                outcome_{sli, 5} = time;

                % jump state (now)
                state.jump = ret;
                state.reps = 0;
                wait_end   = 1;
                break
            end
        end
    end

    % initialize/update wait times
    if wait_end
        wait = wait_end - GetSecs;
    else
        if isscalar(state.wait)
            wait = state.wait*0.001;
        else
            wait = getRandomNumber(state.wait);
        end
        wait_end = time_of_flip + wait;
    end
end

% Don't forget to dehighlight the last state button
set(buttons(redState), 'ForegroundColor', [0,0,1]);

% save only filled-in portion of outcome_
outcome_ = outcome_(1:sli,:);