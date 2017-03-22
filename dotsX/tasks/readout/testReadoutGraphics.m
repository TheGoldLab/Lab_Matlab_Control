% test the graphics for the readout task

rInit('local')
rGroup('gXreadout_Graphics')

meanDir = 90;
sdtDir = 40;
dirDomain = meanDir + (-180:180);
dirCDF = normcdf(dirDomain, meanDir, sdtDir);
rSet('dXdots', 1, 'dirDomain', dirDomain, 'dirCDF', dirCDF);

rGraphicsShow('dXdots', 1, 'dXtarget', 1, 'dXimage');
rGraphicsDraw(inf);

rDone