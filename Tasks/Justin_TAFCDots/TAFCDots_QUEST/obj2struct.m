function struct = obj2struct(obj)

props = properties(obj);
values = cell(size(props));
for ii = 1:numel(props)
    values{ii} = obj.(props{ii});
end

struct = cell2struct(values, props);