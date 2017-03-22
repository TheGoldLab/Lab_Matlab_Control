function rGraphicsSetDraw(class_name, indices, varargin)
% function rGraphicsSetDraw(class_name, indices, varargin)
%
% Sets value(s) for the graphic object(s) of the given class
%   with the given id(s).
% Then draws all objects (once). Assumes back buffer IS
%   cleared (i.e., dont_clear flag = false)
%

% Copyright 2004 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% call the class-specific set methods, saving the result
if isempty(indices)
    
    % all objects
    ROOT_STRUCT.(class_name) = ...
        set(ROOT_STRUCT.(class_name), varargin{:});
else

    % indexed objects
    ROOT_STRUCT.(class_name)(indices) = ...
        set(ROOT_STRUCT.(class_name)(indices), varargin{:});
end

% flip buffers
switch ROOT_STRUCT.screenMode
    
    case 0
        
        % debug mode, do nothing
        
    case 1

        % loop through the drawables
        % or just call rGraphicsDraw
        for dr = ROOT_STRUCT.methods.draw

            % call class-specific draw
            ROOT_STRUCT.(dr{:}) = draw(ROOT_STRUCT.(dr{:}));
        end

        % send done drawing command .. sometimes optimizes
        Screen('DrawingFinished', ROOT_STRUCT.windowNumber);

        % flip buffers (and clear, by default ...
        %   might want to change this)
        Screen('Flip', ROOT_STRUCT.windowNumber);

    case 2
        
        % remote mode
        sendMsgH('draw_flag=1;');
end
