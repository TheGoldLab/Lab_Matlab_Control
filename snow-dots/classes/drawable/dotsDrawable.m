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
      
      % Convenient utility for combining a bunch of drawables into an ensemble
      %
      % Aguments:
      %  name           ... optional <string> name of the ensemble/composite
      %  objects        ... cell array of drawable objects
      %
      function ensemble = makeEnsemble(name, objects)
         
         if isempty(name)
            name = 'drawable';
         end
         
         % Check dotsTheScreen for the screenEnsemble
         screenEnsemble = dotsTheScreen.theEnsemble();
         if isempty(screenEnsemble) || ~isa(screenEnsemble, 'dotsClientEnsemble')
            % Local
            remoteInfo = {false};
         else
            % Remote
            remoteInfo = {true, ...
               screenEnsemble.clientIP, ...
               screenEnsemble.clientPort, ...
               screenEnsemble.serverIP, ...
               screenEnsemble.serverPort};
         end
         
         % create the ensemble
         ensemble = dotsEnsembleUtilities.makeEnsemble([name 'Ensemble'], remoteInfo{:});
         
         % add the objects
         for ii = 1:length(objects)
            ensemble.addObject(objects{ii});
         end
         
         % Automate drawing
         ensemble.automateObjectMethod('draw', @mayDrawNow);
      end
      
      % Convenient utility for drawing an ensemble
      %
      % Aguments:
      %  ensemble    ... the ensemble
      %  args        ... cell array of cell arrays of property/value pairs
      %                    for each object in the ensemble
      %  prepareFlag ... whether to call prepareToDrawInWindow
      %  showDuration ... in sec
      %  pauseDuration ... in sec
      %
      function frameInfo = drawEnsemble(ensemble, args, prepareFlag, showDuration, pauseDuration)
         
         % Arguments given?
         if nargin >= 2 && ~isempty(args)
            for ii = 1:length(args)
               for pp = 1:2:length(args{ii})
                  ensemble.setObjectProperty(args{ii}{pp}, args{ii}{pp+1}, ii);
               end
            end
         end
         
         % Prepare?
         if nargin >= 3 && prepareFlag
            ensemble.callObjectMethod(@prepareToDrawInWindow);
         end
         
         % Call runBriefly to draw it & flip the buffers
         frameInfo = ensemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            
         % Pause while showing?
         if nargin >= 4 && showDuration > 0
         
            % Wait while showing
            pause(showDuration);
            
            % check for hide
            if nargin >= 5 && pauseDuration > 0
               
               % Set visible flags to false
               ensemble.setObjectProperty('isVisible', false);
               
               % Draw again to blank screen
               ensemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               
               % Wait again
               pause(pauseDuration);
            end
         else
            frameInfo = [];
         end
      end
   end
end