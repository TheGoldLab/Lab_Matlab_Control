% Demonstrate how to get exclusive access to a HID device.
% @details
% Human Interface Devices (HIDs) can be accessed in two ways: exclusive
% access means that only Matlab will see data coming from the device;
% regular access (which is the default) means that data can be
% shared by Matlab, other applications, and the operating system.
% @details
% dotsReadableHID classes allow exclusive and regular access.  This demo
% shows how to choose one or the other, in the case of a mouse and
% dotsReadableHIDMouse.
%
% @ingroup dotsDemos
function demoExclusiveHID()

% First get a mouse object.
m = dotsReadableHIDMouse();

% If more than one mouse is plugged in, try to specify one mouse in
% particular.  See mexHIDScout() for data that can be used to specify
% individual devices.
% prefs.VendorID = 1452;
% prefs.ProductID = 553;
% m.devicePreference = prefs;

% choose whether to get exclusive access or regular access.
m.isExclusive = true;

% reinitialize the mouse object with device preferences and access type
m.initialize();

% try moving the mouse around, and note whether or not the operating system
% cursor moves
m.plotData();

% release operating system HID resources
mexHID('terminate');