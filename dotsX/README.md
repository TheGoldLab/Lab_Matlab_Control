# dotsX
# (Mostly) obsolete utilities for controlling graphics

How to do basic DotsX stuff
---------------------------

-> RUN A SCRIPT
There are several MATLAB scripts which demonstrate DotsX functionality in

	DotsX/scripts/.

For example, demoAllGraphics.m will demonstrate every type of DotsX graphics.  demoDots.m will show variations of the DotsX moving dot stimulus.

To run a DotsX script on a machine with DotsX installed, open MATLAB and type the sctipt name in the MATLAB command window and press enter.  For example,

	>> demoDots [ENTER]

-> LOCAL OR REMOTE GRAPHICS
You may need to edit a script slightly so that DotsX can display graphics on the correct computer.  To edit the demoDots script type in the MATLAB command window

	>> edit demoDots.m [ENTER]

to bring up the file.  Find the line that reads

rInit('remote');

or

rInit('local');

The word in quotes determines where DotsX will show graphics.  If you want to show graphics on the computer you?re using, make sure the word reads ?local?.  If you have a DotsX remote graphics client attached to your machine, make sure the word reads ?remote?.

-> RUN A PARADIGM
There are several DotsX tasks in 

	DotsX/tasks/.

These tasks define stimuli and user input that may be included in an experiment (also called a paradigm).  taskDots.m define a basic version of the dots task.  taskCalibrateAsl.m can facilitate calibration of the ASL eye tracker.  You can run a paradigm, using the DotsX function,?rRun?.  Type

	>> rRun(?taskDots?) [ENTER]

to start a paradigm which includes the basic dots task.

You can gain fine control over how a paradigm runs and which task or tasks it includes.  In the MATLAB command window, type

	>> help rRun [ENTER]

for more information.

-> START THE GUI AND DO THE SAME THINGS
You can also use DotsX scripts and paradigms with a graphical user interface (a ?gui?), which provides menus and buttons as alternatives to typing in the command window.  Start the DotsX gui by typing

	>> dXgui [ENTER]

Go to File --> Open to choose a script.  When you click (Open) the script will run immediately.

Go to File --> New paradigm to start a new paradigm.  You may see a dialog titled, ?Save existing ROOT_STRUCT??  If you wish to save the state of a previous DotsX session, pick a file name and click (Save).  Otherwise click (Cancel) to proceed.

Two new dialogs will appear which give you control over your new paradigm.  In the dialog titled ?newParadigm? you should click (add task) to add one or more task definitions to you paradigm.  You can select multiple tasks by holding the ?apple? key.

If you select taskDots.m and click (Open) the basic dots task will load.  A row of controls will appear, including a large button named (Dots) which indicates the name of the task you loaded.  These controls and others in the ?newParadigm? dialog give you fine control over how your paradigm will run.

A new window may appear when you add a new task, for example a window for showing eye position data from an attached ASL eyetracker.

You can start your paradigm by clicking (start) in the original ?dXgui?dialog.  You can also (pause) or (stop) your paradigm while it?s running.
