% Implement a symple system of moving particles drawn as OpenGL points.
% @details
% demoParticleSystem() implements a simple system of particles.  Each
% particle has an initial position and velocity and experiences constant
% acceleration.  The system is updated on a frame-by-frame basis and
% animated with each particle as an OpenGL point.
% @details
% demoParticleSystem actually implements the same system twice: once
% relying mainly on the CPU, and once relying mainly on the GPU.
% @details
% The CPU implementation uses m-code to update the particle system model.
% On each frame, m-code executed on the CPU computes a new position and
% velocity for each particle and transmits the position of each particle to
% OpenGL to be rendered as a point.
% @details
% The GPU immplementation uses fancy OpenGL features: buffer objects, a
% vetex shader, and transform feedback.  OpenGL buffer objects hold the
% particle system data in graphics memory.  A GLSL shader program executes
% on the GPU to update particle positions and velocities, based on a "delta
% t" for each frame.  This "delta t" is the only parameter transmitted to
% OpenGL on each frame.  The updated particle positions continue along the
% OpenGL pipeline to be rendered as points.  In addition, transform
% feedback allows the updated  positions and velocities are stored in
% buffer objects, which are then updated and rendered on the next frame.
% @details
% The two implementations should have the same behavior--they should look
% the same.  They're meant to represent a tradeoff between code simplicity
% and performance.
% @details
% The CPU implementation is easier to code and read, but may suffer from
% performance problems: passing lots of position data from m-code to
% OpenGL on every frame is likely to be a performance bottleneck.  Also,
% the GPU should be better optimized than the CPU for executing repetitive
% instructions for many particles, in parallel.
% @details
% The GPU implementation avoids the data bottleneck by passing only a
% single parameter on each frame.  It exploits the implicit parallelism
% of the GPU, and also allows particle system computations to occurr in
% parallel with the CPU.  But the GPU implementation is more complicated
% and more difficult to set up.  It involves m-code, c-code, and GLSL code!
% @details
% demoParticleSystem() attempts to show the performance benefit of the GPU
% implementation by measuring how long it takes each implementation to
% update the particle system and render the next frame of animation.  The
% performance benefit probably depends on the number of particles in the
% system.
% @details
% demoParticleSystem() uses OpenGL "transform feedback" functionality,
% which is discussed in this good tutorial:
% http://ogldev.atspace.co.uk/www/tutorial28/tutorial28.html
%
% @ingroup dotsDemos
function data = demoParticleSystem(nParticles, nFrames, openArg)

%% Check Arguemnts

% choose demo parameters
if nargin < 1
    nParticles = 50000;
end

if nargin < 2
    nFrames = 1000;
end

if nargin < 3
    openArg = -1;
end

%% Common Initialization

% choose initial position as interleaved xy pairs in [-10 10]
initialPosition = 10*(rand(2, nParticles)-0.5);

% choose initial velocity as interleaved xy pairs in [-2 2]
initialVelocity = 2*(rand(2, nParticles)-0.5);

% choose center of attraction
attractorPosition = initialPosition(:,1);
attractorRadius = 1;
attractorG = 25;

% choose a list of time increments for CPU and GPU to use each frame
%   this separates implementation performance time from model behavior
%   since model time is arbitrary, deltaT need not match the frame rate
deltaTList = normrnd((1/60), (1/60^2), 1, nFrames);

% allocate struct for return data
data.nParticles = nParticles;
data.nFrames = nFrames;
data.initialPosition = initialPosition;
data.initialVelocity = initialVelocity;

data.attractorPosition = attractorPosition;
data.attractorRadius = attractorRadius;
data.attractorG = attractorG;

data.updateTimeCPU = zeros(1, nFrames);
data.updateTimeGPU = zeros(1, nFrames);
data.drawTimeCPU = zeros(1, nFrames);
data.drawTimeGPU = zeros(1, nFrames);
data.renderTimeCPU = zeros(1, nFrames);
data.renderTimeGPU = zeros(1, nFrames);

%% Run the CPU implementation
mglOpen(openArg);
mglDisplayCursor(0);
mglVisualAngleCoordinates(57,[16 12]);
position = initialPosition;
velocity = initialVelocity;
mglClearScreen();
mglFlush();
mglFlush();
for ii = 1:nFrames
    % update the model and animation since the last frame
    startTime = mglGetSecs();
    deltaT = deltaTList(ii);
    
    % is there a clever 'vectorized' way to do this?
    for jj = 1:nParticles
        deltaX = attractorPosition(1) - position(1,jj);
        deltaY = attractorPosition(2) - position(2,jj);
        rSquared = deltaX*deltaX + deltaY*deltaY;
        
        if (attractorRadius*attractorRadius) < rSquared
            theta = atan2(deltaY, deltaX);
            acceleration = [cos(theta); sin(theta)]*attractorG/rSquared;
            position(:,jj) = position(:,jj) ...
                + deltaT.*velocity(:,jj) + ...
                0.5*deltaT*deltaT*acceleration;
            velocity(:,jj) = velocity(:,jj) + deltaT.*acceleration;
        end
    end
    
    % how long did the update take?
    data.updateTimeCPU(ii) = mglGetSecs() - startTime;
    
    % how long did drawing take?
    mglPoints2(position(1,:), position(2,:), 1);
    data.drawTimeCPU(ii) = mglGetSecs() - startTime;
    
    % how long did the rendering take?
    dotsMglFinish();
    data.renderTimeCPU(ii) = mglGetSecs() - startTime;
    
    mglFlush();
    mglClearScreen();
    dotsMglFinish();
end
mglDisplayCursor(1);
mglClose();

%% Run the GPU implementation
mglOpen(openArg);
mglDisplayCursor(0);
mglVisualAngleCoordinates(57,[16 12]);

% create a shader program which implements constant acceleration
fid = fopen('particleSystem.vert');
vertexSource = fread(fid, '*char');
fclose(fid);
programInfo = dotsMglCreateShaderProgram(vertexSource, []);
status = dotsMglUseShaderProgram(programInfo);
assert(status > 0 , 'could not create GPU shader program');

% create two pairs of vertex buffer objects (VBOs)
%   On each frame, a VBO from each pair passes data to the shader program.
%   The program passes its results to the other VBO from each pair.
%   On the next frame, the VBOs swap roles.
%   Shader programs use single-precision floats natively
bufferTarget = 0;
usageHint = 2;
elementsPerVertex = 2;
for ii = 1:2
    positionVBO(ii) = dotsMglCreateVertexBufferObject( ...
        single(initialPosition), ...
        bufferTarget, usageHint, elementsPerVertex);
    velocityVBO(ii) = dotsMglCreateVertexBufferObject( ...
        single(initialVelocity), ...
        bufferTarget, usageHint, elementsPerVertex);
end

% choose program inputs: variable names and initial data sources
dotsMglSelectVertexAttributes(programInfo, ...
    [positionVBO(1), velocityVBO(1)], ...
    {'positionIn', 'velocityIn'});

% choose program outputs: variable names and initial data locations
dotsMglSelectTransformFeedback(programInfo, ...
    [positionVBO(2), velocityVBO(2)], ...
    {'positionOut', 'velocityOut'});

% choose vertices using a buffer of indices
%   this gives OpenGL a chance (at best) to optimize by caching
if nParticles < 2^16
    elements = zeros(1, nParticles, 'uint16');
else
    elements = zeros(1, nParticles, 'uint32');
end
elements(1:end) = 0:(nParticles-1);
bufferTarget = 1;
usageHint = 3;
elementsPerVertex = 1;
elementVBO = dotsMglCreateVertexBufferObject( ...
    elements, bufferTarget, usageHint, elementsPerVertex);

% set constant system parameters
positionVariable = dotsMglLocateProgramVariable( ...
    programInfo, 'attractorPosition');
dotsMglSetProgramVariable(positionVariable, attractorPosition');

radiusVariable = dotsMglLocateProgramVariable( ...
    programInfo, 'attractorRadius');
dotsMglSetProgramVariable(radiusVariable, attractorRadius);

gravityVariable = dotsMglLocateProgramVariable( ...
    programInfo, 'attractorG');
dotsMglSetProgramVariable(gravityVariable, attractorG);

% step through the model
deltaTVariable = dotsMglLocateProgramVariable( ...
    programInfo, 'deltaT');
drawPoints = 0;
mglClearScreen();
mglFlush();
mglFlush();
for ii = 1:nFrames
    % account for frame time
    startTime = mglGetSecs();
    dotsMglSetProgramVariable(deltaTVariable, deltaTList(ii));
    
    % how long did the update take?
    data.updateTimeGPU(ii) = mglGetSecs() - startTime;
    
    % swap the input and ouput data buffers
    %   no need to specify variable names again
    inIndex = 1 + mod(ii, 2);
    outIndex = 1 + mod(ii+1, 2);
    dotsMglSelectVertexAttributes(programInfo, ...
        [positionVBO(inIndex), velocityVBO(inIndex)]);
    dotsMglSelectTransformFeedback(programInfo, ...
        [positionVBO(outIndex), velocityVBO(outIndex)]);
    
    % update the model and capture the results with feedback
    dotsMglBeginTransformFeedback(drawPoints, 0);
    dotsMglDrawVertices(drawPoints, nParticles, [], [], elementVBO);
    dotsMglEndTransformFeedback();
    
    % how long did drawing take?
    data.drawTimeGPU(ii) = mglGetSecs() - startTime;
    
    % how long did the rendering take?
    dotsMglFinish();
    data.renderTimeGPU(ii) = mglGetSecs() - startTime;
    
    % show the frame and clear the screen
    %   use glFinish() to isolate clear timing from the model update
    mglFlush();
    mglClearScreen();
    dotsMglFinish();
end

% clean up this mess
dotsMglUseShaderProgram();
dotsMglSelectVertexAttributes();
dotsMglDeleteVertexBufferObject(positionVBO(1));
dotsMglDeleteVertexBufferObject(positionVBO(2));
dotsMglDeleteVertexBufferObject(velocityVBO(1));
dotsMglDeleteVertexBufferObject(velocityVBO(2));
dotsMglDeleteVertexBufferObject(elementVBO);
dotsMglDeleteShaderProgram(programInfo);

mglDisplayCursor(1);
mglClose();
