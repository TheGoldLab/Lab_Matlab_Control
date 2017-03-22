function dXROOT_makeMenu(parent,field,handles)
% function dXROOT_makeMenu(parent,field,handles)
%
% recursively make menus for all [nested] fields of a struct
%
% args:
%   parent  ... a graphics handle for a figure or uimenu
%   field   ... a struct or field to be parsed recursively,
%               start with ROOT_STRUCT
%   handles ... dXgui guihandles
%
% returns:  ... nun.

% 2006 Benjamin Heasly at University of Pennsylvania
sizfd = size(field);

if isempty(field)
    % base case for empty field

    % explain just how empty this field really is
    uimenu(parent,'Label',sprintf('empty %s',class(field)));

elseif isstruct(field) && isscalar(field)
    % recursive case for nested scalar struct

    % make submenus beneath this field's menu item

    % sort fieldnames like magic
    [menus, sep] = dXROOT_sortedFields(field);

    for n = 1:length(menus)

        % keep track of path descending into ROOT_STRUCT
        handles.pointer = cat(2,handles.pointer,menus(n));

        % make a new submenu and recur
        child = uimenu(parent,'Label',menus{n});

        % maybe make an awesome separator
        if sep(n)
            set(child,'Separator','on');
        end
        
        dXROOT_makeMenu(child,field.(menus{n}),handles);

        % back up one level in ROOT_STRUCT path
        handles.pointer = handles.pointer(1:end-1);
    end

elseif isstruct(field) && ~isscalar(field)
    % recursive case for nested struct array
    for ss = 1:length(field)
        % make a new submenu and recur
        child = uimenu(parent,'Label',sprintf('(%d)', ss));
        dXROOT_makeMenu(child,field(ss),handles);
    end


elseif iscell(field)
    %base case for cell

    % make a submenu with a string that summarizes the cell contents
    summ = '{';
    for n = 1:length(field)
        if ischar(field{n})
            summ = [summ, sprintf('''%s''  ',field{n})];
        elseif isnumeric(field{n})
            summ = [summ, sprintf('[%0.3f]  ',field{n})];
        else
            summ = [summ, sprintf('(%s)  ',class(field{n}))];
        end
    end
    summ(end) = '}';
    uimenu(parent, 'Label', summ);

elseif isobject(field)
    %convert objects to structs and recur
    dXROOT_makeMenu(parent,struct(field),handles);

else
    %base case for field with data

    format = [];
    switch class(field)

        case 'double'
            if (mod(field,1) ~= 0)
                format = '%0.4f';
            else
                format = '%d';
            end

        case 'logical'
            format = '%d';

        case 'char'
            format = '%s';

        case 'function_handle'
            format = '@%s';
            field = char(field);

        otherwise
            format = '%f';

    end

    if sizfd(1) == 1 && (sizfd(2) == 1 || ischar(field))

        % show single field value
        uimenu(parent,'Label',sprintf(format, field));

    else

        % show field values by row with tab-sep columns
        format = sprintf('%s, ',format);

        % in-trim big matrices
        if sizfd(1) > 20
            % trim inner rows
            fdrow = [1:10, sizfd(1)-9:sizfd(1)];
            showrow = [1:10, 12:21];
            show{11} = '...  ';
        else
            % all rows
            fdrow = 1:sizfd(1);
            showrow = 1:sizfd(1);
        end

        if sizfd(2) > 20
            % trim inner columns
            for r = 1:length(fdrow)
                show{showrow(r)} = [sprintf(format, field(fdrow(r),1:10)), ...
                    '..., ', sprintf(format, field(fdrow(r),end-9:end))];
            end
        else
            % all columns
            for r = 1:length(fdrow)
                show{showrow(r)} = sprintf(format, field(fdrow(r),:));
            end
        end

        % makem menues
        for r = 1:length(show)
            uimenu(parent,'Label',[show{r}(1:end-2), ';']);
        end
    end
end