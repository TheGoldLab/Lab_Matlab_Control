classdef dotsDrawable < handle
    % @class dotsDrawable
    % Superclass for drawable graphics objects.
    % @details
    % Subclasses should redefine the draw() method to use specific OpenGL
    % drawing commands.  Most drawing commands should assume units of
    % degrees of visual angle, with the origin centered on the display.
    % This is because dotsTheScreen configures OpenGL to do a
    % pixels-per-degree transformation automatically.  This works for
    % commands that deal with the positions of points, lines, and
    % polygons.
    % @details
    % A few commands may need to assume units of pixels.  Theses should be
    % named and documented as exceptions to the rule.
    % @details
    % Subclasses may also redefine the prepareToDrawInWindow() method.
    % This should do any one-time or infrequent set up to enable
    % or optimize the behavior of draw().
    properties
        % true or false, whether to draw() this object
        isVisible = true;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawable()
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self, mc.defaultGroup);
        end
        
        % Do any pre-draw setup that requires an OpenGL drawing window.
        function prepareToDrawInWindow(self)
        end
        
        % Draw() or not, depending on isVisible and possibly other factors.
        function mayDrawNow(self)
            if self.isVisible
                self.draw;
            end
        end
        
        % Subclass must redefine draw() to draw graphics.
        function draw(self)
        end
        
        % Shorthand to set isVisible=true.
        function show(self)
            self.isVisible = true;
        end
        
        % Shorthand to set isVisible=false.
        function hide(self)
            self.isVisible = false;
        end
    end
    
    methods (Static)
        % draw() several drawable objects and show the next Screen frame.
        % @param drawables cell array of objects to draw()
        % @param doClear whether or not clear the Screen after this frame
        % @details
        % Invokes draw() on each of the objects in @a drawables, then
        % invokes nextFrame() on dotsTheScreen.  If provided, passes @a
        % doClear to nextFrame(), to determine whether to clear the OpenGL
        % frame buffer after displaying it.
        % @details
        % Returns a struct of frame timing information, as returned from
        % nextFrame().
        function frameInfo = drawFrame(drawables, doClear)
            % draw() each drawable
            for ii = 1:numel(drawables)
                drawables{ii}.mayDrawNow();
            end
            
            % swap OpenGL frame buffers
            theScreen = dotsTheScreen.theObject();
            if nargin >= 2
                frameInfo = theScreen.nextFrame(doClear);
            else
                frameInfo = theScreen.nextFrame();
            end
        end
    end
end