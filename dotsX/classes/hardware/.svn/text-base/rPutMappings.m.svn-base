function rPutMappings(class_name, index, map)
% set DotsX hardware class input-output mappings

% copyright 2007 by Benjamin Heasly, University of Pennsylvania

global ROOT_STRUCT
[ROOT_STRUCT.(class_name)(index), ret, time] = ...
    putMap(ROOT_STRUCT.(class_name)(index), map);

% don't overwrite previous returns
if isempty(ROOT_STRUCT.jumpState)
    ROOT_STRUCT.jumpState = ret;
    ROOT_STRUCT.jumpTime = time;
end