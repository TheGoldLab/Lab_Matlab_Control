function [a_, ret_, time_] = putMap(a_, map);
% change mappings, check against data for a jumpState

% clear auto fields
a_.checkList = [];
a_.checkRet  = {};
a_.default   = [];
a_.other     = [];

% Map is a list of {input, output, ...} pairs
%
% Eyetracker inputs are based on acceptance rectangles.  Each row of a
% numeric matrix is a separate entry.  A row may have the form,
%   [x,y,w,h,io,nt],
% where x and y are the coordinates in degrees of visual angle of the
% lower-left corner of a rectangle, and w and h are the rectangle's
% dimensions, also in degrees of visual angle.
%   A row may also have the form,
%   [index, io, nt],
% where index is the index of an active dXtarget object.  In this case, the
% acceptance rectangle is centered on 'x' and 'y' cordinates of the
% dXtarget object, and has width and height, in degrees of visual angle,
% equal to the 'diameter2' property of the dXtarget object.
%
% For either form, io is optional.  io=true (default) means we want eye
% position to end up inside the rectangle, io=false means we want the eye
% to end up outside the rectangle.
%
% nt is also optional.  nt specifies the number of transistions allowable to
% reach the position specified by io.
%   nt=0 means eye position never entered nor exited the rectangle.
%   nt=1 (default) means eye position entered or exited the recangle exactly
%   once, and remained there.
%   nt>=2 means eye position fluctuated with respect to the rectangle, and
%   ended up, after nt or fewer transitsions, in the position specified by
%   io.
%
% Each output should be a string state name.
for ii = 1:2:length(map) - 1

    if isnumeric(map{ii})

        % number of entries
        m = size(map{ii}, 1);

        % form of entries
        n = size(map{ii}, 2);

        % always want to end up with mx6
        cl = ones(m, 6);

        % rectangle(s) from dXtarget(s)?
        if n <= 3

            % fill in rectangle(s) from dXtarget properties
            dXt = rGet('dXtarget', map{ii}(:,1));
            cl(:,1:4) = [[dXt.x]' - [dXt.diameter2]'/2, ...
                [dXt.y]' - [dXt.diameter2]'/2, ...
                [dXt.diameter2]', [dXt.diameter2]'];
        end

        % use defaults io and nt?
        switch n

            case 1
                % dXtarget index
                %   got rect from dXtarget
                %   let io=true, nt=1, from ones()

            case 2
                % dXtarget index
                %   got rect from dXtarget
                %   let io=true, from ones
                %   get nt from map{ii}
                cl(:,5) = map{ii}(:,2);

            case 3
                % dXtarget index
                %   got rect from dXtarget
                %   get io and nt from map{ii}
                cl(:,5:6) = map{ii}(:,2:3);

            case 4
                % arbitrary rectangle
                %   get rect from map{ii}
                %   let io=true, nt=1, from ones()
                cl(:,1:4) = map{ii};

            case 5
                % arbitrary rectangle
                %   get rect and io from map{ii}
                %   let nt=1, from ones()
                cl(:,1:5) = map{ii}(:,1:5);

            case 6
                % arbitrary rectangle
                %   get rect, io, and nt from map{ii}
                cl(:,1:6) = map{ii}(:,1:6);

            otherwise continue
        end

        a_.checkList = cat(1, a_.checkList, cl);
        a_.checkRet = ...
            cat(1, a_.checkRet, repmat(map(ii+1), m, 1));

    elseif ischar(map{ii})
        if strcmp(map{ii}, 'none')
            a_.default = map{ii+1};
        elseif strcmp(map{ii}, 'any')
            a_.other   = map{ii+1};
        end
    end
end

% optional trailing value is boolean for ignore previous hardware values
if mod(length(map), 2) && isscalar(map{end}) && map{end}
    a_.recentVal = size(a_.values, 1) + 1;
end

% plot rectangles that correspond to eye pos acceptance rectangles
if a_.showPlot && ~isempty(a_.checkList)

    for ii = 1:size(a_.checkList,1)
        cl = a_.checkList(ii,:);
        if isscalar(a_.ax)                            % MN 8/16/09 got rid of parent...
            rectangle('Position', cl(1:4), 'Parent', a_.ax, ...
                'EdgeColor', [cl(5)==1 cl(6)==1 1]);
        else
            rectangle('Position', cl(1:4), 'EdgeColor', [cl(5)==1 cl(6)==1 1]);
        end
    end
end

% check new mappings against existing data
[a_, ret_, time_] = getJump(a_);