/* 
*	lpHID.c
 *	Matlab Mex file
 *
 * lpHID = lever-pull Human Interface Device
 *
 * Makes a MATLAB mex file for reading data from the forced-choice two-lever pull thing, which uses
 * the PMD1208-FS digital-analog converter, which is a HID-compliant USB device
 * 
 *  Created by BSH on 28 Nov 2005-1 Dec 2005 using jigold's as.c as template and
 *  dennis pelli's PsychHIDReceiveReports.c for HID implementation and hints
 *
 *	Modified by BSH on 25 Jan 2006 to do do a little error checking, especially for redundant and 
 *	out-of-order calls.  There have been some crashes during testing in MATLAB.  I hope these changes address them.
 * 
 *                                             ***************************
 *												     *NOTE TO SELF:*
  *******************************************************************************************************************
  ** THIS IS IMPORTANT!!  COMPILE WITH gcc 3.3 OR SUFFER THE FATE OF BANGING YOUR HEAD AGAINST THE WALL FOR HOURS. **
  ** ALSO, LINK AGAINST THE VERSION OF libHIDUtilities.a in DotsX/utilities, OR SUFFER INSTANTANEOUS MATLAB QUITS. **
  * DON'T FORGET TO SET THE XCODE LIBRARY SEARCH PATH TO POINT TO SAME.  INSPECT lpHID AND GO TO BUILD TAB. DAMNIT! *
  *******************************************************************************************************************
 *                                                        *BSH*
 *                                             ***************************
 *
*/

#include "lpHID.h"
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

/* 
*lpHID usage:
 *	 isActive = lpHID('init'),
 *	 new_samples=lpHID('read'),
 *	 lpHID('reset'),
 *	 isActive = lpHID('close')
 *		
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *command=NULL;
	int buf_len;
	
	// If no arguments given, print usage string
	if(nrhs < 1) {
		mexPrintf("lpHID usage:\n\t isActive = lpHID('init'),\n\t new_samples=lpHID('read'),\n\t lpHID('reset'),\n\t isActive = lpHID('close')\n");
		return;
	}
	
	// First argument is command string... get and convert to char *
	if(mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1 && mxIsChar(prhs[0])) {
		buf_len =  mxGetN(prhs[0]) + 1;
		command = mxCalloc(buf_len, sizeof(char));
		if(mxGetString(prhs[0], command, buf_len))
			mexWarnMsgTxt("lpHID: Not enough space. String is truncated.");
	} else {
		mexErrMsgTxt("lpHID: First argument should be a string (command)");
	}
	
	//mexPrintf("%s\n",command);
		
	// case on command string...
	if(!strncmp(command, "init", 3)) {

		// done with command
		mxFree(command);
		
		// register exit routine
			if(mexAtExit(cleanup) != 0 ) {
				cleanup();
				mexErrMsgTxt("lpHID('open'): failed to register exit routine, cleanup.");
			}

		//only init once
		if(!initialized){

			//Scan the USB HID devices for the PMD1208
			//Failure to find PMD shoould cause a warning, not an error
			HIDBuildDeviceList(NULL,NULL);
			pRecDevice currentDevice;
			int i=0;
			for(currentDevice=HIDGetFirstDevice(); currentDevice != NULL; currentDevice=HIDGetNextDevice(currentDevice)){
				//figure out which HID devices are the PMD master and reporters
				if(currentDevice->productID==130){
					if(currentDevice->inputs==1){

						// found a PMD device.
						PMDReporters[i] = currentDevice;
						interface = PMDReporters[i]->interface;

						//register the HandleReportCallback function that bufers reports within this executable
						(*interface)->setInterruptReportHandlerCallback(interface,rawBuffer,(UInt32)DEFAULT_REPORT_SIZE,HandleReportCallback,rawBuffer,(void *)i);

						//create an event source for the CFRunLoop that points to each PMD reporter
						(*interface)->createAsyncEventSource(interface,&(source[i]));

						//mexPrintf("success %d\n",ret==KERN_SUCCESS);
						i++;
					} else if (currentDevice->inputs>1) PMDMaster = currentDevice;
				} 
			}

			//mexPrintf("found %i reporters\n",i);
			if(i!=NUM_REPORTING_DEVICES){
				mexPrintf("looking for %d reporting devices on USB bus\n", NUM_REPORTING_DEVICES);
				mexWarnMsgTxt("lpHID('init'): could not find all reporting HID devices for PMD1208-FS.");
				initialized = -1;
			}
			if(PMDMaster==NULL){
				mexWarnMsgTxt("lpHID('init'): could not find HID master device for PMD1208-FS.");
				initialized = -1;
			}

			//Found PMD.  Failure to register with CFRunLoop shoould cause an error.
			if(initialized != -1){
			
				//use the CF run loop for the thread on which lpHID was initialized.
				myRunLoop=CFRunLoopGetCurrent();

				//use the default run mode or a custom lpHID mode?
				myRunLoopMode=kCFRunLoopDefaultMode;
				//myRunLoopMode=CFSTR("lpHIDmodekthxbye");

				//add PMD device sources to the CF run loop on the lpHID's thread (matlab's current thread).
				for(i=0;i<NUM_REPORTING_DEVICES;i++){
					if(CFRunLoopSourceIsValid(source[i]) && !CFRunLoopContainsSource(myRunLoop,source[i],myRunLoopMode)){
							CFRunLoopAddSource(myRunLoop,source[i],myRunLoopMode);
							CFRunLoopWakeUp(myRunLoop);
					} else {
							mexErrMsgTxt("lpHID('open'): failed could not register PMD1208 with CFRunLoop.");
					}
				}

				// clear out old reports before starting data acquisition.  Just in case??
				CFRunLoopRunInMode(myRunLoopMode,myRunLoopTime,false);//0,true allows callbacks from only one device at a time

				//tell the PMD master which analog input channels to scan over and then start scanning at 1000Hz,
				//Report elements are in lpHID.h.  Their structure is sometimes mysterious, sometimes intuitive. ooooh.
				interface=PMDMaster->interface;
				if(interface!=NULL){
					(*interface)->setReport(interface,kIOHIDReportTypeOutput,19,(void *)&loadQueueReport,10,50,NULL,NULL,NULL);
					(*interface)->setReport(interface,kIOHIDReportTypeOutput,17,(void *)&startScanReport,11,50,NULL,NULL,NULL);
				}

				zeroTime=0;
				resetZeroTimeFlag=0;
				for(i=0;i<4;i++)channelOldState[i]=0;
				initialized = 1;
			} else {
			
				// take any PMD device sources out of the CF run loop
				int d;
				for(d=i-1;d>=0;d--){
					mexPrintf("\n%d\n",d);
					if(CFRunLoopSourceIsValid(source[d]) && CFRunLoopContainsSource(myRunLoop,source[d],myRunLoopMode)){
						//remove source and let CFRunLoop process the change
						CFRunLoopRemoveSource(myRunLoop,source[d],myRunLoopMode);
						CFRunLoopWakeUp(myRunLoop);
					}
				}

				//free the internal HID device list
				HIDReleaseDeviceList();
				
				initialized = 0;
			}

		}//if(!initialized)
		
		// Always return the init status
        if(!(plhs[0] = mxCreateDoubleScalar((double)initialized)))
            mexErrMsgTxt("lpHID('init'): mxCreateNumericArray failed.");

	} else if(!strncmp(command, "read", 3)) {

		// done with command
		mxFree(command);
				
		if(initialized && nlhs==1){
			static ReportStruct *r;
			static int i,j,n,c;
			static double *outPtr;
			static int chans[MATLAB_BUFFER_SIZE], changes[MATLAB_BUFFER_SIZE], times[MATLAB_BUFFER_SIZE];

			//trigger several callbacks by making a few passes through the CF run loop
			CFRunLoopRunInMode(myRunLoopMode,myRunLoopTime,false);//0,true allows callbacks from only one device at a time
			
			//'zero'is the time corresponding to the first sample in the first report after a reset
			if(resetZeroTimeFlag && freeReportIndex){
				zeroTime=reportsBuffer[0].serialNumber*31/4;
				resetZeroTimeFlag=0;
			}
			
			n = 0;//count changes (lever pulls/releases) for all 4 channles/all 3 devices
			for(i=0;i<freeReportIndex;i++){
				//mexPrintf("attempting to access reportsBuffer[%i]\n",i);
				r = &reportsBuffer[i];
				for(j=0;j<r->bytes-3;j+=2){//a sample is worth two report elements 
					c = (r->serialNumber*31+j/2)%4;//the channel from which this sample came
					//probably should do endian checking and shift bits, rather than making ints right away
					int channelIsHigh = r->report[j]+256*r->report[j+1]>20000;
					if ( channelIsHigh!=channelOldState[c] && n<MATLAB_BUFFER_SIZE){//if old and new channel states differ
						channelOldState[c] = channelIsHigh; // update channel state
						chans[n] = c; // report to MATLAB which channel changed,
						changes[n] = channelIsHigh; //the result of the change, and
						times[n] = ((r->serialNumber)*31+j/2)/4 - zeroTime; //the time of the change
						n++;
					}
				}
			}
			
			// build me a report worthy of MATLAB
			if(!(plhs[0] = mxCreateDoubleMatrix((mwSize)n, (mwSize)3, mxREAL)))
				mexErrMsgTxt("lpHID('read'): mxCreateDoubleMatrix failed.");

			// read buffered data into MATLAB array (cool).
			outPtr = mxGetPr(plhs[0]);
			for(i=0;i<n;i++,outPtr++){
				*(outPtr)		=	(double)chans[i];
				*(outPtr+n)		=	(double)changes[i];	
				*(outPtr+2*n)	=	(double)times[i];
			}

			//overwrite old reports on next read call
			freeReportIndex=0;
		}
					
	} else if(!strncmp(command, "write", 3)) {

		// done with command
		mxFree(command);
		mexPrintf("lpHID: Command is write--write on\n");
		
	} else if(!strncmp(command, "reset", 3)) {

		// done with command
		mxFree(command);

		if(initialized){
			//Register a degenerate callback for each reporting device.  Trigger the callback so that they dump all their reports
			//and free up the OS buffer.  Then reregister the useful callback so that reports are handled by this executable.
			//Keep track of the new zeroTime;
			int d;
			for(d=0;d<NUM_REPORTING_DEVICES;d++){
				interface = PMDReporters[d]->interface;
				(*interface)->setInterruptReportHandlerCallback(interface,rawBuffer,(UInt32)DEFAULT_REPORT_SIZE,FlushReportCallback,rawBuffer,(void *)d);
				CFRunLoopRunInMode(myRunLoopMode,myRunLoopTime,false);//0,true allows callbacks from only one device at a time
				(*interface)->setInterruptReportHandlerCallback(interface,rawBuffer,(UInt32)DEFAULT_REPORT_SIZE,HandleReportCallback,rawBuffer,(void *)d);
			}
			freeReportIndex=0;//overwrite old reports at next 'read'
			resetZeroTimeFlag=1;//'zero' the reported times of new lever events
		}
	
	} else if(!strncmp(command, "close", 3)) {

		// done with command
		mxFree(command);
		cleanup();
		
		//Always return the init status
        if(!(plhs[0] = mxCreateDoubleScalar((double)initialized)))
            mexErrMsgTxt("lpHID('close'): mxCreateNumericArray failed.");

	} else {

		// done with command
		mxFree(command);
		mexErrMsgTxt("lpHID: Unknown command");
	}
}

// callback is registered with the CFRunLoop and triggered when the RunLoop gets data reports from the PMD
// this callback does the usful work of formatting and sorting the reports, and buffering the data in this exec
// for later reading-out to MATLAB
void HandleReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize)
{
	static int i,serialNumber;
	static unsigned char *ptr;
	static ReportStruct *r;
	ptr=target;
	
	//buffer the report unil it's read out to MATLAB
	if(freeReportIndex>=DEFAULT_NUM_REPORTS){
		//mexErrMsgTxt("lpHID reportCallback ran out of room.  This shouldn't happen");
		mexPrintf("lpHID('read'): reportCallback reached end of reportsBuffer[%d], overwriting oldest reports\n",DEFAULT_NUM_REPORTS);
		freeReportIndex=0;
	}
	
	//get the serial number of this report--the last two bytes--for sorting
	//probably should do endian checking and shift bits, rather than making ints right away
	serialNumber = (int)*(ptr+bufferSize-1)*256+(int)*(ptr+bufferSize-2);

	//Use online insert sorting by serial number to put incoming reports into the reports Buffer.
	//since only up to a few tens of reports come in at once, this should be fast enough.
	for(i=freeReportIndex;i>0 && serialNumber<reportsBuffer[i-1].serialNumber;i--){
		reportsBuffer[i]=reportsBuffer[i-1];
	}
	r=&reportsBuffer[i];
	freeReportIndex++;
	
	//fill in this reportStruct.  The argument refcon is a user-made-up pointer passed into 
	//setInterruptReportHandlerCallback, in 'init' case above.  Used as indexes for the HID reporting devices (0,1,2)
	r->error=result;
	r->bytes=bufferSize;
	r->deviceIndex=(int)refcon;
	for(i=0;i<bufferSize && i<DEFAULT_REPORT_SIZE;i++)r->report[i]=*(ptr+i);
	r->serialNumber = serialNumber;
}

// callback is registered with the CFRunLoop and triggered when the RunLoop gets data reports from the PMD
// this degenerate callback lets the reports disappear into oblivion, effectively flushing the OS report buffer
void FlushReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize){
	//mexPrintf("FlushReportCallback--remove this print or DIE\n");
}

void cleanup(){

	if(initialized){
		//take PMD device sources out of the CF run loop
		int d=0;
		for(d=0;d<NUM_REPORTING_DEVICES;d++){
			if(CFRunLoopSourceIsValid(source[d]) && CFRunLoopContainsSource(myRunLoop,source[d],myRunLoopMode)){
				//remove source and let CFRunLoop process the change
				CFRunLoopRemoveSource(myRunLoop,source[d],myRunLoopMode);
				CFRunLoopWakeUp(myRunLoop);
			}
		}

		// stop the PMD
		interface=PMDMaster->interface;
		if(interface!=NULL)
			(*interface)->setReport(interface,kIOHIDReportTypeOutput,18,(void *)&stopScanReport,1,50,NULL,NULL,NULL);

		//free the internal HID device list
		HIDReleaseDeviceList();

		initialized=0;
	}
}
