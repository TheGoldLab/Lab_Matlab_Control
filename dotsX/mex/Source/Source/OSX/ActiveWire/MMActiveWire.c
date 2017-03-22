/* 
*	MMActiveWire.c
 *	Matlab Mex file
 *
 * Makes a MATLAB mex file for querying the ActiveWire USB device,
 *	via Dave Keck's WONDERFUL driver
 * 
 *
 *  Created by jigold on Fri Jan 14 2005.
 *  Copyright (c) 2005 University of Pennsylvania. All rights reserved.
 *
 */

#include "ActiveWireLib.h"

#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdbool.h>
#include <string.h>
#include <sys/time.h>

#include "mex.h"

static int gl_opened = 0;
void signalHandler();

/* 
* Usage:
 *		aw('init')
 *		[times pins] = aw('check')
 *		aw('write')
 *		aw('reset')
 *		aw('close')
 *		
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *command=NULL;
	int buflen;
	static struct timeval reset_time;
	static unsigned char reset_buf[2];
	
	/* First argument is (string) command */
	if(nrhs < 1) {
		mexPrintf("aw Usage:\n\taw('init', <history_length>),\n\t<changes>=aw('read')\n\taw('write',<data>)\
\n\taw('reset')\n\taw('close')\n");
		return;
	}
	
	if(mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1 && mxIsChar(prhs[0])) {
		buflen  =  mxGetN(prhs[0]) + 1;
		command = mxCalloc(buflen, sizeof(char));
		if(mxGetString(prhs[0], command, buflen))
			mexWarnMsgTxt("aw: Not enough space. String is truncated.");
	} else {
		mexErrMsgTxt("aw: First argument should be a string (command)");
	}
	
	if(!strncmp(command, "init", 3)) {
	
		if(!gl_opened) {
			unsigned char numberOfBoards = 0;
			int len = 24; // default size of save buffer
			
			// lock file in memory (can't clear)
			mexLock();
			
			// register signal handler
			signal(SIGINT, signalHandler);
			
			/* initialize driver */
			if(aw_init())
				mexErrMsgTxt("aw: Unable to initialize driver");
			
			/* get number of connected boards */
			if(aw_numberOfConnectedBoards(&numberOfBoards))
				mexErrMsgTxt("aw: Unable to retrieve number of boards connected.");
			if(!numberOfBoards)
				mexErrMsgTxt("aw: No ActiveWire boards connected.");
			
			/* set input/output */
			if(aw_setDirectionsOfPinSets(0, 0xff, 0xff))
				mexErrMsgTxt("aw: Unable to set the IO pins' directions.");
			
			/* setup callbacks/"delivery method"
				** we're using a buffer, the last argument sets the max size of the buffer
				**	(i.e., the max number of events it will store before needing a 'reset')
				** Get this as an optional argument to the mex function, after keyword 'init'
				*/
			if(nrhs == 2 && mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 1 && mxIsNumeric(prhs[1]))
				len = mxGetScalar(prhs[1]);
			
			if(aw_setCallbacksAndDeliveryMethod(NULL, NULL, NULL, AW_DELIV_BUFFER, len))
				mexErrMsgTxt("aw: Unable to set callbacks.");
			
			/* use gettimeofday to initialize static variables that keep track of time */
			gettimeofday(&reset_time, NULL);
			
			/* reset the channel buffer to the current state */
			if(aw_readData(0, reset_buf, 2))
				mexErrMsgTxt("aw: Unable to read buffer\n");
				
			// set flag
			gl_opened = 1;
		}
		
	} else if(!strncmp(command, "read", 3)) {
		double *data;
		long elapsed_time;
		register int i, j;
		int total=0, count=0, bits[] = {8,9,10,11,12,13,14,15,0,1,2,3,4,5,6,7};
		unsigned short changed, *this_buf, *last_buf;
		AW_EVENT_LIST eventList;
		
		if(!gl_opened) {
			plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
			mxFree(command);
			return;
		}
		
		/* return a matrix of <channel> <value> <time> for each changed input */
		// if(nlhs != 1)
		//	mexErrMsgTxt("aw: Read requires one output argument");
		
		// get the events
		eventList = aw_getEvents();

		if(!(eventList->numberOfEvents)) {
			plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
			mxFree(command);
			return;
		}
		
		//mexPrintf("number of events = %d\n", eventList->numberOfEvents);
		
		/* count the events */
		last_buf = (unsigned short *) (&(reset_buf[0]));
		for(i=0;i<eventList->numberOfEvents;i++) {
			this_buf = (unsigned short *) (&(eventList->events[i]->boardData[0]));
			changed  = ((*this_buf) ^ (*last_buf));
			for(j=0;j<16;j++)
				total += (changed >> j) & 0x0001;
			last_buf = this_buf;
		}

		//if(eventList->numberOfEvents != total) {
		//	printf("%d events, %d changes\n", eventList->numberOfEvents, total);
		//	printf("reset buf is %d.%d\n", (int) (reset_buf[0]), (int) (reset_buf[1]));
		//}
		
		if(!total) {
		mexPrintf("NO CHANGE (%d events)\n", eventList->numberOfEvents);
			plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
			mxFree(command);
			return;
		}
					
		/* set up the output matrix */
		plhs[0] = mxCreateDoubleMatrix(total, 3, mxREAL);
		
		/* loop through the events */
		data     = mxGetPr(plhs[0]);
		last_buf = (unsigned short *) (&(reset_buf[0]));
		for(i=0;i<eventList->numberOfEvents;i++) {
			
			/* elapsed time is in ms */
			elapsed_time = (double) 
			((eventList->events[i]->timestamp.tv_sec - reset_time.tv_sec )  * 1000L + 
			 (eventList->events[i]->timestamp.tv_nsec/1000L - reset_time.tv_usec) / 1000L);
			
			this_buf = (unsigned short *) (&(eventList->events[i]->boardData[0]));
			changed  = ((*this_buf) ^ (*last_buf));
			for(j=0;j<16;j++) {
				if((changed >> bits[j]) & 0x0001) {
					*(data+count)			= (double) j;
					*(data+count+total)		= (double) (((*this_buf) >> bits[j]) & 0x0001);
					*(data+count+2*total)	= elapsed_time;
					count++;
				}
			}
			last_buf = this_buf;
		}
		
	} else if(!strncmp(command, "write", 3)) {
		mexPrintf("aw: Command is write\n");
		
	} else if(!strncmp(command, "reset", 3)) {
		
		if(gl_opened) {

			// clear events
			aw_clearEvents();
		
			// reset time base
			gettimeofday(&reset_time, NULL);
		
			// reset the channel buffer to the current state
			if(aw_readData(0, reset_buf, 2))
				mexErrMsgTxt("aw: Unable to read buffer\n");
		}
		
	} else if(!strncmp(command, "close", 3)) {
		
		if(gl_opened) {
			aw_close();
			gl_opened = 0;
			mexUnlock();			
		}
		
	} else if(!strncmp(command, "fclose", 3)) {
		aw_close();

	} else {
		mexErrMsgTxt("aw: Unknown command");
	}

	// free memory for command name
	mxFree(command);
}

void signalHandler() {
	printf("signal handler\n");
	aw_close();
	gl_opened = 0;
}