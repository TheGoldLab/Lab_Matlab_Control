function rHIDPutValues(class_name, index, values)
%HID devices automatically dump asynchronous event data here

% It goes like this:
%   -HID deviced are added to the CFRunLoop, which automatically detects
%   new-data-events and triggers a callback.
%   -the device-specific callback decodes and formats event data and sends
%   it to this function.
%   -this function gets the appropriate class instance and feeds the new
%   data to the class-specific putValues method, which should append new
%   values and check values agains input-output mappings.

% copyright 2007 by Benjamin Heasly, University of Pennsylvania

global ROOT_STRUCT
[ROOT_STRUCT.(class_name)(index), ret, time] = ...
    putValues(ROOT_STRUCT.(class_name)(index), values);

% don't overwrite previous returns
if isempty(ROOT_STRUCT.jumpState)
    ROOT_STRUCT.jumpState = ret;
    ROOT_STRUCT.jumpTime = time;
end