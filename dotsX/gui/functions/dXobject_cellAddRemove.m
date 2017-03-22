function dXobject_cellAddRemove(obj, event, arH, sbH, field, dXcopy)
% function dXobject_cellAddRemove(obj, event, arH, field, dXcopy)
%
% Callback from widget to add or remove element(s) from a dX___ object
% property of type cell.
%
% Gets String from widget arH and converts with str2num.  Positive numbers
% are indices to insert or append to cell.  New elements will have the
% value of their lower neighbor--a safe default.  Negative numbers are
% indices to remove from cell.  Adds/appends, then removes.
%
% Args:
%
%   arH             ... handle of edit field with cell indices
%
%   sbH             ... handle of 'Set' button with setArg queue
%
%   field           ... struct with widget prescriptions
%       .name       ... string containing name of dX___ field
%       .data       ... data in fieldname
%       .safeType   ... string MATLAB class of data in fieldname
%       .userType   ... string user-defined type of fieldname or special flag
%       .range      ... cell containing constraints on field.data
%
%   dXcopy          ... copy of the dX___ instance to be modified
%
% Returns: bubkis, flushes queue of dX___/set args, updates dXobjectGUI
%
% 2006 Benjamin Heasly at University of Pennsylvania
global ROOT_STRUCT

% check and format string input from edit widget
celli = str2num(get(arH,'String'));
new = [];

% copy the cell from which to add/remove elements
cellData = get(dXcopy,field.name);

% define a new cell...
if isempty(cellData);
    new = inputdlg('Write out a new cell:', 'New cell', 3);
    if ~isempty(new)
        cellData = eval(new{1});
        if ~iscell(cellData)
            return
        end
    end
end

% ... or possibly edit and old cell
if ~isempty(celli) && isempty(new)
    lcd = length(cellData);

    % indices to insert are positive and in bounds
    addi = celli(celli > 0 & celli <= lcd);
    la = length(addi);

    if ~isempty(addi)
        % insert copied elements into the cellarray,
        % try to preserve organization of element types
        ins = logical(ones(1,lcd+la));
        ins(addi) = false;
        copyData = cellData(addi);
        cellData(ins) = cellData;
        cellData(addi) = copyData;
    end

    % indices to append are positive and out of bounds
    app = max(celli(celli > 0 & celli > lcd));

    if ~isempty(app)
        % add copied elements to end of cell array,
        if app <= 2*(lcd+la)
            % try to preserve organization of element types
            cellData(end+1:app) = cellData(2*end-app+1:end);
        else
            cellData(end+1:app) = cellData(end);
        end
    end

    % indices to remove are negative and in bounds
    rem = -celli(celli < 0 & celli >= -lcd);
    if ~isempty(rem)
        cellData(rem) = [];
    end
end

% add {property, value} pair to the queue of dX___/set
% argumnets stored in sbH.UserData
% this will rebuild the objectGUI figure.
setArgs = {field.name, cellData};
enqueFcn = get(sbH,'Callback');
feval(enqueFcn{1}, sbH, setArgs, true, enqueFcn{3:end});