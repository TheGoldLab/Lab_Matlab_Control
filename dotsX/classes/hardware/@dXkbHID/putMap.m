function [kb_, ret_, time_] = putMap(kb_, map)
% change mappings, check against data for a jumpState

% clear auto fields
kb_.checkList = [];
kb_.checkRet  = {};
kb_.default   = [];
kb_.other     = [];

% re-compute kb_.checkList and kb_.checkRet from cell array map
%   mappings are {input, output, ...}
%   output is a string state name
%   each input is key or {key, value}
%   value is scalar, probably 1 or 0 for press or release
%   key is a char array, cell array of strings, or a numeric array:
%   rows of a char array are separate entries, e.g. 'a     ;Return'.
%   elements of a cell array of strings are separate entries
%   strings converted to keycodes
%   numbers are treated as keycodes
%   see KbName.m for key string names and numeric keycodes
for ii = 1:2:size(map, 2) - 1

    % parse input specifier
    if iscell(map{ii}) && numel(map{ii})==2 && isnumeric(map{ii}{2})
        % input is {key, value}
        key = map{ii}{1};
        value = map{ii}{2};
    else
        % input is key, value defaults to 1 for press
        key = map{ii};
        value = 1;
    end

    if ischar(key)
        % key is a char array of key string names
        %   get one key per row
        for jj = 1:size(key,1)
            k = deblank(key(jj,:));
            if strcmp(k, 'none')
                kb_.default = map{ii+1};
            elseif strcmp(k, 'any')
                kb_.other = map{ii+1};
            else
                % convert name to keycode(s), use only first keycode
                k = KbName(k);
                kb_.checkList = cat(1, kb_.checkList, [k(1), value]);
                kb_.checkRet = cat(1, kb_.checkRet, map(ii+1));
            end
        end

    elseif iscell(key)
        % key is a cell array of key string names
        %   get one key per element
        for jj = 1:length(key)
            k = deblank(key{jj});
            if strcmp(k, 'none')
                kb_.default = map{ii+1};
            elseif strcmp(k, 'any')
                kb_.other = map{ii+1};
            else
                % convert name to keycode(s), use only first keycode
                k = KbName(k);
                kb_.checkList = cat(1, kb_.checkList, [k(1), value]);
                kb_.checkRet = cat(1, kb_.checkRet, map(ii+1));
            end
        end

    elseif isnumeric(key)
        % key is a numeric array of keycodes
        %   duplicate values and output string for all keycodes listed
        kb_.checkList = cat(1, kb_.checkList, ...
            [reshape(key, numel(key),1), repmat(value, numel(key), 1)]);
        kb_.checkRet = cat(1, kb_.checkRet, ...
            repmat(map(ii+1), numel(key), 1));
    end
end

% optional trailing value is boolean for ignore previous hardware values
if mod(length(map), 2) && isscalar(map{end}) && map{end}
    kb_.recentVal = size(kb_.values, 1) + 1;
end

% check new mappings against existing data
[kb_, ret_, time_] = getJump(kb_);