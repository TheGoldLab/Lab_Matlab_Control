function drawNew(varargin)

% Get rid of mask, Show new Number... 
        
global ROOT_STRUCT
if isfield(ROOT_STRUCT, 'dXimage')
        rGraphicsShow( 'dXtext', 'dXtexture', 1, {}, 'dXtexture', 2, 'dXimage')
        rGraphicsDraw;
end