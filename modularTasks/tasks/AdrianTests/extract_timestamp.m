function ts = extract_timestamp(tn)
% returns the timestamp as a string 'YYYY_MM_DD_HH_mm' associated with
% the topsTreeNodeTopNode object tn
ts = regexprep(tn.filename, ...
    '[^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}]', '');
ts = ts(1:16);
end