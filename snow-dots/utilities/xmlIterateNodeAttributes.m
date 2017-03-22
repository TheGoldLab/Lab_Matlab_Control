% Execute a function for each of an xml node's attributes.
% @param xNode a DOM xml node with attributes
% @param attributeAction a function to execute for each attribute of @a
% xNode.  Should take @a xNode and an attribute as the only two arguments.
% @details
% Used to iterate through all attributes of an xml tree node, using
% Matlab's built-in DOM xml parser.  See "doc xmlread" for details about
% parsing xml files.
% @details
% For the given @a xNode, simply loops through any attributes and invokes
% @a attributeAction with @a xNode and the attribute as the only two
% arguments.
%
% @ingroup dotsUtilities
function xmlIterateNodeAttributes(xNode, attributeAction)
xAttributes = xNode.getAttributes;
n = xAttributes.getLength;
for ii = 0:(n-1)
    a = xAttributes.item(ii);
    feval(attributeAction, xNode, a);
end