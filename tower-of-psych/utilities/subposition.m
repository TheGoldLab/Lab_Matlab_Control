% Get a rectangular sub-region of a rectangle.
% @param postion 1x4 matrix that defines a rectangle, [x y w h]
% @param r the number of rows to divide @a position into
% @param c the number of columns to divide @a position into
% @param ii the row index of the desired sub-region
% @param jj the column index of the desired sub-region
% @details
% Returns an array of the form [x y w h] which defines the rectangular
% subregion found at the iith row and jjth column of @a position.
% @details
% subposition() is similar to the Matlab's built-in subplot(), but it
% operates on position rectangles (that is, arrays) rather than Matlab
% graphics objects.
%
% @ingroup topsUtilities
function subpos = subposition(position, r, c, ii, jj)
w = position(3)/c;
h = position(4)/r;
subpos = [position(1)+(jj-1)*w, position(2)+(ii-1)*h, w, h];