classdef dotsDrawableExplosion < dotsDrawableVertices
    % @class dotsDrawableExplosion
    % Animate an explosion of many particles.
    % @details
    % dotsDrawableExplosion simulates a fireworks-style explosion.  It
    % animates multiple particles with constant-acceleration projectile
    % motion.  The animation has a few distinct phases:
    %   - Explosion.  Animates many particles until they hit the ground.
    %   The particles start with random velocities, which are be chosen so
    %   that the eventual resting positions will obey a given distribution.
    %   Each particle is drawn as a point.
    %   - Bounces.  Animates the particles as they bounce off the ground.
    %   The bounce trajectories follow from the explosion trajectories,
    %   with damping at each contact with the ground.  There are 4 bounces.
    %   - Rest.  After all the bounces are complete, each particle settles
    %   in place at ground level.
    %   .
    % The explosion and bounce trajectory parameters for each particle are
    % solved during prepareToDrawInWindow().  Frame-by-frame positions are
    % computed for each particle during draw(), based on the current time.
    % An OpenGL vertex shader (explosion.vert by default) implements the
    % projectile calculations.
    % @details
    % The algebra used to solve trajectory parameters is on the Snow Dots
    % wiki: http://code.google.com/p/snow-dots/wiki/ExplosionAlgebra
    properties
        % file name with projectile motion vertex shader source
        vertexShader = 'explosion.vert';
        
        % x-position where each particle should come to rest
        xRest = 1;
        
        % y-position where each particle should bounce, then rest
        yRest = 1;
        
        % how long it should take each particle to come to rest
        tRest = 1;
        
        % constant vertical acceleration for all particles
        gravity = -1;
        
        % multiplier for particle x and y velocity at each bounce [bX bY]
        bounceDamping = [0.5 -0.5];
        
        % how to choose roots from quadratic solutions
        % @details
        % Solving for velocities yields two solutions.  The first tends to
        % slam paricles against the ground and makes them bounce high.  The
        % second tends to toss particles gently in the air.  Either way,
        % particles end up in the same place.
        whichRoot = 2;
        
        % function that returns the current time as a number
        clockFunction;
        
        % time of the most recent draw()
        currentTime;
        
        % whether to update currentTime with clockFunction during draw()
        isInternalTime = true;
    end
    
    
    properties (SetAccess = protected)
        % zero-time for the beginning of each animation sequence
        startTime;
        
        % identifier and other info for OpenGL shader program
        programInfo;
        
        % identifier and other info about the shader time variable
        timeVar;
        
        % number of bounces supported by shader program
        nBounces = 4;
        
        % attribute names for the OpenGL shader program
        attribNames = {'restTime', ...
            'time1', 'time2', 'time3', 'time4', ...
            'position1', 'position2', 'position3', 'position4', ...
            'velocity1', 'velocity2', 'velocity3', 'velocity4'};
        
        % attribute data calculated in solveParticleSystem()
        attribData;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsDrawableExplosion
            self = self@dotsDrawableVertices;
            
            % data and OpenGL buffers to be organized by names
            empties = cell(size(self.attribNames));
            self.attribData = cell2struct(empties, self.attribNames, 2);
            self.attribBufferInfo = ...
                cell2struct(empties, self.attribNames, 2);
        end
        
        % Release OpenGL resources.
        function delete(self)
            self.delete@dotsDrawableVertices();
            
            if ~isempty(self.programInfo)
                dotsMglDeleteShaderProgram(self.programInfo);
            end
            self.programInfo = [];
        end
        
        % Keep track of required buffer updates.
        function set.xRest(self, xRest)
            if ~isequal(self.xRest, xRest);
                % nVertices changed
                self.flagAllBuffersAsStale();
            end
            self.xRest = xRest;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.yRest(self, yRest)
            if ~isequal(self.yRest, yRest);
                % nVertices changed
                self.flagAllBuffersAsStale();
            end
            self.yRest = yRest;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.tRest(self, tRest)
            if ~isequal(self.tRest, tRest);
                % nVertices changed
                self.flagAllBuffersAsStale();
            end
            self.tRest = tRest;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.bounceDamping(self, bounceDamping)
            self.bounceDamping = bounceDamping;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.gravity(self, gravity)
            self.gravity = gravity;
            self.isAttribBufferStale = true;
        end
        
        % Keep track of required buffer updates.
        function set.whichRoot(self, whichRoot)
            self.whichRoot = whichRoot;
            self.isAttribBufferStale = true;
        end
        
        % Determine minimum resting times, based on system properties.
        % @details
        % Several parameters affect how long each particle requires to fall
        % to the ground and bounce.  Together they impose a minimum
        % duration for particle bouncing.  Smaller times for tRest would be
        % impossible to achieve.
        % @details
        % Intuituvely, a particle starting with zero y-velocity should
        % require the least time--adding upward or downward velocity would
        % add energy to the system and causes larger bounces.
        % calculateMinimumRestTimes() assumes zero starting velocity and
        % calculates the corresponding time to complete all bounces.
        function tRestMins = calculateMinimumRestTimes(self)
            tRestMins = zeros(1, self.getNVertices());
            aY = self.gravity;
            heights = self.y - self.yRest;
            bounceNumbers = (1:(self.nBounces-1));
            yDampSequence = abs(self.bounceDamping(2)) .^ bounceNumbers;
            yDampSum = sum(yDampSequence);
            tMin0 = sqrt(-2*heights/aY);
            vYMin0 = -aY*tMin0;
            tMin1N = (-2/aY)*vYMin0*yDampSum;
            tRestMins(:) = tMin0 + tMin1N;
        end
        
        % Compute motion parameters for each particle and each bounce.
        function solveParticleSystem(self)
            nParticles = self.getNVertices();
            
            % clip resting times to minimum possible
            durations = zeros(1, self.getNVertices());
            durations(:) = self.tRest;
            tRestMins = self.calculateMinimumRestTimes();
            durations = max([durations;tRestMins], [], 1);
            
            % Contrive velocities for each particle which will fulfill the
            %   chosen durations and resting x-positions.
            
            % Imagine each particle started at yRest, as opposed to an
            % arbitrary y.  This leads to a "root" parabola which began
            % some time in the past.
            aY = self.gravity;
            bounceNumbers = (0:(self.nBounces-1));
            yDampSequence = abs(self.bounceDamping(2)) .^ bounceNumbers;
            yDampSum = sum(yDampSequence);
            heights = self.y - self.yRest;
            aCoef = 4*(yDampSum*yDampSum - yDampSum);
            bCoef = 2*aY*durations*((2*yDampSum) - 1);
            cCoef = (durations.^2) .* (aY^2) - (2*aY*heights);
            vYRoots = dotsDrawableExplosion.solveQuadratic( ...
                aCoef, bCoef, cCoef);
            
            % choose one of the solutions arbitrarily
            vYRoot = vYRoots{self.whichRoot};
            
            % root y-velocity leads to:
            %   sequence of y-velocity (including root parabola)
            %   sequence of bounce durations (including root parabola)
            vYSequence = vYRoot'*yDampSequence;
            durationSequence = (-2/aY) .* vYSequence;
            
            % solve the "root" time corresponding to the "root" velocity
            %   this is the pre-explosion time within the "root" parabola
            aCoef = aY/2;
            bCoef = vYRoot;
            cCoef = -heights;
            tRoots = dotsDrawableExplosion.solveQuadratic( ...
                aCoef, bCoef, cCoef);
            tRoot = tRoots{3-self.whichRoot};
            
            % adjust y-velocity and bounce durations forward in time
            %   from the "root" time to the actual explosion time
            vYSequence(:,1) = vYRoot + aY*tRoot;
            durationSequence(:,1) = durationSequence(:,1) - tRoot';
            
            % adjusted sequence of bounce durations leads to:
            %   x-velocity at explosion time
            %   sequence of x-velocity
            %   sequence of x-displacements
            %   sequence of x-positions
            xDampSequence = abs(self.bounceDamping(1)) .^ bounceNumbers;
            xDampMat = repmat(xDampSequence, nParticles, 1);
            widths = self.xRest - self.x;
            vXExplosion = widths ./ sum(durationSequence .* xDampMat, 2)';
            vXSequence = vXExplosion'*xDampSequence;
            displacementSequence = vXSequence .* durationSequence;
            xExplosion = repmat(self.x, nParticles, 1);
            xSequence = cumsum( ...
                [xExplosion, displacementSequence(:,1:end-1)], 2);
            
            % The system is solved!
            % Pack results into single-precision matrices and organize by
            % shader variable names (contrived to match attribNames).
            
            % let the first bounce start at t=0
            timeData = zeros(1, nParticles, self.nBounces, 'single');
            timeData(1,:,2:end) = cumsum(durationSequence(:,1:end-1), 2);
            self.attribData.time1 = timeData(:,:,1);
            self.attribData.time2 = timeData(:,:,2);
            self.attribData.time3 = timeData(:,:,3);
            self.attribData.time4 = timeData(:,:,4);
            self.attribData.restTime = single(durations);
            
            % let the first bounce start at self.x
            % let the first bounce start at self.y
            % let subsequent bounces start at self.yRest
            positionData = zeros(3, nParticles, self.nBounces, 'single');
            positionData(1,:,:) = xSequence;
            positionData(2,:,1) = self.y;
            positionData(2,:,2) = self.yRest;
            positionData(2,:,3) = self.yRest;
            positionData(2,:,4) = self.yRest;
            positionData(3,:,:) = self.z;
            self.attribData.position1 = positionData(:,:,1);
            self.attribData.position2 = positionData(:,:,2);
            self.attribData.position3 = positionData(:,:,3);
            self.attribData.position4 = positionData(:,:,4);
            
            % let each velocity be unique, as solved
            velocityData = zeros(3, nParticles, self.nBounces, 'single');
            velocityData(1,:,:) = vXSequence;
            velocityData(2,:,:) = vYSequence;
            self.attribData.velocity1 = velocityData(:,:,1);
            self.attribData.velocity2 = velocityData(:,:,2);
            self.attribData.velocity3 = velocityData(:,:,3);
            self.attribData.velocity4 = velocityData(:,:,4);
        end
        
        % Solve particle trajectores into buffers and load shader program.
        function prepareToDrawInWindow(self)
            % create buffers and the shader program as needed.
            self.updateBuffers();
            self.loadShaderProgram();
            
            % define "zero" time for draw()
            self.startTime = feval(self.clockFunction);
        end
        
        % Draw particles, based on the current time.
        function draw(self)
            % activate the explosion shader program
            dotsMglUseShaderProgram(self.programInfo);
            
            % update the shader program time
            if self.isInternalTime
                self.currentTime = ...
                    feval(self.clockFunction) - self.startTime;
            end
            dotsMglSetProgramVariable(self.timeVar, self.currentTime);
            
            % draw vertices like DrawableVertices
            self.draw@dotsDrawableVertices();
            
            % deactivate the explosion shader program
            dotsMglUseShaderProgram();
        end
        
        % Calculate number of vertices based on several properties;
        function nVertices = getNVertices(self)
            nVertices = max([ ...
                numel(self.x), ...
                numel(self.y), ...
                numel(self.z), ...
                numel(self.xRest), ...
                numel(self.yRest), ...
                numel(self.tRest)]);
        end
    end
    
    methods (Access = protected)
        
        % Release OpenGL vertex buffer for each attribNames.
        function deleteAttribBuffer(self)
            for ii = 1:numel(self.attribNames)
                name = self.attribNames{ii};
                buffer = self.attribBufferInfo.(name);
                if ~isempty(buffer)
                    dotsMglDeleteVertexBufferObject(buffer);
                end
                self.attribBufferInfo.(name) = [];
            end
            self.isAttribBufferStale = true;
        end
        
        % Write OpenGL vertex buffer data for each attribNames.
        function updateAttribBuffer(self)
            % Calculate parameters for each particle and each bounce
            %   this fills attribData
            self.solveParticleSystem();
            
            % get an OpenGL buffer for each field of attribData
            %   attribData and attribBufferInfo both organized by
            %   attribNames
            bufferTarget = 0;
            for ii = 1:numel(self.attribNames)
                % get the new data and the old buffer by attribute name
                %   the buffer may be empty
                name = self.attribNames{ii};
                buffer = self.attribBufferInfo.(name);
                data = self.attribData.(name);
                
                % create, replace, or re-write the buffer as needed
                elementsPerVertex = size(data, 1);
                buffer = self.overwriteOrReplaceBuffer( ...
                    buffer, data, bufferTarget, elementsPerVertex);
                
                % assign the updated buffer by attribute name
                self.attribBufferInfo.(name) = buffer;
            end
            self.isAttribBufferStale = false;
        end
        
        % Load the shader program which makes particles explode.
        function loadShaderProgram(self)
            % re-load the shader program from scratch
            if ~isempty(self.programInfo)
                dotsMglDeleteShaderProgram(self.programInfo);
            end
            fid = fopen(self.vertexShader);
            vertexSource = fread(fid, '*char');
            fclose(fid);
            self.programInfo = dotsMglCreateShaderProgram( ...
                vertexSource, []);
            
            % activate the shader program to bind variables
            dotsMglUseShaderProgram(self.programInfo);
            
            % link attribute data to shader variable names
            buffers = struct2cell(self.attribBufferInfo);
            dotsMglSelectVertexAttributes(self.programInfo, ...
                [buffers{:}], self.attribNames);
            
            % set the gravity constant variable, just once
            accelVar = dotsMglLocateProgramVariable( ...
                self.programInfo, 'acceleration');
            dotsMglSetProgramVariable(accelVar, [0 self.gravity 0]);
            
            % save the location of the currentTime variable
            %   let draw() update its value
            self.timeVar = dotsMglLocateProgramVariable( ...
                self.programInfo, 'currentTime');
            
            % done with OpenGL program and attribute buffers for now
            dotsMglSelectVertexAttributes();
            dotsMglUseShaderProgram();
        end
        
        % Bind buffers for drawing.
        function selectBuffers(self)
            % select particle colors and re-bind attribute buffers
            dotsMglSelectVertexData(self.colorBufferInfo, {'color'});
            buffers = struct2cell(self.attribBufferInfo);
            dotsMglSelectVertexAttributes(self.programInfo, [buffers{:}]);
        end
        
        % Unbind buffers for drawing.
        function deselectBuffers(self)
            dotsMglSelectVertexData();
            dotsMglSelectVertexAttributes();
        end
    end
    
    methods (Static)
        % Solve roots of a quadratic, given coefficients.
        function roots = solveQuadratic(aCoef, bCoef, cCoef)
            discriminant = sqrt(bCoef.*bCoef - (4*aCoef.*cCoef));
            roots{1} = (-bCoef + discriminant) ./ (2*aCoef);
            roots{2} = (-bCoef - discriminant) ./ (2*aCoef);
        end
    end
end