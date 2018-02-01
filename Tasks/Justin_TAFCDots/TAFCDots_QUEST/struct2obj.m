function obj = struct2obj(struct,obj)

props = properties(obj);
mco = metaclass(obj);

fields = fieldnames(struct);

for ii = 1:length(fields) 
    propind = strcmp(props,fields{ii});
    if sum(propind)>0 && strcmp(mco.PropertyList(propind).SetAccess,'public')
        obj.(fields{ii}) = struct.(fields{ii});
    end
end
