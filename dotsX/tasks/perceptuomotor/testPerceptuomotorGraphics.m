% test the graphics for the perceptuomotor task

rInit('local')
rGroup('gXperceptuomotor_Graphics')

rGraphicsShow;
rGraphicsDraw(inf);

% clock the Gabor computation
n = 100;
tims = zeros(1,n);
f = logspace(-1,1,n);
c = linspace(0,.99,n);
for ii = 1:n
    tic;
    rSet('dXtexture', 2, 'textureArgs', f(ii));
    tims(ii) = toc;
    rGraphicsDraw;
end

rGraphicsDraw(inf);

for ii = 1:n
    tic;
    rSet('dXtexture', 1, 'contrast', c(ii));
    tims(ii) = toc;
    rGraphicsDraw;
end

rGraphicsDraw(inf);

rDone