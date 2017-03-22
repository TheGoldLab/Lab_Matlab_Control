function dXobject_editField(obj, event, field, dXcopy,sbH)
% function dXobject_editField(obj, event, field, dXcopy,sbH)
%
% callback from widget to set dX___ object property
%
% Args:
%
%   field               ... struct with widget prescriptions
%       .name           ... string containing name of dX___ field
%       .data           ... data in fieldname
%       .safeType       ... string MATLAB class of data in fieldname
%       .userType       ... string user-defined type of fieldname or special flag
%       .range          ... cell containing constraints on field.data
%
%   dXcopy  ... copy of the dX___ instance to be modified
%
%   sbH     ... handle of the 'Reset' button of a dXobjectGUI instance
%
% Returns: bubkis, enqueues dX___/set args.
%
% 2006 Benjamin Heasly at University of Pennsylvania
global ROOT_STRUCT

% get new data from widget and cast to appropriate type
switch field.safeType

    case 'char'

        newData = get(obj,'String');

    case 'logical'

        newData = logical(get(obj,'Value'));
        set(obj,'String',newData);

    case 'function_handle'

        newData = str2func(get(obj,'String'));

    otherwise

        % get user entry from edit widget and cast to numeric type
        newData = feval(field.safeType,str2num(get(obj,'String')));

        % if can't cast 'String' to number, bail, git, outta, laytuh
        if isempty(newData)
            return
        end
end

doFlush = false;

% possibly insert new data into proper cell or struct, enqueue dX___/set
% args, and trigger an update immediately i.e. don't wait for [Set changes]
switch field.userType{1}
    case 'cell'
        cellData = get(dXcopy,field.name);
        cellData{field.userType{2}} = newData;
        newData = cellData;
        doFlush = true;
        
    case 'struct'
        structData = get(dXcopy,field.name);
        structData.(field.userType{2}) = newData;
        newData = structData;
        doFlush = true;
    case 'task'
        % get new taskfile name from dialog--hooya!
        suggestion = mfilename('fullpath');
        basei = strfind(suggestion,'/gui');
        suggestion = [suggestion(1:basei),'/tasks/*.*'];

        file = uigetfile('*.m','Pick a task', suggestion);
        [path,newData,ext] = fileparts(file);
        
        % get real
        if ~ischar(file) || ~exist(file)
            return
        end
        
        set(obj, 'String', newData);

        cellData = get(dXcopy,field.name);
        cellData{field.userType{2}} = newData;
        newData = cellData;
        doFlush = true;
end

% add {property, value} pair to the queue of 
% dX___/set argumnets stored in sbH.UserData
setArgs = {field.name, newData};
enqueFcn = get(sbH,'Callback');
feval(enqueFcn{1}, sbH, setArgs, doFlush, enqueFcn{3:end})