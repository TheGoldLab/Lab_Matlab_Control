function rgb_ = colorRGB(colorName)
% function rgb_ = colorRGB(colorName)
%
% Simple utility to get RGB values from color string

if isnumeric(colorName)
   rgb_ = colorName;
   return
end

switch colorName
   case 'r'
      rgb_ = [1 0 0];
      return
   case 'g'
      rgb_ = [0 1 0];
      return
   case 'b'
      rgb_ = [0 0 1];
      return
   case 'y'
      rgb_ = [1 1 0];
      return
   case 'm'
      rgb_ = [1 0 1];
      return
   case 'c'
      rgb_ = [0 1 1];
      return
   case 'w'
      rgb_ = [1 1 1];
      return
   otherwise
      rgb_ = [0 0 0];
      return
end      
