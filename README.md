# Lab-Matlab-Control
Custom utilities for experimental control for the Gold Lab, including snow-dots (custom utilities written in an object-oriented framework for controlling the components of a psychophyiscs experiment, such as graphics, sounds, etc.), tower-of-psych (custom utilities written in an object-oriented framework to organize and control the flow of a psychophyiscs experiment), and modular tasks (tasks written as subclasses of the [topsTreeNodeTask](https://github.com/TheGoldLab/Lab_Matlab_Control/blob/master/tower-of-psych/foundation/runnable/topsTreeNodeTask.m) class)


## What you need:
- The files contained within both the [Lab-Matlab-Control](https://github.com/TheGoldLab/Lab_Matlab_Control) and [Lab-Matlab-Utilities](https://github.com/TheGoldLab/Lab_Matlab_Utilities) repos
- MGL, a "a suite of mex/m files for displaying visual psychophysics stimuli and writing experimental programs in Matlab" that can be downloaded [here](http://gru.stanford.edu/doku.php/mgl/overview)
- At your own risk: a test version of [snow-dots](https://github.com/TheGoldLab/Lab_Matlab_Control/tree/PTB) that depends on [PsychToolbox](http://psychtoolbox.org)

- The lastest version of Matlab that Snow-Dots will work 100% properly on is 2013a. With the exception of dotsDrawableExplosions, Matlab 2016a will run everything as well. Currently Matlab 2017a and beyond is not compatabile with Snow Dots. If you must install the 2013a version of Matlab and are running on Apples latest OS, you will likely encouter an error when trying to run it. Please go to this link https://www.mathworks.com/support/bugreports/1098655 and complete the appropriate steps to patch up your 2013a version of Matlab.

Be sure to check out our [documentation](https://thegoldlab.github.io/SnowDotsDocumentation/index.html) and [tutorials](https://github.com/TheGoldLab/Lab_Tutorials) if you are just getting started!
