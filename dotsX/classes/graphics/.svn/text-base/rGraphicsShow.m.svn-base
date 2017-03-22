function rGraphicsShow(varargin)
% function rGraphicsShow(varargin)
%
% Convenience routine to show/hide grapihcs objects;
%   that is, set 'visible' flag to true/false
%
% Arguments:
%   varargin ... List of class name + (optional)
%               index list ... empty cell array
%               indicates all subsequent arguments
%               set 'visible' to false
%               If no arg given, set to 'visible'
%               everything in ROOT_STRUCT.draw
% 
% Returns:
%   nada
%
% Examples:
%   {'<class1>', '<class2>', ...} 
%       Shows all objects per given class 
%   {{}, '<class1>', '<class2>', ...
%       Hides all objects per given class
%   {'<class1>', <indices>, {}, '<class2>', '<class3>'}
%       Shows <indices> objects of class1, hides
%           all objects of class2 and class3
%
%

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% no args, use ROOT_STRUCT.draw objects
if nargin == 0
    varargin = ROOT_STRUCT.methods.draw;
end

index = 1;
len   = length(varargin);
flag  = true;

while index <= len
    
    if isempty(varargin{index})
        
        % Empty cell indicates subsequent
        %   arguments set 'visible' to false
        flag  = false;

    else
        
        % get class name
        class_name = varargin{index};
        
        if index < len && isnumeric(varargin{index+1})
            
            % indices given
            ROOT_STRUCT.(class_name)(varargin{index+1}) = set( ...
                ROOT_STRUCT.(class_name)(varargin{index+1}), ...
                'visible', flag);
            index = index + 1;
            
        else
            
            % indices not given
            ROOT_STRUCT.(class_name) = set( ...
                ROOT_STRUCT.(class_name), 'visible', flag);
        end
    end
    
    % increment index into varargin cell array
    index = index + 1;
end
    
