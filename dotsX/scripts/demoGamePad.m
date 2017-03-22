% demo a joystick
global ROOT_STRUCT
rInit('debug');

% how to find compatible device:

% get any device that thinks its a "Joystick" or a "Gamepad"
%HIDCriteria.usageName = 'Joystick';
HIDCriteria.usageName = 'GamePad';

% get basic gamepad info
rAdd('dXgameHID', 1, 'HIDCriteria',  HIDCriteria);
elements = rGet('dXgameHID', 1, 'HIDElementsInfo');
elName = {elements.usageName};
elType = [elements.type];
elMax = [elements.max];
elMin = [elements.min];

% set up mappings for buttons:
%   just list the element indexes of the button elements,
%   and say that a "hit" means the value of that element goes to 1
bInds = find(elType == 2);
bMap = {};
for ii = bInds
    bMap = cat(2, bMap, [ii, elMax(ii)], elName{ii});
end

% set up mappings for axes:
%   partition the range of each element into thirds
%   top third means "high", bottom third means "low"
axInds = find(elType == 1);
axMap = {};
for ii = axInds

    % for "up"
    third = [elMax(ii) - elMin(ii)] / 3;
    axMap = cat(2, axMap, [ii, elMax(ii)-third, elMax(ii)], ...
        sprintf('%s HIGH', elName{ii}));

    % for "down"
    axMap = cat(2, axMap, [ii, elMin(ii), elMin(ii)+third], ...
        sprintf('%s LOW', elName{ii}));
end

% set mappings that identify joystick elements
rSet('dXgameHID', 1, 'mappings', cat(2, bMap, axMap));

% display HID events until button #1 is pressed
disp('Press some buttons.  Button #1 should quit.')
ROOT_STRUCT.jumpState = [];
while true

    % check for HID events, mapping returns
    HIDx('run')
    if ~isempty(ROOT_STRUCT.jumpState)

        % what happened?
        disp(ROOT_STRUCT.jumpState)

        % quit on button # 1
        if strcmp(ROOT_STRUCT.jumpState, elName(bInds(1)))
            break
        end

        % check anew
        ROOT_STRUCT.jumpState = [];
        %disp(rGet('dXgameHID', 1, 'values'))
        rSet('dXgameHID', 1, 'values', []);
    end

    % don't bog the system
    WaitSecs(.005);
end

rDone