# RTDots task
Response-time “random dots” direction discrimination task

NOTES:
1. To get code updates, open Terminal and type:
	-> cd /Users/Lab/ActiveFiles/Matlab/Lab-Matlab-Control
	-> git pull origin eyeDev
2. On our setup, the laptop is the “client” and the mac mini is the “server”

ON THE MINI (SERVER)
————————————————————

1. Start Matlab server

	a. type: 
		-> RTDserver

	b. To force quit when the screen is blank (will have to re-start Matlab):
		<Command>-<Option>-<Esc>

	c. To force quit script when the command window is available:
		<Ctrl>-c

ON THE LAPTOP (CLIENT)
——————————————————————

1. Start Pupil labs. 

	a. Make sure the glasses are plugged into the USB port	
	b. Open terminal app and at the prompt type (hitting <return> after each line):		-> cd /Users/Lab/ActiveFiles/PupilLabs/pupil/pupil_src		-> python3 main.py	
	c. Three windows should open up, labeled:		Pupil Capture – World		Pupil Capture – Eye 0		Pupil Capture – Eye 1	
If the “World” window does not open, try quitting terminal then trying again. If one or both of the Eye windows does not open, go to the World window, click on the “General Settings” button on the upper-right corner, and make sure “Direct eye 0” and “Direct eye 1” both have greenish buttons next to them (if not, click on the button).d. Make sure calibration (the “bullseye” icon to the right) is set to Manual Marker Calibration.2. Start Matlab client	a. type: 
		-> RTDrun

	b. To force quit when the screen is blank (will have to re-start Matlab):
		<Command>-<Option>-<Esc>

	c. To force quit script when the command window is available:
		<Ctrl>-c
