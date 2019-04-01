# Dream Oddball Task

**Overview:** A certain sound frequency will be played commonly. A second, ‘oddball’ frequency will be played rarely. The participant is required to press a button or pattern of buttons to respond to oddball frequencies when they play.

There are additional modes that can be run as well:

**Distractor Mode:** This turns on a distractor sound that will intermittently play and make the task a little more difficult.

**Adaptive Mode:** This will tune the difference between the oddball frequency and commonly-played frequency to adapt the difficulty of the task to the participant’s ability.

**Opposite Input Mode:** During the standard version of the task, the participant must respond to oddball frequencies being played. With Opposite Input Mode turned on, they must respond to standard frequencies, and IGNORE oddball frequencies.

***
# Dependencies

The **FoundationCode** folder includes Snowdots by Ben Heasley, Psychtoolbox, Stanford's MGL Library, the Tobii SDK, and other assorted Matlab toolboxes. The Custom folder features code that was written by me or by colleagues at the GoldLab. These are all **REQUIRED** to be in the Matlab path for the task code to work!

Before running this task, TobiiCalibration must have been run on a subject to calibrate the Tobii Eyetracker! The calibration file can be found in the greater GoldLabPsychophysics repository: *Foundation/Custom/KabirTobiiCalibration.m*

***
# The Task Constructor

To create the runnable task object, run:

	>[task, list] = dreamOddballConfig(distractor_on, adaptive_on, opposite_on)

The arguments inside the dreamOddballConfig function are 0s or 1s.

distractor_on == 1 means that the task is in Distractor Mode. 

adaptive_on ==1 means the task in in Adaptive Mode.

opposite_on ==1 means the task is in Opposite Input Mode.

All three modes can be active at once.

To actually run the task:

	>[task,list] = dreamOddballConfig(0,0,0)
	>dotsTheScreen.openWindow() %Opens window
	>task.run  %Runs task
	>dotsTheScreen.closeWindow()  %Closes window 

***

# Data storage

Everything is stored in the ‘list’ object that will appear after the task is constructed. 

The list can be accessed by indexing using string ‘mnemonics’.

For example, to access Eyetracker data for the left eye, I can:

	>list{’Eye’}{‘Left’}

Some important data stores:

	list{‘Stimulus’}{‘Playtimes’} = Timestamps for every sound played

	list{‘Stimulus’}{‘Playfreqs’} = Frequencies played for each trial

	list{‘Input’}{‘Choices’} = Participant inputs for a trial

	list{‘Input’}{‘Corrects’} = Whether or not answers were correct for each trial

	list{‘Eye’}{‘Left’} = All eye tracking data (X-coordinate, Y-coordinate, Eye Diameter, Validity Code) for the left eye

	list{‘Eye’}{‘Right’} = All eye tracking data (X-coordinate, Y-coordinate, Eye Diameter, Validity Code) for the right eye



	


