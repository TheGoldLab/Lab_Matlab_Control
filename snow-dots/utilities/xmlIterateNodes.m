% Execute a function at each node of an xml tree.
% @param xNode the DOM node at the top on an xml tree
% @param nodeAction a function to execute at @a xNode and each of its
% descendents.  Should take a DOM node as the only argument.
% @details
% Used to iterate through all nodes of an xml tree, using Matlab's built-in
% DOM xml parser.  See "doc xmlread" for details about parsing xml files.
% @details
% When a node is encountered, invokes @a nodeAction, with the node as the
% only argument.  Then recursively visits the nodes children and their
% children, etc.  Thus, most of the behavior is left up to @a nodeAction.
% @details
% Since @a nodeAction is executed before trying to visit the next node,
% xmlIterateNodes is potentially suitable for parsing existing xml trees,
% or writing new ones on the fly.  The only requirement for writing is that
% @a nodeAction be smart enough to figure out what to do at each tree
% level: It should create new nodes in breadth-first order so that
% xmlIterateNodes can continue parsing in depth-first order.
%
% @ingroup dotsUtilities
function xmlIterateNodes(xNode, nodeAction)
if xNode.getNodeType == xNode.ELEMENT_NODE
    if nargin > 1
        feval(nodeAction, xNode)
    end
    if xNode.hasChildNodes
        xChild = xNode.getFirstChild;
        while ~isempty(xChild)
            xmlIterateNodes(xChild, nodeAction)
            xChild = xChild.getNextSibling;
        end
    end
end
