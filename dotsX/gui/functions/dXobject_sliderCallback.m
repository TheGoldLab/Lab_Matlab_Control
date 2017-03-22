function dXobject_sliderCallback(obj, event, widge, indexMode)
% function dXobject_sliderCallback(obj, event, widge, mode)
%
% updates the text widget associated with a

if indexMode
    % slider indexes a cell array
    index = round(get(obj, 'Value'));

    % set the text widget's String with
    % a value from it's range
    range = get(widge,'UserData');
    set(widge,'String',range{index});

else
    % slider continuous between min and max

    % set text widget's string with slider value
    set(widge,'String',get(obj,'Value'));

end

% trigger the text widget's callback!  Hi-yah!
cb = get(widge,'Callback');
feval(cb{1},widge,[],cb{2:end});