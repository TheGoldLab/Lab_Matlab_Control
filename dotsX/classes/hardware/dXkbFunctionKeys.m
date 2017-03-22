function didPause = checkFunctionKeys(keyCode)
% function didPause = checkFunctionKeys(keyCode)
%
% Screens array of KbName-style keyCodes for pressed F-keys.  Allows
% user to pause, resume, quit, reset at any time when the kb is being
% queried during a task/paradigm--which is nearly all the time.  For
% example, dXparadigm/runTasks and dXGUI_sync pass keyCodes through this
% function to get fast interrupting behavior.
%
% The dXgui buttons can also access this function for interrupting behavior
% by fabricating appropriate keyCodes.  But they suffer the disadvantage of
% having to wait for a PAUSE or a DRAWNOW during which their callbacks can
% be dequeued and executed.
%
% Returns boolean allowing caller to do the right thing after a pause
%
% 2006 by Benjamin Heasly at University of Pennsylvania

% Keycodes 58-65 correspond to F1-F8

pTogg = [];
didPause = false;

% First, maybe do pause behavior
if any(keyCode==58)
    % 58 = F1 -> pause

    % is there a dXgui with a pause toggleButton?
    pTogg = findobj('Tag', 'pauseToggle');

    if isempty(pTogg)
        % no GUI.  wait around for F2, yield CPU/drawing time
        disp('PRESS F2 TO CONTINUE');
        global ROOT_STRUCT
        ROOT_STRUCT.dXkbHID = reset(ROOT_STRUCT.dXkbHID);
        while ~any(keyCode==59) && ~any(keyCode==60)
            HIDx('run');
            v = get(ROOT_STRUCT.dXkbHID, 'values');
            if ~isempty(v)
                keyCode = [keyCode, v(v(:,2)==1,1)'];
            end
            pause(.01);
        end

    elseif ishandle(pTogg)
        % yes GUI.  update the gui and stuff

        global ROOT_STRUCT
        handles = guidata(pTogg);
        sTogg = handles.stopToggle;

        % before anyone looks, update the ROOT_STRUCT menu
        delete(get(handles.rootStructMenu,'Children'));
        handles.pointer = {};
        dXROOT_makeMenu(handles.rootStructMenu, ROOT_STRUCT, handles);

        % refresh any object GUIs
        fig = findobj('Tag','objectFigure');
        if ~isempty(fig)
            for f = fig
                dXobject_makeWidgets(nan, [], f);
            end
        end

        % make the whole GUI look behave as paused
        set(pTogg, 'Value', true, 'String', 'paused...');
        set(handles.runDisable,'Enable','on');
        set(handles.f1orf2Text, 'String', 'F2');

        % wait around for F2 or pause button, yield CPU/drawing time
        disp('PRESS F2 OR PAUSE BUTTON TO CONTINUE');
        global ROOT_STRUCT
        ROOT_STRUCT.dXkbHID = reset(ROOT_STRUCT.dXkbHID);
        while ~any(keyCode==59) && ~any(keyCode==60)
            HIDx('run');
            v = get(ROOT_STRUCT.dXkbHID, 'values');
            if ~isempty(v)
                keyCode = [keyCode, v(v(:,2)==1,1)'];
            end
            keyCode = [keyCode, ...
                (~get(pTogg,'Value'))*59, get(sTogg,'Value')*60];
            pause(.01)
        end

        % make the whole GUI look and behave as not paused
        set(pTogg, 'Value', false, 'String', 'pause');
        set(handles.runDisable,'Enable','off');
        set(handles.f1orf2Text, 'String', 'F1');
    end
end

% Then, check for other keypresses
%   (which may have happened duting a pause)
if any(keyCode==60)
    % 60 = F3 -> stop

    % unpress dXgui buttons,
    set([findobj('Tag', 'pauseToggle'), ...
        findobj('Tag', 'startToggle'), ...
        findobj('Tag', 'stopToggle')], 'Value', false);

    error('USER QUIT')

elseif any(keyCode==59)
    % 59 = F2 -> resume

    didPause = true;
    disp('CONTINUING')

end